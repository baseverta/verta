# Desenho dos Workflows de Cadência — para aprovação

> **Nada foi criado.** Este documento é o desenho para sua aprovação, conforme o item 3 do prompt.

---

## Bloqueios que impedem a construção

### 1. `SUB - Global - TratamentoErro` não existe

A instância `https://n8n.baseverta.com.br` tem **exatamente um workflow**:

| Nome | ID | Estado |
| --- | --- | --- |
| `01 - Captura e Extracao de Pautas` | `P6Tp3JQsexA4N9Mc` | ativo |

Consultei com `includeArchived=true` e sem cursor de paginação pendente — é isso mesmo. O workflow existente não segue a convenção `[GATILHO] - [DOMÍNIO] - [Ação]`, o que sugere que a padronização começa agora.

O `.env.n8n` referencia dezenas de IDs de workflow (`N8N_WORKFLOW_WHATSAPP_ID`, `N8N_WORKFLOW_ONBOARDING`, etc.) que **não existem nesta instância**. Ou o arquivo é de uma instância anterior, ou os workflows foram removidos.

É pré-requisito declarado dos três workflows. **Preciso da sua decisão antes de seguir.**

### 2. O Supabase está vazio

O projeto `vnqsyngphmkgvribtmfa` **não expõe nenhuma tabela**. Não existe `pipedrive_config`, nem `organizations`, nem `leads` — o PostgREST retorna `PGRST205` para todas.

Agravante: o MCP do Supabase configurado no `.mcp.json` **não tem acesso a este projeto**. A conta autenticada enxerga apenas um projeto, `Manekin.ai` (`rmadcqprekuvwgacwuaf`) — que é justamente o projeto de teste cujos resíduos limpamos no Pipedrive. Toda chamada ao projeto da Verta retorna *"You do not have permission"*.

Consequência prática: **eu não consigo criar a tabela.** O PostgREST não faz DDL, o MCP não alcança o projeto, e não há senha de Postgres no `.env` para conexão direta. O SQL abaixo terá que ser rodado por você no SQL Editor do Supabase.

### 3. A etiqueta `Engajou` não existe

Confirmado por GET. As etiquetas de Negócio hoje são: `65` Qualificado · `66` Incerto · `67` Sem fit · `68` Rota 1 (Start) · `69` Rota 2 (Modular) · `70` Origem: WhatsApp · `71` Origem: Typeform · `72` Origem: Calendly.

Ela é o sinal que sustenta o Workflow 3 inteiro. Posso criá-la, mas é escrita no Pipedrive — aguardo aprovação.

### 4. Não consegui verificar as variáveis do container

A inspeção via SSH foi **bloqueada pelo classificador de permissões** desta sessão. Não contornei.

Portanto não sei se `PIPEDRIVE_API_TOKEN` e `DISCORD_WEBHOOK_CADENCIA` existem dentro do container do n8n. Ambas são exigidas pelo desenho. Você precisa confirmar, ou me liberar a permissão.

---

## Divergências no desenho

### A. Webhooks do Pipedrive não têm assinatura

O padrão do projeto manda *"ative `rawBody: true` e valide a assinatura"*. **O Pipedrive não assina webhooks.** Não há HMAC nem header de assinatura — a documentação oferece exclusivamente **HTTP Basic Auth**, com `http_auth_user` e `http_auth_password` definidos no momento em que a subscrição é criada.

Esse padrão do projeto veio dos webhooks de Typeform e Cal.com, que de fato assinam. Aqui ele não tem como ser aplicado.

**Proposta:** Basic Auth na subscrição do Pipedrive + credencial Basic Auth no nó Webhook do n8n, com as credenciais em variável de ambiente. E **não** ativar `rawBody`, que sem assinatura só serve para complicar o parse.

### B. A condição de filtro do Workflow 1 tem um bug

O prompt define: *"só prossegue se `current.stage_id == 16` e `previous.stage_id != 16`"*.

