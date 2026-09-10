-- =====================================================================
-- Verta — 001 — Dicionário de CRM
-- Objetivo: adicionar namespace sem derrubar os workflows em produção,
-- e sem cravar Pipedrive na estrutura.
--
-- Decisões e por quê:
--   provider como coluna, não prefixo de tabela — o chassi da Verta será
--     replicado em clientes que usam RD Station, HubSpot ou planilha.
--   text + CHECK em vez de ENUM — ALTER TYPE ADD VALUE tem restrição
--     transacional e não há remoção; 'propriedade' e 'record_type' vão
--     aparecer quando outros CRMs entrarem.
--   external_key em vez de hash — a assimetria "ID numérico na leitura,
--     string na escrita" não é esquisitice do Pipedrive, é comum.
--   UNIQUE (provider, chave) — protege o mapa plano cfg[chave] do n8n
--     dentro do provider, sem impedir que outro CRM use o mesmo nome.
--
-- Fase 0 (10/09) confirmou: não existe coluna tipo_dado; o prefixo da
-- chave é o discriminador; 'chave' é única; a única colisão de valor_id
-- é o id 15 (etapa Lista de Prospecção x tipo de atividade Diagnóstico).
-- =====================================================================


-- ---------------------------------------------------------------------
-- FASE 1 — Nova tabela + view de compatibilidade (transação única)
-- Ao final, GET /rest/v1/pipedrive_config?select=chave,valor_id,valor_texto
-- responde exatamente como antes. Nenhum workflow precisa mudar.
-- ---------------------------------------------------------------------

begin;

alter table public.pipedrive_config rename to pipedrive_config_bkp;

create table public.crm_ref (
  id            uuid primary key default gen_random_uuid(),
  provider      text not null default 'pipedrive',
  tipo          text not null,
  chave         text not null,   -- nome legível usado no n8n
  external_key  text,            -- chave opaca do campo (hash, API name)
  valor_id      bigint,          -- ID numérico devolvido na leitura
  valor_texto   text,            -- string exigida na escrita (key_string)
  entidade      text,            -- a qual entidade o campo pertence
  parent_id     uuid references public.crm_ref(id) on delete restrict,
  descricao     text,
  ativo         boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  constraint crm_ref_tipo_ck check (
    tipo in ('campo','opcao','pipeline','etapa','tipo_atividade','etiqueta')
  ),
  constraint crm_ref_entidade_ck check (
    entidade is null or entidade in ('deal','organization','person','activity')
  ),

  -- Contrato de leitura do n8n: cfg[chave] é um mapa plano por provider.
  constraint crm_ref_provider_chave_uk unique (provider, chave),

  -- Namespaces separados: etapa 15 e tipo_atividade 15 convivem.
  constraint crm_ref_provider_tipo_valor_uk unique (provider, tipo, valor_id),

  -- external_key só existe para campo.
  constraint crm_ref_external_key_ck check (
    (tipo = 'campo'  and external_key is not null) or
    (tipo <> 'campo' and external_key is null)
  ),

  -- Entidade acompanha o campo.
  constraint crm_ref_campo_entidade_ck check (
    (tipo = 'campo'  and entidade is not null) or
    (tipo <> 'campo' and entidade is null)
  ),

  -- Opção sempre pendurada num campo; as demais naturezas, nunca.
  constraint crm_ref_parent_ck check (
    (tipo = 'opcao'  and parent_id is not null) or
    (tipo <> 'opcao' and parent_id is null)
  )
);

create unique index crm_ref_provider_external_key_uk
  on public.crm_ref (provider, external_key) where external_key is not null;

create index crm_ref_chave_ix  on public.crm_ref (provider, chave);
create index crm_ref_tipo_ix   on public.crm_ref (provider, tipo);
create index crm_ref_parent_ix on public.crm_ref (parent_id) where parent_id is not null;

comment on table public.crm_ref is
  'Dicionário de identificadores do CRM. Campo, opção, funil, etapa, tipo de atividade e etiqueta convivem aqui porque são a mesma coisa: um nome legível apontando para um identificador do sistema externo. O que muda entre eles é o namespace, e isso é coluna.';
