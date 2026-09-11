begin;

alter table public.crm_ref drop constraint crm_ref_tipo_ck;
alter table public.crm_ref add constraint crm_ref_tipo_ck check (
  tipo in ('campo','opcao','pipeline','etapa','tipo_atividade','etiqueta','motivo_perda')
);

insert into public.crm_ref (provider, tipo, chave, valor_id, descricao)
values
  ('pipedrive', 'etapa', 'STAGE_DIAGNOSTICO_PROPOSTA', 18, 'Etapa: Diagnóstico & Proposta'),
  ('pipedrive', 'etapa', 'STAGE_NEGOCIACAO_SLA', 19, 'Etapa: Negociação & SLA'),
  ('pipedrive', 'etapa', 'STAGE_ONBOARDING', 20, 'Etapa: Onboarding')
on conflict (provider, chave) do update
set tipo = excluded.tipo,
    valor_id = excluded.valor_id,
    descricao = excluded.descricao,
    ativo = true;

insert into public.crm_ref (provider, tipo, chave, valor_id, valor_texto, descricao)
values
  ('pipedrive', 'motivo_perda', 'LOST_IR_INFERIOR_A_2', 113, 'IR inferior a 2', 'Baixo retorno recuperável'),
  ('pipedrive', 'motivo_perda', 'LOST_SEM_AUTORIDADE', 114, 'Sem autoridade', 'Contato sem poder de decisão'),
  ('pipedrive', 'motivo_perda', 'LOST_NO_SHOW_PERMANENTE', 115, 'No-show permanente', 'Ausência definitiva após tentativas'),
  ('pipedrive', 'motivo_perda', 'LOST_PRECO', 116, 'Perdido por preço', 'Fit confirmado, sem maturidade financeira'),
  ('pipedrive', 'motivo_perda', 'LOST_SILENCIO', 117, 'Silêncio', 'Cadência encerrada sem interação'),
  ('pipedrive', 'motivo_perda', 'LOST_PROCESSO_CAOTICO', 118, 'Processo caótico', 'Fundação necessária e recusada')
on conflict (provider, chave) do update
set tipo = excluded.tipo,
    valor_id = excluded.valor_id,
    valor_texto = excluded.valor_texto,
    descricao = excluded.descricao,
    ativo = true;

