-- =====================================================================
-- Verta — 009 — Memória da cadência
--
-- O reconciliador precisa distinguir o que ELE criou do que um humano
-- criou. No Pipedrive as duas coisas são idênticas: mesma API, mesmo
-- owner, mesmos campos. Sem essa distinção, um laço convergente que
-- cancela atividades é mais perigoso que o problema que resolve.
--
-- Esta tabela é a memória. Regra que ela sustenta:
--   o reconciliador só encosta em atividade que consta aqui como dele,
--   e só enquanto estiver aberta. Atividade concluída é fato histórico;
--   atividade de humano é intocável.
--
-- Também alimenta a anotação no card: o "por quê" que o vendedor lê sai
-- daqui, não de uma mensagem efêmera no Discord.
--
-- Roda depois de 008.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Registro de artefato criado pelo sistema
--
-- Ancorada nos IDs do Pipedrive, não nos nossos. O reconciliador lê o
-- Pipedrive direto — é o que ele está reconciliando — e o espelho no
-- Supabase pode estar atrás. Amarrar no deal_id interno faria o
-- reconciliador parar de funcionar toda vez que o sync atrasasse.
--
-- Desvio deliberado da regra de organization_id NOT NULL (002): esta não
-- é tabela de negócio, é livro-razão de artefatos externos, na mesma
-- família de external_refs. O vínculo com a organização existe através
-- do negócio, quando ele estiver sincronizado.
-- ---------------------------------------------------------------------

create table if not exists public.cadencia_atividades (
  id                   uuid primary key default gen_random_uuid(),
  provider             text not null default 'pipedrive',
  external_deal_id     bigint not null,
  external_activity_id bigint not null,
  tipo                 text not null,
  deal_id              uuid references public.deals(id) on delete set null,
  criada_em            timestamptz not null default now(),
  cancelada_em         timestamptz,
  cancelada_motivo     text,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  constraint cadencia_atividades_tipo_ck check (
    tipo in ('t1','t2','t3','t4','t5','t6')
  ),
  constraint cadencia_atividades_externa_uk unique (provider, external_activity_id)
);

comment on table public.cadencia_atividades is
  'Livro-razao das atividades criadas pela automacao. Existe para o reconciliador saber o que e dele. Ausencia aqui significa "de humano" e portanto intocavel.';
comment on column public.cadencia_atividades.external_deal_id is
  'ID do negocio no Pipedrive. Ancora externa de proposito: o reconciliador le o Pipedrive, e o espelho no Supabase pode estar atrasado.';
comment on column public.cadencia_atividades.cancelada_em is
  'Preenchido quando o reconciliador cancela o proprio artefato - por exemplo, o T6 aberto quando o engajamento chega tarde.';

create index if not exists cadencia_atividades_deal_ix
  on public.cadencia_atividades (provider, external_deal_id);
create index if not exists cadencia_atividades_abertas_ix
  on public.cadencia_atividades (provider, external_deal_id, tipo)
  where cancelada_em is null;

create trigger cadencia_atividades_touch
  before update on public.cadencia_atividades
  for each row execute function public.tocar_updated_at();

alter table public.cadencia_atividades enable row level security;
revoke all on public.cadencia_atividades from anon, authenticated;
grant select, insert, update on public.cadencia_atividades to service_role;

-- ---------------------------------------------------------------------
-- 2. O clique como sinal de engajamento
--
-- Não dá para observar conversa de LinkedIn por via legítima: a API de
-- mensagens é restrita a parceiros, e raspar sessão logada arrisca a
-- conta, que é o ativo de prospecção. A saída é instrumentar o que se
-- manda pelo canal, em vez de ler o canal: o link vai na mensagem que o
-- vendedor escreve, e o clique bate no nosso servidor.
-- ---------------------------------------------------------------------

alter table public.calcom_routing
  add column if not exists clicado_em timestamptz;

comment on column public.calcom_routing.clicado_em is
  'Primeiro acesso ao link rastreavel. Sinal de engajamento que dispensa o vendedor declarar. Nao e sobrescrito em acessos seguintes.';

create index if not exists calcom_routing_clicado_ix
  on public.calcom_routing (deal_id)
  where clicado_em is not null;

commit;

-- ---------------------------------------------------------------------
-- CONFERÊNCIA
-- ---------------------------------------------------------------------
-- select tipo, count(*) filter (where cancelada_em is null) as abertas,
--        count(*) filter (where cancelada_em is not null)   as canceladas
--   from public.cadencia_atividades group by tipo order by tipo;