Na v2 do webhook, o objeto `previous` **contém apenas os campos que mudaram**. Se você editar um negócio que já está na etapa 16 sem mexer na etapa, `previous.stage_id` vem **ausente** — e `undefined != 16` avalia como verdadeiro. O filtro dispararia exatamente no caso que ele deveria impedir.

**Correção necessária:**

```js
const atual    = $('CODE Validar - Payload').item.json.data;
const anterior = $('CODE Validar - Payload').item.json.previous || {};
const mudouEtapa = Object.prototype.hasOwnProperty.call(anterior, 'stage_id');
return atual.stage_id === ID_EM_CADENCIA && mudouEtapa && anterior.stage_id !== ID_EM_CADENCIA;
```

A guarda de idempotência do passo 3 continua necessária — ela cobre a entrega duplicada do webhook, que é um problema diferente.

Nota adicional: as chaves de topo na v2 são `meta`, `data` e `previous` — **não** `current`.

### C. `type` da atividade usa `key_string`, não ID numérico

Provado empiricamente na sessão anterior: o PATCH da atividade 84 só funcionou com `diagnostico_meet`. Passar `15` não funciona.

Portanto `pipedrive_config` precisa guardar **as duas colunas** — o ID (para leitura e comparação) e a `key_string` (para escrita).

| Tipo | ID | `key_string` |
| --- | --- | --- |
| T1 Comentário LinkedIn | 7 | `t1__comentario_linkedin` |
| T2 Convite Conexão | 8 | `t2__convite_conexao` |
| T3 E-mail Abertura | 9 | `t3__e_mail_abertura` |
| T4 Valor | 10 | `t4__valor` |
| T5 Convite Diagnóstico | 11 | `t5__convite_diagnostico` |
| T6 Break-up | 12 | `t6__break_up` |
| Triagem WhatsApp | 13 | `triagem_whatsapp` |
| Ligação de Resgate | 14 | `ligacao_de_resgate` |
| Diagnóstico (Meet) | 15 | `diagnostico_meet` |

Todos os IDs do prompt foram confirmados por GET, assim como as etapas 15, 16, 17 e 26 do funil 2.

---

## SQL para `pipedrive_config`

Para você rodar no SQL Editor do Supabase. A tabela não existe, então isto cria do zero.

```sql
create table if not exists public.pipedrive_config (
  chave        text primary key,
  valor_id     bigint,
  valor_texto  text,
  descricao    text not null,
  atualizado_em timestamptz not null default now()
);

comment on table public.pipedrive_config is
  'Mapeia chaves opacas e IDs do Pipedrive para nomes legiveis. Nunca escrever IDs soltos nos workflows do n8n.';

insert into public.pipedrive_config (chave, valor_id, valor_texto, descricao) values
  ('PIPELINE_PROSPECCAO',        2,  null, 'Funil 01 - Prospeccao'),
  ('STAGE_LISTA_PROSPECCAO',    15,  null, 'Etapa: Lista de Prospeccao'),
  ('STAGE_EM_CADENCIA',         16,  null, 'Etapa: Em Cadencia - dispara a criacao da cadencia'),
  ('STAGE_QUALIFICADO',         17,  null, 'Etapa: Qualificado - Formulario Preenchido'),
  ('STAGE_DIAGNOSTICO_AGENDADO',26,  null, 'Etapa: Diagnostico Agendado'),
  ('ATIVIDADE_T1',               7,  't1__comentario_linkedin', 'T1 - Comentario LinkedIn'),
  ('ATIVIDADE_T2',               8,  't2__convite_conexao',     'T2 - Convite Conexao'),
  ('ATIVIDADE_T3',               9,  't3__e_mail_abertura',     'T3 - E-mail Abertura'),
  ('ATIVIDADE_T4',              10,  't4__valor',               'T4 - Valor'),
  ('ATIVIDADE_T5',              11,  't5__convite_diagnostico', 'T5 - Convite Diagnostico'),
  ('ATIVIDADE_T6',              12,  't6__break_up',            'T6 - Break-up'),
  ('ATIVIDADE_TRIAGEM_WHATSAPP',13,  'triagem_whatsapp',        'Triagem WhatsApp'),
  ('ATIVIDADE_LIGACAO_RESGATE', 14,  'ligacao_de_resgate',      'Ligacao de Resgate'),
  ('ATIVIDADE_DIAGNOSTICO_MEET',15,  'diagnostico_meet',        'Diagnostico (Meet)'),
  ('LABEL_QUALIFICADO',         65,  null, 'Etiqueta de negocio: Qualificado'),
  ('LABEL_ROTA_1',              68,  null, 'Etiqueta de negocio: Rota 1 (Start)'),
  ('LABEL_ROTA_2',              69,  null, 'Etiqueta de negocio: Rota 2 (Modular)')
on conflict (chave) do update
  set valor_id      = excluded.valor_id,
      valor_texto   = excluded.valor_texto,
      descricao     = excluded.descricao,
      atualizado_em = now();
```