comment on column public.crm_ref.provider is
  'CRM de origem. O chassi da Verta roda em clientes que não usam Pipedrive.';
comment on column public.crm_ref.valor_texto is
  'String exigida na ESCRITA. Ex.: POST /activities do Pipedrive recusa o ID numérico e exige a key_string.';


-- >>> BACKFILL — prefixo da chave é o discriminador (não há tipo_dado) <<<
--
-- Em DUAS passadas, de propósito. O parent_ck exige parent_id preenchido
-- para 'opcao', e CHECK no Postgres não aceita DEFERRABLE — inserir tudo
-- de uma vez e vincular depois aborta a transação. Os pais entram
-- primeiro; as opções entram já resolvidas.

-- Passada 1 — tudo que não é opção.
insert into public.crm_ref
  (provider, tipo, chave, external_key, valor_id, valor_texto, entidade, descricao)
select
  'pipedrive',
  case
    when chave like 'PIPELINE\_%'    then 'pipeline'
    when chave like 'STAGE\_%'       then 'etapa'
    when chave like 'ATIVIDADE\_%'   then 'tipo_atividade'
    when chave like 'LABEL\_%'       then 'etiqueta'
    when chave like 'DEAL\_FIELD\_%' then 'campo'
    when chave like 'ORG\_FIELD\_%'  then 'campo'
  end,
  chave,
  -- O hash mora em valor_texto na tabela antiga; só os campos o têm.
  case when chave like 'DEAL\_FIELD\_%' or chave like 'ORG\_FIELD\_%'
       then valor_texto end,
  valor_id,
  -- valor_texto sobrevive apenas para tipo de atividade (key_string).
  case when chave like 'ATIVIDADE\_%' then valor_texto end,
  case when chave like 'DEAL\_FIELD\_%' then 'deal'
       when chave like 'ORG\_FIELD\_%'  then 'organization' end,
  descricao
from public.pipedrive_config_bkp
where chave not like 'OPT\_%';

-- Passada 2 — opções, com o pai já resolvido pelo prefixo.
-- O JOIN descarta opção de prefixo desconhecido; a conferência das 45
-- logo abaixo transforma isso em erro em vez de perda silenciosa.
insert into public.crm_ref
  (provider, tipo, chave, valor_id, descricao, parent_id)
select 'pipedrive', 'opcao', b.chave, b.valor_id, b.descricao, p.id
  from public.pipedrive_config_bkp b
  join public.crm_ref p
    on p.provider = 'pipedrive'
   and p.tipo = 'campo'
   and p.chave = case
     when b.chave like 'OPT\_ORIGEM\_%' then 'DEAL_FIELD_ORIGEM_LEAD'
     when b.chave like 'OPT\_ICP\_%'    then 'DEAL_FIELD_ICP'
     when b.chave like 'OPT\_ROTA\_%'   then 'DEAL_FIELD_ROTA_COMERCIAL'
   end
 where b.chave like 'OPT\_%';

do $$
declare n int;
begin
  -- Prefixo desconhecido não chega até aqui: o CASE devolve NULL e o
  -- INSERT estoura antes, por NOT NULL. A guarda real é a contagem.
  select count(*) into n from public.crm_ref;
  if n <> 45 then raise exception 'ABORTADO: esperado 45 linhas, veio %', n; end if;
  select count(*) into n from public.crm_ref where tipo = 'opcao';
  if n <> 12 then raise exception 'ABORTADO: esperado 12 opcoes, veio %', n; end if;
end $$;


