begin;

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

grant execute on function public.upsert_deal_from_crm(text,text,text,text,bigint,bigint,text,numeric,text) to service_role;
revoke execute on function public.upsert_deal_from_crm(text,text,text,text,bigint,bigint,text,numeric,text) from public, anon, authenticated;

commit;
