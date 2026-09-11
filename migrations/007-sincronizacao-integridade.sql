-- =====================================================================
-- Verta — 007 — Integridade da sincronização com o CRM
--
-- Fecha quatro defeitos do 004/005, todos com o mesmo sintoma: o dado
-- chega e é destruído ou recusado sem ninguém perceber.
--
--   P1.1  motivo de perda comparado por string de exibição acentuada
--   P1.2  primary_contact_id apagado a cada webhook de negócio
--   P1.3  status da organização rebaixado a 'prospect' a cada webhook
--   P2.2  IDs de etapa e funil cravados no corpo da função
--
-- Roda depois de 004, 005 e 006. Idempotente: pode rodar duas vezes.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Reserva de linha no outbox (P3.1)
-- O CRON processa uma linha por minuto sem reservar nada. Duas execuções
-- sobrepostas pegam a mesma linha e criam o registro duas vezes no CRM.
-- Com esta coluna a reserva vira um UPDATE condicional atômico.
-- ---------------------------------------------------------------------

alter table public.crm_sync_outbox
  add column if not exists reservado_em timestamptz;

comment on column public.crm_sync_outbox.reservado_em is
  'Reserva otimista. O worker faz PATCH ...&reservado_em=is.null com return=representation: zero linhas significa que outra execucao pegou primeiro.';

drop index if exists public.crm_sync_outbox_disponivel_ix;
create index crm_sync_outbox_disponivel_ix
  on public.crm_sync_outbox (disponivel_em)
  where processado_em is null and reservado_em is null;

-- Reserva presa por execucao que morreu volta para a fila depois de 5 min.
create or replace function public.liberar_reservas_presas()
returns integer language sql as $$
  with liberadas as (
    update public.crm_sync_outbox
       set reservado_em = null
     where processado_em is null
       and reservado_em is not null
       and reservado_em < now() - interval '5 minutes'
    returning 1
  )
  select coalesce(count(*), 0)::integer from liberadas;
$$;

-- ---------------------------------------------------------------------
-- 2. Normalização de rótulo (P1.1)
-- O mapeamento motivo<->rótulo comparava a string exata, com acento. O
-- rótulo vem do Pipedrive, digitado por gente, e o caminho de volta já
-- provou que corrompe acento. Comparar por forma normalizada tolera
-- 'Perdido por preço', 'perdido por preco' e 'PERDIDO POR PRECO' — e
-- continua recusando o que não é nenhum dos seis motivos canônicos.
--
-- translate() em vez da extensão unaccent: uma dependência a menos no
-- chassi, e a cobertura do português cabe numa linha.
-- ---------------------------------------------------------------------

create or replace function public.normalizar_rotulo(p_texto text)
returns text language sql immutable as $$
  select regexp_replace(
           lower(translate(coalesce(p_texto, ''),
             'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
             'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN')),
           '[^a-z0-9]', '', 'g');
$$;

comment on function public.normalizar_rotulo(text) is
  'Reduz um rotulo de CRM a letras e digitos sem acento, para comparacao. Nao serve para exibicao.';

-- ---------------------------------------------------------------------
-- 3. Motivos de perda — alinhamento, não criação
--
-- O 004 já inseriu os seis motivos com prefixo LOST_ e já relaxou o
-- crm_ref_tipo_ck. A primeira versão desta migração inseriu um segundo
-- conjunto com prefixo MOTIVO_, duplicando o dicionário — exatamente o
-- que o crm_ref existe para impedir. Erro corrigido: prevalece o LOST_.
--
-- Único ajuste necessário: LOST_PRECO era o único cujo sufixo não batia
-- com o slug canônico de deals_motivo_perda_ck, o que quebra a derivação
-- por prefixo.
-- ---------------------------------------------------------------------

alter table public.crm_ref drop constraint if exists crm_ref_tipo_ck;
alter table public.crm_ref add constraint crm_ref_tipo_ck check (
  tipo in ('campo','opcao','pipeline','etapa','tipo_atividade','etiqueta','motivo_perda')
);

