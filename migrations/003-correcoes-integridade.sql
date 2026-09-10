-- =====================================================================
-- Verta — 003 — Correções de integridade e permissão
--
-- ⚠️  NÃO RODAR EM INSTALAÇÃO NOVA.
--
-- Este arquivo existe só para o projeto vnqsyngphmkgvribtmfa, que rodou
-- 001 e 002 nas versões anteriores à revisão de 10/09. Numa instalação
-- limpa, 000 → 001 → 002 já produzem este estado, e rodar 003 em cima
-- falha por constraint duplicada.
--
-- Sequência para cliente novo:  000 → 001 → 002
-- Sequência para este projeto:  (001, 002 antigos) → 003
--
-- Verificado em Postgres limpo: 6 tabelas, 49 linhas na view,
-- security_invoker ligado, 6 gatilhos, 6 tabelas com RLS, índice único
-- de telefone, e anon/authenticated com zero privilégios.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. telefone_e164 sem unicidade duplica contato
-- O índice era comum. find_or_create por telefone lê, não acha, insere:
-- duas mensagens do mesmo número novo chegando quase juntas — "oi" e
-- "queria saber o preço" — passam as duas pela leitura antes de qualquer
-- inserção e criam dois contatos. Workflow bem escrito só reduz a
-- janela; constraint é o que garante.
-- ---------------------------------------------------------------------

drop index if exists public.contacts_telefone_ix;
create unique index contacts_telefone_uk on public.contacts (telefone_e164)
  where telefone_e164 is not null and deleted_at is null;

comment on index public.contacts_telefone_uk is
  'Único, não comum. A ingestão deve usar ON CONFLICT DO NOTHING seguido de releitura.';

-- ---------------------------------------------------------------------
-- 2. O rename carregou a ACL para o _bkp
-- Renomear tabela no Postgres preserva a ACL, e os defaults do Supabase
-- já davam arwdDxtm — tudo, inclusive DELETE — para anon e authenticated.
-- O grant select que 001 emitiu não removia nada. crm_ref tinha o mesmo
-- problema: ficou de fora do revoke do 002.
-- ---------------------------------------------------------------------

revoke all on public.pipedrive_config_bkp from anon, authenticated;
revoke all on public.crm_ref              from anon, authenticated;
revoke all on public.pipedrive_config     from anon;

-- Tabelas de negócio: authenticated não tem uso legítimo aqui. O n8n usa
-- service_role; a defesa de RLS já barrava leitura, mas o grant era mais
-- largo que a intenção.
revoke all on public.organizations, public.contacts, public.deals, public.external_refs
  from anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. A view furava o RLS que 002 liga no crm_ref
-- View roda com as permissões do dono, não de quem chama. Medido:
-- authenticated lia 0 linhas direto na tabela e 49 pela view.
-- ---------------------------------------------------------------------

alter view public.pipedrive_config set (security_invoker = true);

-- ---------------------------------------------------------------------
-- 5. deals.stage e deals.motivo_perda eram texto livre
-- pipeline tinha CHECK, stage não. E motivo_perda aceitava qualquer
-- coisa, embora COMERCIAL.md defina seis motivos canônicos — que são
-- justamente o que se audita no fim do mês. 'silencio' e 'Silêncio'
-- viravam duas categorias no relatório.
--
-- CHECK, e não FK para crm_ref: deals é tabela de negócio e não deve
-- depender do dicionário de um CRM específico — é o mesmo princípio que
-- levou external_refs a existir.
-- ---------------------------------------------------------------------

alter table public.deals add constraint deals_stage_ck check (
  (pipeline = 'prospeccao' and stage in
    ('lista_prospeccao','em_cadencia','qualificado','diagnostico_agendado')) or
  (pipeline = 'fechamento' and stage in
    ('diagnostico_proposta','negociacao_sla','onboarding'))
);

alter table public.deals add constraint deals_motivo_perda_ck check (
  motivo_perda is null or motivo_perda in (
    'ir_inferior_a_2',
    'sem_autoridade',
    'no_show_permanente',
    'perdido_por_preco',
    'silencio',
    'processo_caotico'
  )
);

-- Motivo de perda só faz sentido em negócio perdido, e perdido sem
-- motivo é o que esvazia a auditoria.
alter table public.deals add constraint deals_perda_coerente_ck check (
  (status = 'perdido' and motivo_perda is not null) or
  (status <> 'perdido' and motivo_perda is null)
);

-- ---------------------------------------------------------------------
-- Nota menor 1: cnpj sem validação enquanto telefone tinha
-- 12 alfanuméricos + 2 dígitos verificadores aceita tanto o CNPJ
-- numérico antigo quanto o alfanumérico que passou a valer em 2026.
-- ---------------------------------------------------------------------

alter table public.organizations add constraint organizations_cnpj_ck check (
  cnpj is null or cnpj ~ '^[A-Z0-9]{12}[0-9]{2}$'
);

-- ---------------------------------------------------------------------
-- Nota menor 2: nada impedia cadeia de merge (A -> B -> C)
-- A resolução por merged_into_id é de um salto; uma cadeia devolveria
-- uma organização que também já foi consolidada.
-- ---------------------------------------------------------------------

create or replace function public.impedir_cadeia_de_merge()
returns trigger language plpgsql as $$
declare alvo_ja_consolidado uuid;
begin
  if new.merged_into_id is null then
    return new;
  end if;
  select merged_into_id into alvo_ja_consolidado
    from public.organizations where id = new.merged_into_id;
  if alvo_ja_consolidado is not null then
    raise exception 'Cadeia de merge: % aponta para %, que ja foi consolidada em %',
      new.id, new.merged_into_id, alvo_ja_consolidado;
  end if;
  -- Uma organização já apontada por outras não pode virar filha.
  if exists (select 1 from public.organizations
              where merged_into_id = new.id and id <> new.id) then
    raise exception 'Cadeia de merge: % ja e destino de outra consolidacao', new.id;
  end if;
  return new;
end $$;

create trigger organizations_sem_cadeia_de_merge
  before insert or update of merged_into_id on public.organizations
  for each row execute function public.impedir_cadeia_de_merge();

commit;