A linha `LABEL_ENGAJOU` fica de fora porque a etiqueta ainda não existe. Assim que eu a criar, o `insert` correspondente sai com o ID real.

**RLS:** a tabela nasce sem row level security. Como o n8n acessa com a chave de serviço, funciona — mas convém habilitar RLS e criar uma policy de leitura antes de considerar isso produção.

---

## Workflow 1 — `WEB - Pipedrive - CriarCadencia`

Gatilho: webhook `deal.updated`.

| # | Nó | Função |
| --- | --- | --- |
| 1 | `WEBHOOK Pipedrive - Receber DealUpdated` | POST, sem barra final, credencial Basic Auth |
| 2 | `CODE Validar - Payload` | Confere `meta.action`, `meta.entity`, presença de `data`; normaliza a saída |
| 3 | `GET Supabase - Ler PipedriveConfig` | Carrega IDs e `key_strings` |
| 4 | `IF Filtrar - Entrou Em Cadencia` | `data.stage_id == STAGE_EM_CADENCIA` **e** `previous` possui `stage_id` **e** difere |
| 5 | `GET Pipedrive - Buscar Negocio` | Traz `org_id`, `person_id` e o nome da organização |
| 6 | `GET Pipedrive - Buscar Atividades Do Negocio` | `?deal_id=X` |
| 7 | `IF Guarda - Ja Existe T1` | Se houver atividade do tipo T1, desvia |
| 8 | `POST Discord - Log Cadencia Duplicada` | Ramo da guarda; registra e encerra |
| 9 | `CODE Calcular - Datas Uteis` | T1 hoje · T2 +2 · T3 +3 · T4 +8 dias úteis, empurrando fim de semana |
| 10 | `POST Pipedrive - Criar T1` | |
| 11 | `POST Pipedrive - Criar T2` | |
| 12 | `POST Pipedrive - Criar T3` | |
| 13 | `POST Pipedrive - Criar T4` | |
| 14 | `POST Discord - Confirmar Cadencia` | Negócio, organização e as quatro datas |
| 15 | `STICKY Nota - Escopo` | Registra que T5 e T6 pertencem ao Workflow 3 |

Error Workflow: `SUB - Global - TratamentoErro`.

## Workflow 2 — `CRON - Pipedrive - AgendaDoDia`

Gatilho: Schedule 07:00, seg–sex, `America/Sao_Paulo`.

| # | Nó | Função |
| --- | --- | --- |
| 1 | `SCHEDULE Trigger - 07h Dias Uteis` | `0 7 * * 1-5` |
| 2 | `GET Supabase - Ler PipedriveConfig` | Para traduzir tipo → rótulo legível |
| 3 | `GET Pipedrive - Buscar Atividades Pendentes` | `?done=false&limit=500` |
| 4 | `CODE Separar - Hoje e Atrasadas` | Compara `due_date` com hoje no fuso de São Paulo |
| 5 | `CODE Formatar - Mensagem Discord` | Agrupa por tipo, ordena T1→T6 e depois triagem |
| 6 | `POST Discord - Postar Agenda` | Mensagem única; se vazio, posta a linha de confirmação |
| 7 | `STICKY Nota - Somente Leitura` | Registra que o workflow nunca marca nada como concluído |