update public.crm_ref
   set chave = 'LOST_PERDIDO_POR_PRECO'
 where provider = 'pipedrive' and tipo = 'motivo_perda' and chave = 'LOST_PRECO';

-- ---------------------------------------------------------------------
-- 4. Tradutores lendo o dicionário, não constantes no código (P2.2)
-- O mapa etapa->ID vivia em três lugares: Code Node do n8n, corpo da
-- função SQL, e crm_ref. Três cópias divergem — e a etapa 17 já foi
-- renomeada uma vez. Agora só o crm_ref manda.
--
-- Convenção de chave, estabelecida em 001: STAGE_EM_CADENCIA,
-- PIPELINE_PROSPECCAO, MOTIVO_SILENCIO. O slug e o sufixo em minúscula.
-- ---------------------------------------------------------------------

create or replace function public.slug_etapa(p_stage_id bigint)
returns text language sql stable as $$
  select lower(substring(chave from 7))          -- remove 'STAGE_'
    from public.crm_ref
   where provider = 'pipedrive' and tipo = 'etapa'
     and valor_id = p_stage_id and ativo
   limit 1;
$$;

create or replace function public.slug_funil(p_pipeline_id bigint)
returns text language sql stable as $$
  select lower(substring(chave from 10))         -- remove 'PIPELINE_'
    from public.crm_ref
   where provider = 'pipedrive' and tipo = 'pipeline'
     and valor_id = p_pipeline_id and ativo
   limit 1;
$$;

create or replace function public.slug_motivo_perda(p_rotulo text)
returns text language sql stable as $$
  select lower(substring(chave from 6))          -- remove 'LOST_'
    from public.crm_ref
   where provider = 'pipedrive' and tipo = 'motivo_perda' and ativo
     and chave like 'LOST\_%'
     and public.normalizar_rotulo(valor_texto) = public.normalizar_rotulo(p_rotulo)
   limit 1;
$$;

-- Caminho de volta, para o worker do outbox nao carregar constantes.
create or replace function public.rotulo_motivo_perda(p_slug text)
returns text language sql stable as $$
  select valor_texto
    from public.crm_ref
   where provider = 'pipedrive' and tipo = 'motivo_perda' and ativo
     and chave = 'LOST_' || upper(p_slug)
   limit 1;
$$;

-- ---------------------------------------------------------------------
-- 5. Organização: status só na criação (P1.3)
-- Os três workflows mandam p_status: 'prospect' fixo, e o UPDATE
-- sobrescrevia. Cliente ativo voltava a prospect no webhook seguinte;
-- churned também. Status é ciclo de vida nosso, não do CRM.
-- ---------------------------------------------------------------------

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
    insert into public.organizations (nome, status)
    values (p_nome, coalesce(p_status, 'unidentified'))
    returning id into v_id;
    insert into public.external_refs (provider, entidade, external_id, organization_id)
    values ('pipedrive', 'organization', p_external_id, v_id);
  else
    -- Só o nome. O status pertence ao nosso ciclo de vida.
    update public.organizations set nome = coalesce(p_nome, nome) where id = v_id;
  end if;
  return v_id;
end $$;

-- ---------------------------------------------------------------------
-- 6. Contato: nulo não apaga (P1.2, P1.4)
-- Parâmetro ausente significa "o CRM não me disse", não "apague".
-- ---------------------------------------------------------------------

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
  if v_org_id is null then
    raise exception 'Organizacao externa % nao sincronizada', p_organization_external_id;
  end if;

  select contact_id into v_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'contact' and external_id = p_external_id;

  if v_id is null then
    insert into public.contacts (organization_id, nome, telefone_e164, email)
    values (v_org_id, p_nome, p_telefone_e164, p_email) returning id into v_id;
    insert into public.external_refs (provider, entidade, external_id, contact_id)
    values ('pipedrive', 'contact', p_external_id, v_id);
  else
    update public.contacts set
      organization_id = v_org_id,
      nome            = coalesce(p_nome, nome),
      telefone_e164   = coalesce(p_telefone_e164, telefone_e164),
      email           = coalesce(p_email, email)
     where id = v_id;
  end if;
  return v_id;
