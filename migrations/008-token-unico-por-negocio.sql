-- =====================================================================
-- Verta — 008 — Um link de qualificação vivo por negócio
--
-- Medido em 11/09: três linhas de calcom_routing apontando para o mesmo
-- negócio (78), duas delas com token aberto. O GerarLinkQualificacao cria
-- uma linha a cada vez que a etiqueta AGENDAR entra e não encerra as
-- anteriores. Link de qualificação é credencial: credencial antiga que
-- continua servindo é o que transforma vazamento em acesso.
--
-- O expires_at existia e ninguém consultava — prazo declarado e não
-- aplicado. Aqui ele passa a valer, junto de um encerramento explícito.
--
-- Roda depois de 006 e 007. Idempotente.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Encerramento explícito
-- Separado de expires_at porque são coisas diferentes: um é prazo, o
-- outro é revogação. O índice único precisa de um predicado imutável, e
-- 'expires_at > now()' não é.
-- ---------------------------------------------------------------------

alter table public.calcom_routing
  add column if not exists encerrado_em timestamptz;

comment on column public.calcom_routing.encerrado_em is
  'Revogacao explicita do token. Preenchido ao reemitir o link para o mesmo negocio. Distinto de expires_at, que e prazo.';

-- ---------------------------------------------------------------------
-- 2. Fecha o passado antes de proibir o futuro
-- Mantém a linha mais recente de cada negócio; encerra as anteriores que
-- ainda estavam abertas. Linha com booking_id já cumpriu seu papel e não
-- disputa o índice.
-- ---------------------------------------------------------------------

update public.calcom_routing c
   set encerrado_em = now()
 where c.booking_id is null
   and c.encerrado_em is null
   and exists (
     select 1 from public.calcom_routing mais_nova
      where mais_nova.deal_id = c.deal_id
        and mais_nova.booking_id is null
        and mais_nova.encerrado_em is null
        and mais_nova.created_at > c.created_at
   );

-- ---------------------------------------------------------------------
-- 3. No máximo um token vivo por negócio
-- ---------------------------------------------------------------------

create unique index if not exists calcom_routing_token_vivo_uk
  on public.calcom_routing (deal_id)
  where booking_id is null and encerrado_em is null;

comment on index public.calcom_routing_token_vivo_uk is
  'Um link de qualificacao aberto por negocio. Reemitir exige encerrar o anterior primeiro.';

-- ---------------------------------------------------------------------
-- 4. search_path fixo nas funções do 007
-- O linter do Supabase acusa search_path mutável. As funções já
-- qualificam tudo com o schema, entao search_path vazio e seguro:
-- pg_catalog continua implicito para operadores e funcoes internas.
-- ---------------------------------------------------------------------

alter function public.normalizar_rotulo(text)        set search_path = '';
alter function public.slug_etapa(bigint)             set search_path = '';
alter function public.slug_funil(bigint)             set search_path = '';
alter function public.slug_motivo_perda(text)        set search_path = '';
alter function public.rotulo_motivo_perda(text)      set search_path = '';
alter function public.liberar_reservas_presas()      set search_path = '';

commit;

-- ---------------------------------------------------------------------
-- CONFERÊNCIA
-- ---------------------------------------------------------------------
-- select deal_id, count(*) filter (where booking_id is null and encerrado_em is null) as vivos
--   from public.calcom_routing group by deal_id having count(*) > 1;
