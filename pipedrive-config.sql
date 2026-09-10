-- pipedrive_config — mapeamento de IDs e chaves opacas do Pipedrive
-- Projeto Supabase: vnqsyngphmkgvribtmfa (Verta)
-- Base: ARQUITETURA.md secao 1 — "Nunca escreva a chave direto no workflow.
--       Mapeie na tabela pipedrive_config com nome legivel."
--
-- Rodar no SQL Editor do Supabase. Idempotente: pode rodar mais de uma vez.
-- Todos os valores abaixo foram confirmados por GET na API em 09/09/2026.

create table if not exists public.pipedrive_config (
  chave         text primary key,
  valor_id      bigint,
  valor_texto   text,
  descricao     text not null,
  atualizado_em timestamptz not null default now()
);

comment on table public.pipedrive_config is
  'Mapeia IDs e chaves opacas do Pipedrive para nomes legiveis. Fonte da verdade para os workflows do n8n.';
comment on column public.pipedrive_config.valor_id is
  'ID numerico. Usado em leitura e comparacao.';
comment on column public.pipedrive_config.valor_texto is
  'key_string ou hash. Usado em ESCRITA: a API de atividades exige key_string, nao o ID.';

insert into public.pipedrive_config (chave, valor_id, valor_texto, descricao) values
  -- Funil e etapas
  ('PIPELINE_PROSPECCAO',          2, null, 'Funil 01 - Prospeccao'),
  ('PIPELINE_FECHAMENTO',          4, null, 'Funil 02 - Fechamento'),
  ('STAGE_LISTA_PROSPECCAO',      15, null, 'Etapa: Lista de Prospeccao'),
  ('STAGE_EM_CADENCIA',           16, null, 'Etapa: Em Cadencia - dispara a criacao da cadencia'),
  ('STAGE_QUALIFICADO',           17, null, 'Etapa: Qualificado - Formulario Preenchido'),
  ('STAGE_DIAGNOSTICO_AGENDADO',  26, null, 'Etapa: Diagnostico Agendado'),

  -- Tipos de atividade. valor_texto = key_string, obrigatorio na escrita.
  ('ATIVIDADE_T1',                 7, 't1__comentario_linkedin', 'T1 - Comentario LinkedIn'),
  ('ATIVIDADE_T2',                 8, 't2__convite_conexao',     'T2 - Convite Conexao'),
  ('ATIVIDADE_T3',                 9, 't3__e_mail_abertura',     'T3 - E-mail Abertura'),
  ('ATIVIDADE_T4',                10, 't4__valor',               'T4 - Valor'),
  ('ATIVIDADE_T5',                11, 't5__convite_diagnostico', 'T5 - Convite Diagnostico'),
  ('ATIVIDADE_T6',                12, 't6__break_up',            'T6 - Break-up'),
  ('ATIVIDADE_TRIAGEM_WHATSAPP',  13, 'triagem_whatsapp',        'Triagem WhatsApp'),
  ('ATIVIDADE_LIGACAO_RESGATE',   14, 'ligacao_de_resgate',      'Ligacao de Resgate'),
  ('ATIVIDADE_DIAGNOSTICO_MEET',  15, 'diagnostico_meet',        'Diagnostico (Meet)'),

  -- Etiquetas de negocio
  ('LABEL_QUALIFICADO',           65, null, 'Etiqueta: Qualificado'),
  ('LABEL_INCERTO',               66, null, 'Etiqueta: Incerto'),
  ('LABEL_SEM_FIT',               67, null, 'Etiqueta: Sem fit'),
  ('LABEL_ROTA_1',                68, null, 'Etiqueta: Rota 1 (Start)'),
  ('LABEL_ROTA_2',                69, null, 'Etiqueta: Rota 2 (Modular)'),
  ('LABEL_ORIGEM_WHATSAPP',       70, null, 'Etiqueta: Origem WhatsApp'),
  ('LABEL_ORIGEM_TYPEFORM',       71, null, 'Etiqueta: Origem Typeform'),
  ('LABEL_ORIGEM_CALENDLY',       72, null, 'Etiqueta: Origem Calendly'),
  ('LABEL_ENGAJOU',              112, null, 'Etiqueta: Engajou - sinal que libera o T5 (Workflow 3)'),

  -- Campos personalizados de Negocio (chaves opacas)
  ('DEAL_FIELD_ORIGEM_LEAD',    null, 'cf1d89d574bdec4674b046791949a99bd5ce59fa', 'Campo Negocio: Origem do Lead (enum)'),
  ('DEAL_FIELD_ICP',            null, '6191cc510bf3d5815ac8d4231b02f4fe2dd92021', 'Campo Negocio: ICP (enum)'),
  ('DEAL_FIELD_VOLUME_CONVERSAS',null,'44c6dc9d259349def6a64f6a0534b4ae34ad6c62', 'Campo Negocio: Volume de Conversas/Mes'),
  ('DEAL_FIELD_TICKET_MEDIO',   null, '7a11436fe7cc27cedf80e0fff04f0bc83b1be264', 'Campo Negocio: Ticket Medio (monetary)'),
  ('DEAL_FIELD_LEADS_PERDIDOS', null, '9ac324e99825c08e05d785a89a2e8866eb34393f', 'Campo Negocio: Leads Perdidos/Mes'),
  ('DEAL_FIELD_INDICE_RECUPERACAO',null,'3048f51cd1c58b890a85a900d8c6263b3b389f7e','Campo Negocio: Indice de Recuperacao (IR)'),
  ('DEAL_FIELD_SOFTWARE_ATUAL', null, '9315a06ccadb9af2d8f12b0b0cae265a142b6055', 'Campo Negocio: Software Atual (CRM/Agenda)'),
  ('DEAL_FIELD_ROTA_COMERCIAL', null, '0ca3261dde48fb34c91d9997d9da69b03ac68ba6', 'Campo Negocio: Rota Comercial (enum)'),

  -- Campo personalizado de Organizacao
  ('ORG_FIELD_FATURAMENTO',     null, '58f54ae6225863454cb946ba57f6c5a54ab5b712', 'Campo Organizacao: Faturamento Aproximado (enum)'),

  -- Opcoes de enum usadas em escrita
  ('OPT_ORIGEM_LINKEDIN',         96, null, 'Origem do Lead: LinkedIn'),
  ('OPT_ORIGEM_EMAIL',            97, null, 'Origem do Lead: E-mail'),
  ('OPT_ORIGEM_INBOUND_SITE',     98, null, 'Origem do Lead: Inbound Site'),
  ('OPT_ORIGEM_INSTAGRAM',        99, null, 'Origem do Lead: Instagram'),
  ('OPT_ORIGEM_WHATSAPP_DIRETO', 100, null, 'Origem do Lead: WhatsApp direto - so quem escreveu sem passar por canal de aquisicao (DECISOES.md 3)'),
  ('OPT_ORIGEM_INDICACAO',       101, null, 'Origem do Lead: Indicacao'),
  ('OPT_ICP_A1_ESTETICA',        102, null, 'ICP: A1 - Estetica'),
  ('OPT_ICP_A2_ODONTO',          103, null, 'ICP: A2 - Odonto'),
  ('OPT_ICP_B_ADVOCACIA',        104, null, 'ICP: B - Advocacia'),
  ('OPT_ICP_FORA',               105, null, 'ICP: Fora do ICP'),
  ('OPT_ROTA_1_START',           106, null, 'Rota Comercial: Rota 1 - Verta Start'),
  ('OPT_ROTA_2_MODULAR',         107, null, 'Rota Comercial: Rota 2 - Modular')
on conflict (chave) do update
  set valor_id      = excluded.valor_id,
      valor_texto   = excluded.valor_texto,
      descricao     = excluded.descricao,
      atualizado_em = now();

-- RLS: a tabela e lida pelo n8n com a chave de servico, que ignora RLS.
-- Habilitar mesmo assim evita exposicao acidental via chave publishable.
alter table public.pipedrive_config enable row level security;

drop policy if exists "pipedrive_config sem acesso anonimo" on public.pipedrive_config;
create policy "pipedrive_config sem acesso anonimo"
  on public.pipedrive_config for select
  to authenticated
  using (true);

-- Conferencia
select chave, valor_id, valor_texto, descricao
from public.pipedrive_config
order by chave;
