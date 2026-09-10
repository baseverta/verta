-- =====================================================================
-- Verta — 002 — Núcleo relacional
-- organizations é a raiz absoluta: nenhum dado de negócio existe fora
-- de uma organização. Toda tabela operacional carrega organization_id
-- NOT NULL.
--
-- Fora de escopo nesta rodada, deliberadamente: sessões, mensagens e
-- embeddings. Dependem da decisão Evolution API x API oficial da Meta,
-- que muda o formato de identificação de sessão; e a extensão vector só
-- faz sentido quando houver o que vetorizar.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- RAIZ
-- ---------------------------------------------------------------------

create table public.organizations (
  id               uuid primary key default gen_random_uuid(),
  nome             text not null,
  status           text not null default 'unidentified'
                     check (status in ('unidentified','prospect','client','churned')),
  drive_folder_id  text,
  drive_file_ids   jsonb not null default '{}'::jsonb,
  merged_into_id   uuid references public.organizations(id) on delete restrict,
  -- 12 alfanuméricos + 2 dígitos verificadores: aceita o CNPJ numérico
  -- antigo e o alfanumérico que passou a valer em 2026.
  cnpj             text check (cnpj is null or cnpj ~ '^[A-Z0-9]{12}[0-9]{2}$'),
  is_internal      boolean not null default false,
  deleted_at       timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint organizations_merge_nao_autorreferente check (merged_into_id is distinct from id)
);

comment on table public.organizations is
  'Raiz absoluta. Nasce com status unidentified quando a ingestão ainda não sabe quem é: find_or_create_organization cria a provisória e só então vincula o contato. O enriquecimento posterior faz merge via merged_into_id, migrando os filhos por FK.';
comment on column public.organizations.drive_folder_id is
  'Referência por ID, nunca por nome ou caminho: pastas homônimas e renomeações quebram fluxo baseado em texto.';
comment on column public.organizations.is_internal is
  'Cadastro da própria Verta. Instrui a auditoria a ignorar ausência de espelhamento no CRM. Derivada do contexto de inserção, nunca do payload do n8n.';

create index organizations_status_ix on public.organizations (status) where deleted_at is null;
create index organizations_merged_ix on public.organizations (merged_into_id) where merged_into_id is not null;

-- ---------------------------------------------------------------------
-- FILHAS
-- ---------------------------------------------------------------------