end $$;

-- ---------------------------------------------------------------------
-- 7. Negócio: contato preservado, mapeamento vindo do dicionário
-- (P1.1, P1.2, P2.2)
-- ---------------------------------------------------------------------

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
  v_id uuid; v_org_id uuid; v_contact_id uuid;
  v_pipeline text; v_stage text; v_status text; v_motivo text;
begin
  perform set_config('app.sync_origin', 'pipedrive', true);

  select organization_id into v_org_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'organization' and external_id = p_organization_external_id;
  if v_org_id is null then
    raise exception 'Organizacao externa % nao sincronizada', p_organization_external_id;
  end if;

  if p_contact_external_id is not null then
    select contact_id into v_contact_id from public.external_refs
     where provider = 'pipedrive' and entidade = 'contact' and external_id = p_contact_external_id;
  end if;

  v_pipeline := public.slug_funil(p_pipeline_id);
  v_stage    := public.slug_etapa(p_stage_id);
  v_status   := case p_status when 'open' then 'aberto'
                              when 'won'  then 'ganho'
                              when 'lost' then 'perdido' else null end;
  v_motivo   := public.slug_motivo_perda(p_motivo_perda);

  if v_pipeline is null or v_stage is null or v_status is null then
    raise exception 'Sem mapeamento em crm_ref: funil=%, etapa=%, status=%',
      p_pipeline_id, p_stage_id, p_status;
  end if;
  if v_status = 'perdido' and v_motivo is null then
    raise exception 'Motivo de perda sem mapeamento em crm_ref: %', p_motivo_perda;
  end if;
  -- Motivo em negocio nao perdido e ruido do CRM, nao erro nosso.
  if v_status <> 'perdido' then v_motivo := null; end if;

  select deal_id into v_id from public.external_refs
   where provider = 'pipedrive' and entidade = 'deal' and external_id = p_external_id;

  if v_id is null then
    insert into public.deals (organization_id, primary_contact_id, titulo,
                              pipeline, stage, valor, status, motivo_perda)
    values (v_org_id, v_contact_id, p_titulo, v_pipeline, v_stage, p_valor, v_status, v_motivo)
    returning id into v_id;
    insert into public.external_refs (provider, entidade, external_id, deal_id)
    values ('pipedrive', 'deal', p_external_id, v_id);
  else
    -- coalesce no contato: o webhook de negocio nao traz o contato, e
    -- sobrescrever com null destruia o vinculo feito pelo SincronizarContato.
    update public.deals set
      organization_id    = v_org_id,
      primary_contact_id = coalesce(v_contact_id, primary_contact_id),
      titulo             = coalesce(p_titulo, titulo),
      pipeline           = v_pipeline,
      stage              = v_stage,
      valor              = p_valor,
      status             = v_status,
      motivo_perda       = v_motivo
     where id = v_id;
  end if;
  return v_id;
end $$;

-- ---------------------------------------------------------------------
-- 8. Permissões
-- ---------------------------------------------------------------------

grant execute on function public.normalizar_rotulo(text)                    to service_role;
grant execute on function public.slug_etapa(bigint)                         to service_role;
grant execute on function public.slug_funil(bigint)                         to service_role;
grant execute on function public.slug_motivo_perda(text)                    to service_role;
grant execute on function public.rotulo_motivo_perda(text)                  to service_role;
grant execute on function public.liberar_reservas_presas()                  to service_role;

revoke execute on function public.normalizar_rotulo(text)                   from public, anon, authenticated;
revoke execute on function public.slug_etapa(bigint)                        from public, anon, authenticated;
revoke execute on function public.slug_funil(bigint)                        from public, anon, authenticated;
revoke execute on function public.slug_motivo_perda(text)                   from public, anon, authenticated;
revoke execute on function public.rotulo_motivo_perda(text)                 from public, anon, authenticated;
revoke execute on function public.liberar_reservas_presas()                 from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 9. Guarda: o dicionário cobre o funil inteiro?
-- Se alguma etapa ou funil não tiver linha em crm_ref, os tradutores
-- devolvem null e TODO negócio daquela etapa falha na sincronização.
-- Melhor abortar a migração agora do que descobrir em produção.
-- ---------------------------------------------------------------------