## Workflow 3 — `WEB - Pipedrive - AvancarCadencia`

Gatilho: webhook `activity.updated`.

| # | Nó | Função |
| --- | --- | --- |
| 1 | `WEBHOOK Pipedrive - Receber ActivityUpdated` | POST, Basic Auth |
| 2 | `CODE Validar - Payload` | Normaliza `meta`/`data`/`previous` |
| 3 | `GET Supabase - Ler PipedriveConfig` | |
| 4 | `IF Filtrar - Toque Concluido` | `data.done === true` **e** `previous.done === false` **e** tipo ∈ {T4, T6} |
| 5 | `GET Pipedrive - Buscar Negocio` | Lê `label_ids` |
| 6 | `GET Pipedrive - Buscar Atividades Do Negocio` | Guarda de idempotência para T5/T6 |
| 7 | `SWITCH Rotear - PorTipoDeToque` | Ramifica T4 / T6 |
| 8 | `IF Verificar - Tem Etiqueta Engajou` | Ramo T4 |
| 9 | `CODE Calcular - Data T5` → `POST Pipedrive - Criar T5` → `POST Discord - Notificar Engajamento` | +2 dias úteis |
| 10 | `CODE Calcular - Data T6` → `POST Pipedrive - Criar T6` → `POST Discord - Notificar BreakUp` | +7 dias úteis |
| 11 | `IF Verificar - Engajamento Tardio` | Ramo T6 |
| 12 | `POST Discord - Alertar Engajamento Tardio` | Só avisa; nenhuma escrita no CRM |
| 13 | `IF Chave - Marcar Perdido Habilitado` | **Interruptor:** lê `$env.CADENCIA_MARCAR_PERDIDO` |
| 14 | `PATCH Pipedrive - Marcar Negocio Perdido` | `status: lost`, `lost_reason: "Silêncio"` |
| 15 | `POST Discord - Notificar Perda` | |
| 16 | `STICKY Nota - Unico Ponto De Perda` | Documenta o interruptor e o ramo |

**Sobre o interruptor:** o nó 13 lê uma variável de ambiente nova, `CADENCIA_MARCAR_PERDIDO`. Com `false`, o ramo de perda para ali e o resto do workflow segue funcionando. É a forma mais limpa de atender ao seu requisito de desligar só esse ramo — desativar o nó pelo editor exigiria republicar o workflow.

---

## Variáveis de ambiente exigidas

| Variável | Situação | Uso |
| --- | --- | --- |
| `PIPEDRIVE_API_TOKEN` | **não verificada** | Header `x-api-token` |
| `DISCORD_WEBHOOK_CADENCIA` | **não verificada** | Destino das mensagens |
| `PIPEDRIVE_WEBHOOK_USER` | **nova** | Basic Auth da subscrição |
| `PIPEDRIVE_WEBHOOK_PASS` | **nova** | Basic Auth da subscrição |
| `CADENCIA_MARCAR_PERDIDO` | **nova** | Interruptor do ramo de perda |
| `SUPABASE_URL` / `SUPABASE_SECRET_KEY` | **não verificadas** | Leitura de `pipedrive_config` |

---

## Decisões que tomei por conta própria

1. **Basic Auth no lugar de validação de assinatura** — o Pipedrive não oferece assinatura. Sem alternativa técnica.
2. **Não ativar `rawBody`** — o padrão do projeto o exige para ler a assinatura. Sem assinatura, ele só atrapalha o parse.
3. **Cálculo de dias úteis inline, em Code Node** — não criei um `SUB - Global - DiasUteis`. São poucas linhas repetidas em dois workflows. Se preferir o sub-workflow pela reutilização, digo que é a escolha mais correta a longo prazo; só não quis criar um quarto workflow sem você pedir.
4. **Interruptor por variável de ambiente** em vez de nó desativado — atende melhor ao requisito de desligar sem quebrar.
5. **`pipedrive_config` com duas colunas de valor** — `valor_id` e `valor_texto`, por causa da distinção entre ID e `key_string`.