-- View de compatibilidade: mesmo nome, mesmas colunas, mesmo endpoint.
-- Filtra por provider porque o mapa plano do n8n é por provider.
--
-- O coalesce é obrigatório, não cosmético: na tabela antiga o hash do
-- campo morava em valor_texto. Sem ele, os 9 campos personalizados
-- voltariam nulos pela view — divergência silenciosa, que é o modo de
-- falha que esta migração existe para evitar. Nenhuma linha tem os dois
-- preenchidos (campo tem external_key; tipo_atividade tem valor_texto),
-- então não há ambiguidade.
-- security_invoker é obrigatório: sem ele a view roda com as permissões
-- do dono e devolve tudo, furando o RLS da tabela. Medido antes da
-- correção: authenticated lia 0 linhas direto e 49 pela view.
create view public.pipedrive_config with (security_invoker = true) as
select chave,
       valor_id,
       coalesce(valor_texto, external_key) as valor_texto
  from public.crm_ref
 where provider = 'pipedrive' and ativo;

comment on view public.pipedrive_config is
  'Compatibilidade transitória. Fonte real: crm_ref. Preserva o contrato de leitura dos três workflows de cadência. Remover na Fase 3.';

-- Gatilho e RLS junto da tabela que protegem, não num arquivo adiante.
create trigger crm_ref_touch before update on public.crm_ref
  for each row execute function public.tocar_updated_at();

alter table public.crm_ref enable row level security;

-- REVOKE antes de GRANT. Os defaults do Supabase já concedem arwdDxtm —
-- tudo, inclusive DELETE — a anon e authenticated em toda tabela do
-- schema public; um `grant select` não retira nada. E o rename preserva
-- a ACL, então pipedrive_config_bkp herda o mesmo problema.
revoke all on public.crm_ref              from anon, authenticated;
revoke all on public.pipedrive_config     from anon, authenticated;
revoke all on public.pipedrive_config_bkp from anon, authenticated;

grant select on public.crm_ref, public.pipedrive_config to service_role;

commit;


-- ---------------------------------------------------------------------
-- FASE 1.1 — Opções que nunca chegaram a ser registradas
-- Faturamento Aproximado tem 4 opções no Pipedrive e nenhuma linha aqui.
-- Separado para que a conferência das 45 feche antes.
-- ---------------------------------------------------------------------

begin;

insert into public.crm_ref (provider, tipo, chave, valor_id, descricao, parent_id)
select 'pipedrive', 'opcao', v.chave, v.valor_id, v.descricao,
       (select id from public.crm_ref
         where provider = 'pipedrive' and chave = 'ORG_FIELD_FATURAMENTO')
  from (values
    ('OPT_FATURAMENTO_ATE_15K',    108::bigint, 'Faturamento Aproximado: Até R$ 15 mil'),
    ('OPT_FATURAMENTO_15_100K',    109,         'Faturamento Aproximado: R$ 15–100 mil'),
    ('OPT_FATURAMENTO_100_500K',   110,         'Faturamento Aproximado: R$ 100–500 mil'),
    ('OPT_FATURAMENTO_ACIMA_500K', 111,         'Faturamento Aproximado: Acima de R$ 500 mil')
  ) as v(chave, valor_id, descricao)
 where not exists (
   select 1 from public.crm_ref r where r.provider = 'pipedrive' and r.chave = v.chave
 );

commit;


-- ---------------------------------------------------------------------
-- FASE 2 — Migração dos nós do n8n (sem prazo, um workflow por vez)
-- Trocar  /rest/v1/pipedrive_config?select=chave,valor_id,valor_texto
-- por     /rest/v1/crm_ref?select=chave,tipo,external_key,valor_id,valor_texto,entidade
--         &provider=eq.pipedrive&ativo=is.true
-- Uma chamada só, dicionário inteiro em memória — comportamento atual.
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- FASE 3 — Limpeza (só quando os três workflows estiverem migrados)
-- ---------------------------------------------------------------------
-- drop view public.pipedrive_config;
-- drop table public.pipedrive_config_bkp;


-- ---------------------------------------------------------------------
-- ROLLBACK da Fase 1
-- ---------------------------------------------------------------------
-- begin;
--   drop view if exists public.pipedrive_config;
--   drop table if exists public.crm_ref;
--   alter table public.pipedrive_config_bkp rename to pipedrive_config;
-- commit;