do $$
declare
  faltando text;
begin
  select string_agg(s.slug, ', ') into faltando
    from (values ('lista_prospeccao'),('em_cadencia'),('qualificado'),
                 ('diagnostico_agendado'),('diagnostico_proposta'),
                 ('negociacao_sla'),('onboarding')) as s(slug)
   where not exists (
     select 1 from public.crm_ref
      where provider = 'pipedrive' and tipo = 'etapa' and ativo
        and lower(substring(chave from 7)) = s.slug
   );
  if faltando is not null then
    raise exception 'ABORTADO: etapas sem linha em crm_ref: %. Os slugs vem de deals_stage_ck (002); as chaves, de STAGE_<SLUG>.', faltando;
  end if;

  select string_agg(s.slug, ', ') into faltando
    from (values ('prospeccao'),('fechamento')) as s(slug)
   where not exists (
     select 1 from public.crm_ref
      where provider = 'pipedrive' and tipo = 'pipeline' and ativo
        and lower(substring(chave from 10)) = s.slug
   );
  if faltando is not null then
    raise exception 'ABORTADO: funis sem linha em crm_ref: %', faltando;
  end if;

  select string_agg(s.slug, ', ') into faltando
    from (values ('ir_inferior_a_2'),('sem_autoridade'),('no_show_permanente'),
                 ('perdido_por_preco'),('silencio'),('processo_caotico')) as s(slug)
   where not exists (
     select 1 from public.crm_ref
      where provider = 'pipedrive' and tipo = 'motivo_perda' and ativo
        and lower(substring(chave from 6)) = s.slug
   );
  if faltando is not null then
    raise exception 'ABORTADO: motivos sem linha em crm_ref: %. Os slugs vem de deals_motivo_perda_ck (002); as chaves, de LOST_<SLUG>.', faltando;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 10. A etiqueta que dispara o link de qualificação
-- O GerarLinkQualificacao tinha o ID 119 cravado. Passa a ler daqui.
-- Nome confirmado no Pipedrive: "AGENDAR"; ID 119 observado no negócio 78.
-- ---------------------------------------------------------------------

insert into public.crm_ref (provider, tipo, chave, valor_id, descricao)
values ('pipedrive', 'etiqueta', 'LABEL_AGENDAR', 119,
        'Etiqueta AGENDAR: dispara a geracao do link de qualificacao')
on conflict (provider, chave) do update
   set valor_id = excluded.valor_id,
       descricao = excluded.descricao,
       ativo = true;

-- ---------------------------------------------------------------------
-- 11. Concessões que o 006 declarou e nunca chegaram ao banco
-- Medido em 11/09: calcom_routing e a view pipedrive_config ainda tinham
-- authenticated=arwdDxtm. O RLS sem políticas segurava a leitura — mas a
-- concessão é mais larga que a intenção, e RLS vira a única defesa.
-- ---------------------------------------------------------------------

revoke all on public.calcom_routing   from anon, authenticated;
revoke all on public.pipedrive_config from anon, authenticated;

commit;

-- ---------------------------------------------------------------------
-- CONFERÊNCIA — rodar depois, fora da transação
-- ---------------------------------------------------------------------
-- select 'etapa' as tipo, valor_id, lower(substring(chave from 7)) as slug
--   from public.crm_ref where provider='pipedrive' and tipo='etapa' order by valor_id;
-- select public.slug_motivo_perda('Perdido por preço')   as com_acento,
--        public.slug_motivo_perda('perdido por preco')   as sem_acento,
--        public.slug_motivo_perda('PERDIDO POR PREÇO')   as maiuscula,
--        public.slug_motivo_perda('qualquer outra coisa') as desconhecido;