create table public.crm_sync_outbox (
  id uuid primary key default gen_random_uuid(),
  entidade text not null check (entidade in ('organization','contact','deal')),
  entidade_id uuid not null,
  operacao text not null default 'upsert' check (operacao in ('upsert','delete')),
  tentativas integer not null default 0 check (tentativas >= 0),
  disponivel_em timestamptz not null default now(),
  processado_em timestamptz,
  erro text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index crm_sync_outbox_pendente_uk
  on public.crm_sync_outbox (entidade, entidade_id)
  where processado_em is null;
create index crm_sync_outbox_disponivel_ix
  on public.crm_sync_outbox (disponivel_em, created_at)
  where processado_em is null;

create trigger crm_sync_outbox_touch before update on public.crm_sync_outbox
  for each row execute function public.tocar_updated_at();

create or replace function public.enfileirar_sync_crm()
returns trigger language plpgsql as $$
declare
  v_id uuid;
  v_entidade text := tg_argv[0];
begin
  if current_setting('app.sync_origin', true) = 'pipedrive' then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;
  if tg_op = 'DELETE' then v_id := old.id; else v_id := new.id; end if;
  insert into public.crm_sync_outbox (entidade, entidade_id, operacao)
  values (v_entidade, v_id, case when tg_op = 'DELETE' then 'delete' else 'upsert' end)
  on conflict (entidade, entidade_id) where processado_em is null
  do update set operacao = excluded.operacao,
                tentativas = 0,
                disponivel_em = now(),
                erro = null,
                updated_at = now();
  if tg_op = 'DELETE' then return old; else return new; end if;
end $$;

create trigger organizations_sync_crm
after insert or update or delete on public.organizations
for each row execute function public.enfileirar_sync_crm('organization');

create trigger contacts_sync_crm
after insert or update or delete on public.contacts
for each row execute function public.enfileirar_sync_crm('contact');

create trigger deals_sync_crm
after insert or update or delete on public.deals
for each row execute function public.enfileirar_sync_crm('deal');

create or replace function public.upsert_organization_from_crm(
  p_external_id text,
  p_nome text,
  p_status text default 'prospect'
) returns uuid language plpgsql as $$
declare v_id uuid;
begin
  perform set_config('app.sync_origin', 'pipedrive', true);
  select organization_id into v_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'organization' and external_id = p_external_id;
  if v_id is null then
    insert into public.organizations (nome, status) values (p_nome, p_status) returning id into v_id;
    insert into public.external_refs (provider, entidade, external_id, organization_id)
    values ('pipedrive', 'organization', p_external_id, v_id);
  else
    update public.organizations set nome = p_nome, status = p_status where id = v_id;
  end if;
  return v_id;
end $$;

create or replace function public.upsert_contact_from_crm(
  p_external_id text,
  p_organization_external_id text,
  p_nome text,
  p_telefone_e164 text default null,
  p_email text default null
) returns uuid language plpgsql as $$
declare v_id uuid; v_org_id uuid;
begin
  perform set_config('app.sync_origin', 'pipedrive', true);
  select organization_id into v_org_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'organization' and external_id = p_organization_external_id;
  if v_org_id is null then raise exception 'Organização externa % não sincronizada', p_organization_external_id; end if;
  select contact_id into v_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'contact' and external_id = p_external_id;
  if v_id is null then
    insert into public.contacts (organization_id, nome, telefone_e164, email)
    values (v_org_id, p_nome, p_telefone_e164, p_email) returning id into v_id;
    insert into public.external_refs (provider, entidade, external_id, contact_id)
    values ('pipedrive', 'contact', p_external_id, v_id);
  else
    update public.contacts set organization_id = v_org_id, nome = p_nome,
      telefone_e164 = p_telefone_e164, email = p_email where id = v_id;
  end if;
  return v_id;
end $$;

create or replace function public.upsert_deal_from_crm(
  p_external_id text,
  p_organization_external_id text,
  p_contact_external_id text,
  p_titulo text,
  p_pipeline_id bigint,
  p_stage_id bigint,
  p_status text,
  p_valor numeric default null,
  p_motivo_perda text default null
) returns uuid language plpgsql as $$
declare
  v_id uuid;
  v_org_id uuid;
  v_contact_id uuid;
  v_pipeline text;
  v_stage text;
  v_status text;
  v_motivo text;
begin
  perform set_config('app.sync_origin', 'pipedrive', true);
  select organization_id into v_org_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'organization' and external_id = p_organization_external_id;
  if v_org_id is null then raise exception 'Organização externa % não sincronizada', p_organization_external_id; end if;
  if p_contact_external_id is not null then
    select contact_id into v_contact_id from public.external_refs
     where provider = 'pipedrive' and entidade = 'contact' and external_id = p_contact_external_id;
  end if;
  v_pipeline := case p_pipeline_id when 2 then 'prospeccao' when 4 then 'fechamento' else null end;
  v_stage := case p_stage_id
    when 15 then 'lista_prospeccao' when 16 then 'em_cadencia'
    when 17 then 'qualificado' when 26 then 'diagnostico_agendado'
    when 18 then 'diagnostico_proposta' when 19 then 'negociacao_sla'
    when 20 then 'onboarding' else null end;
  v_status := case p_status when 'open' then 'aberto' when 'won' then 'ganho' when 'lost' then 'perdido' else null end;
  v_motivo := case p_motivo_perda
    when 'IR inferior a 2' then 'ir_inferior_a_2'
    when 'Sem autoridade' then 'sem_autoridade'
    when 'No-show permanente' then 'no_show_permanente'
    when 'Perdido por preço' then 'perdido_por_preco'
    when 'Silêncio' then 'silencio'
    when 'Processo caótico' then 'processo_caotico'
    else null end;
  if v_pipeline is null or v_stage is null or v_status is null then
    raise exception 'Pipeline, etapa ou status externo sem mapeamento: %, %, %', p_pipeline_id, p_stage_id, p_status;
  end if;
  if v_status = 'perdido' and v_motivo is null then
    raise exception 'Motivo de perda externo sem mapeamento: %', p_motivo_perda;
  end if;
  select deal_id into v_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'deal' and external_id = p_external_id;
  if v_id is null then
    insert into public.deals (organization_id, primary_contact_id, titulo, pipeline, stage, valor, status, motivo_perda)
    values (v_org_id, v_contact_id, p_titulo, v_pipeline, v_stage, p_valor, v_status, v_motivo)
    returning id into v_id;
    insert into public.external_refs (provider, entidade, external_id, deal_id)
    values ('pipedrive', 'deal', p_external_id, v_id);
  else
    update public.deals set organization_id = v_org_id, primary_contact_id = v_contact_id,
      titulo = p_titulo, pipeline = v_pipeline, stage = v_stage, valor = p_valor,
      status = v_status, motivo_perda = v_motivo where id = v_id;
  end if;
  return v_id;
end $$;

alter table public.crm_sync_outbox enable row level security;
revoke all on public.crm_sync_outbox from anon, authenticated;
grant select, insert, update on public.crm_sync_outbox to service_role;
grant execute on function public.upsert_organization_from_crm(text,text,text) to service_role;
grant execute on function public.upsert_contact_from_crm(text,text,text,text,text) to service_role;
grant execute on function public.upsert_deal_from_crm(text,text,text,text,bigint,bigint,text,numeric,text) to service_role;
revoke execute on function public.upsert_organization_from_crm(text,text,text) from public, anon, authenticated;
revoke execute on function public.upsert_contact_from_crm(text,text,text,text,text) from public, anon, authenticated;
revoke execute on function public.upsert_deal_from_crm(text,text,text,text,bigint,bigint,text,numeric,text) from public, anon, authenticated;

commit;