create table public.contacts (
  id                    uuid primary key default gen_random_uuid(),
  organization_id       uuid not null references public.organizations(id) on delete restrict,
  nome                  text,
  lifecycle_stage       text not null default 'lead'
                          check (lifecycle_stage in ('lead','qualificado','cliente','perdido')),
  telefone_e164         text check (telefone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  email                 text,
  cargo                 text,
  ticket_medio          numeric(14,2),
  volume_conversas_mes  integer,
  leads_perdidos_mes    integer,
  indice_recuperacao    numeric(10,2),
  is_internal           boolean not null default false,
  deleted_at            timestamptz,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

comment on table public.contacts is
  'Entidade filha única. Substitui o par leads/client_contacts: o contato não muda de tabela ao converter, muda de lifecycle_stage. O UUID permanece estável por toda a vida do relacionamento, preservando conversas, sessões e logs que apontam para ele.';
comment on column public.contacts.telefone_e164 is
  'Telefone normalizado em E.164. A constraint recusa formato livre na entrada, em vez de confiar na normalização do workflow.';

create index contacts_organization_ix on public.contacts (organization_id) where deleted_at is null;
-- Único, não comum: duas mensagens do mesmo número novo chegando quase
-- juntas — "oi" e depois "queria saber o preço" — passam as duas pela
-- leitura do find_or_create antes de qualquer inserção e criam dois
-- contatos. Workflow bem escrito só reduz a janela; constraint garante.
-- A ingestão deve usar ON CONFLICT DO NOTHING seguido de releitura.
create unique index contacts_telefone_uk on public.contacts (telefone_e164)
  where telefone_e164 is not null and deleted_at is null;
create index contacts_lifecycle_ix    on public.contacts (lifecycle_stage) where deleted_at is null;

create table public.deals (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references public.organizations(id) on delete restrict,
  primary_contact_id  uuid references public.contacts(id) on delete restrict,
  titulo              text not null,
  pipeline            text not null check (pipeline in ('prospeccao','fechamento')),
  stage               text not null,
  valor               numeric(14,2),
  moeda               text not null default 'BRL',
  status              text not null default 'aberto'
                        check (status in ('aberto','ganho','perdido')),
  motivo_perda        text,

  -- stage era texto livre enquanto pipeline tinha CHECK. CHECK e não FK
  -- para crm_ref: deals é tabela de negócio e não deve depender do
  -- dicionário de um CRM específico — mesmo princípio de external_refs.
  constraint deals_stage_ck check (
    (pipeline = 'prospeccao' and stage in
      ('lista_prospeccao','em_cadencia','qualificado','diagnostico_agendado')) or
    (pipeline = 'fechamento' and stage in
      ('diagnostico_proposta','negociacao_sla','onboarding'))
  ),

  -- Os seis motivos canônicos de COMERCIAL.md. Sem isso, 'silencio' e
  -- 'Silêncio' viram duas categorias no relatório de fim de mês.
  constraint deals_motivo_perda_ck check (
    motivo_perda is null or motivo_perda in (
      'ir_inferior_a_2','sem_autoridade','no_show_permanente',
      'perdido_por_preco','silencio','processo_caotico'
    )
  ),

  -- Motivo só em negócio perdido; e perdido sem motivo esvazia a auditoria.
  constraint deals_perda_coerente_ck check (
    (status = 'perdido' and motivo_perda is not null) or
    (status <> 'perdido' and motivo_perda is null)
  ),
  is_internal         boolean not null default false,
  deleted_at          timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table public.deals is
  'Entidade filha. O progresso de funil sai de organizations e ganha tabela própria: a mesma empresa percorre diagnóstico, setup e renovação como negócios distintos, em momentos distintos.';

create index deals_organization_ix   on public.deals (organization_id) where deleted_at is null;
create index deals_contact_ix        on public.deals (primary_contact_id) where primary_contact_id is not null;
create index deals_pipeline_stage_ix on public.deals (pipeline, stage) where deleted_at is null;

-- ---------------------------------------------------------------------
-- REFERÊNCIAS EXTERNAS
-- Nenhum *_id de CRM vaza para as tabelas de negócio. Serve organização,
-- contato e negócio de uma vez, e permite que o mesmo registro exista em
-- dois sistemas durante uma migração.
--
-- Desvio do esboço (entidade, entidade_id): três colunas de FK em vez de
-- um entidade_id polimórfico. Polimórfico não aceita foreign key, e a
-- seção de integridade do documento é explícita — a arquitetura se recusa
-- a corromper em vez de confiar que ninguém vai errar. O CHECK garante
-- que exatamente uma das três está preenchida, e coerente com 'entidade'.
-- ---------------------------------------------------------------------

create table public.external_refs (
  id               uuid primary key default gen_random_uuid(),
  provider         text not null default 'pipedrive',
  entidade         text not null check (entidade in ('organization','contact','deal')),
  external_id      text not null,
  organization_id  uuid references public.organizations(id) on delete restrict,
  contact_id       uuid references public.contacts(id)      on delete restrict,
  deal_id          uuid references public.deals(id)         on delete restrict,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  -- Exatamente uma FK preenchida, e coerente com entidade.
  constraint external_refs_alvo_ck check (
    (entidade = 'organization' and organization_id is not null and contact_id is null and deal_id is null) or
    (entidade = 'contact'      and contact_id is not null      and organization_id is null and deal_id is null) or
    (entidade = 'deal'         and deal_id is not null         and organization_id is null and contact_id is null)
  ),

  -- Um id externo aponta para no máximo um registro nosso, por provider.
  constraint external_refs_provider_externo_uk unique (provider, entidade, external_id)
);

comment on table public.external_refs is
  'Ponte entre os registros da Verta e os identificadores de sistemas externos. Mantém organizations, contacts e deals livres de qualquer id de CRM.';

create unique index external_refs_org_uk on public.external_refs (provider, organization_id)
  where organization_id is not null;
create unique index external_refs_contact_uk on public.external_refs (provider, contact_id)
  where contact_id is not null;
create unique index external_refs_deal_uk on public.external_refs (provider, deal_id)
  where deal_id is not null;

-- ---------------------------------------------------------------------
-- TOQUE DE ATUALIZAÇÃO
-- ---------------------------------------------------------------------

-- A função vive em 000; o gatilho do crm_ref vive em 001, junto da tabela.
create trigger organizations_touch  before update on public.organizations
  for each row execute function public.tocar_updated_at();
create trigger contacts_touch       before update on public.contacts
  for each row execute function public.tocar_updated_at();
create trigger deals_touch          before update on public.deals
  for each row execute function public.tocar_updated_at();
create trigger external_refs_touch  before update on public.external_refs
  for each row execute function public.tocar_updated_at();

-- Cadeia de merge (A -> B -> C) quebraria a resolução por merged_into_id,
-- que é de um salto: devolveria uma organização também já consolidada.
create or replace function public.impedir_cadeia_de_merge()
returns trigger language plpgsql as $$
declare alvo_ja_consolidado uuid;
begin
  if new.merged_into_id is null then return new; end if;
  select merged_into_id into alvo_ja_consolidado
    from public.organizations where id = new.merged_into_id;
  if alvo_ja_consolidado is not null then
    raise exception 'Cadeia de merge: % aponta para %, que ja foi consolidada em %',
      new.id, new.merged_into_id, alvo_ja_consolidado;
  end if;
  if exists (select 1 from public.organizations
              where merged_into_id = new.id and id <> new.id) then
    raise exception 'Cadeia de merge: % ja e destino de outra consolidacao', new.id;
  end if;
  return new;
end $$;

create trigger organizations_sem_cadeia_de_merge
  before insert or update of merged_into_id on public.organizations
  for each row execute function public.impedir_cadeia_de_merge();

-- ---------------------------------------------------------------------
-- RLS — defesa em profundidade, não controle primário
-- O n8n usa service_role, que passa por cima de RLS. O isolamento real é
-- responsabilidade do workflow: RPC/view que já filtra por
-- organization_id, ou WHERE explícito e revisado. O RLS aqui existe para
-- que uma chave publishable vazada não leia dado de cliente.
-- ---------------------------------------------------------------------

alter table public.organizations  enable row level security;
alter table public.contacts       enable row level security;
alter table public.deals          enable row level security;
alter table public.external_refs  enable row level security;
-- crm_ref liga o próprio RLS em 001, junto da tabela.

-- REVOKE antes de GRANT: os defaults do Supabase concedem arwdDxtm a anon
-- e authenticated em toda tabela do schema public, e um grant não retira.
revoke all on public.organizations, public.contacts, public.deals, public.external_refs
  from anon, authenticated;

grant select, insert, update on
  public.organizations, public.contacts, public.deals, public.external_refs
  to service_role;

commit;
