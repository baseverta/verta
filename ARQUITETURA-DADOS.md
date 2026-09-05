# Arquitetura de Dados — Verta

> Decisão tomada em 2026-09-05. Este documento é a referência de onde cada dado mora
> e quem manda quando as duas fontes discordam.

## A regra

**Supabase é a fonte da verdade. Pipedrive é o espelho completo.**

- **Supabase (fonte da verdade)** — é onde as automações leem para tomar decisão.
  Guarda o que o Pipedrive não consegue guardar bem: histórico de conversas,
  embeddings da base de conhecimento, sessões de qualificação, auditoria de
  transcrições, tokens de rastreio. Conexão SQL direta, com JOIN e funções próprias
  (`normalize_phone_br`), sem limite de requisição.

- **Pipedrive (espelho completo)** — é onde um humano abre e vê tudo sobre o cliente.
  Toda informação que uma pessoa possa precisar consultar tem que estar lá também.
  É também **fonte secundária de consulta** para as automações quando o Supabase
  tem lacuna (ex.: descobrir a Organização a partir do e-mail de um participante
  de reunião que ainda não é lead).

### Por que não o contrário

Foi avaliado usar o Pipedrive como fonte da verdade e descartado por três motivos:

1. **Consulta** — as automações fazem JOIN, normalização de telefone e busca
   vetorial. A API do Pipedrive não faz JOIN nem query arbitrária.
2. **Caminho quente** — cada mensagem de WhatsApp dispara várias consultas. Pela
   API isso viraria 2-3 chamadas externas por mensagem, com latência e risco de
   rate limit. Em SQL local é instantâneo.
3. **Modelo de dados** — conversas, embeddings e auditoria não têm lugar natural
   no CRM.

## Onde cada dado mora

| Dado | Supabase | Pipedrive |
|---|---|---|
| Identidade do lead (nome, e-mail, telefone) | `leads` | Person (nativo) |
| Empresa | `leads.company` | Organization (nativo) |
| Cargo | `leads.job_title` | Person → campo `Cargo` |
| Origem do contato | `leads.source` | Person → campo `Origem do contato` |
| Qualificação (gargalo, faturamento) | `leads`, `qualification_sessions` | Deal → campos customizados |
| Estágio comercial | `qualification_sessions.state` | Deal (stage/pipeline) |
| Status de agendamento | `qualification_sessions` | Deal → `Status do Agendamento` |
| Pasta do cliente no Drive | `leads.drive_folders` (jsonb) | Organization → `Pasta no Drive` |
| Chave de ligação entre os dois | `leads.id` | Organization → `Lead ID (Supabase)` |
| Conversas de WhatsApp | `conversations` | — (não cabe) |
| Base de conhecimento + embeddings | `kb_*` | — (não cabe) |
| Auditoria de transcrições | `meeting_transcripts` | Activity de reunião |

## Como as automações identificam o cliente

Cascata por ordem de confiança. Se dois candidatos empatarem no **mesmo nível**,
o sistema **não escolhe** — manda para revisão humana em vez de arriscar arquivar
no cliente errado.

1. `email_exato` — e-mail do participante bate com `leads.email`
2. `pipedrive_org` — e-mail é de uma Pessoa no Pipedrive → Organização → lead
3. `dominio_email` — domínio corporativo bate (ignora gmail, hotmail, outlook e afins)
4. `titulo_reuniao` — nome da empresa aparece no título da reunião

## O que garante que nada se perde

- **Auditoria diária** (workflow `Auditoria de Integridade - Diaria`, 08h30) —
  varre o Supabase procurando dados que ainda não foram espelhados no Pipedrive/Drive
  ou que impedem alguma automação, e manda e-mail **só quando há algo a corrigir**.
- **Pasta de não identificadas** — transcrição sem cliente definido é arquivada
  numa pasta central em vez de descartada, com alerta explicando o motivo.
- **Idempotência** — `meeting_transcripts.recording_id` é único; reenvio não duplica.
- **Rastro de decisão** — cada transcrição arquivada registra `matched_by`, ou seja,
  qual regra da cascata a identificou.

## Regra de manutenção

Quando uma automação nova passar a capturar um dado novo do lead, atualizar
**todos** os pontos que espelham ou resumem esse dado: mapeamento para o Pipedrive
nos três workflows de entrada (WhatsApp, Typeform, Calendly), o `RESUMO.md` da pasta
do cliente, e as etiquetas do Deal.

## Confiança na entrada: todo webhook público é assinado

Os webhooks do n8n são URLs públicas. Sem verificação, qualquer pessoa que descubra
o endereço consegue **injetar um evento falso** — criar lead, disparar e-mail para
cliente, mexer no Pipedrive. Por isso todo webhook de terceiro valida assinatura
antes de qualquer efeito colateral:

| Origem | Como valida | Observação |
|---|---|---|
| Fathom | Standard Webhooks (`webhook-id`, `webhook-timestamp`, `webhook-signature`), HMAC-SHA256 sobre `id.timestamp.corpo`, janela de 5 min | segredo em base64 após `whsec_` |
| Typeform (×3) | `Typeform-Signature: sha256=<base64>`, HMAC-SHA256 sobre o corpo bruto | um segredo por formulário |
| Pipedrive | webhook próprio do CRM, autenticado na origem | — |
| Calendly | assinatura disponível, ainda **não** aplicada | próximo da fila |

O padrão em todos: `Webhook` → `Validar Assinatura` (Code) → `Assinatura OK?` (IF)
→ fluxo normal; o galho de recusa não vai a lugar nenhum, e o motivo fica no log
da execução. Três detalhes que não são óbvios:

- Validar assinatura exige o **corpo bruto** (`options.rawBody: true` no webhook).
  Com isso o corpo deixa de chegar em `$json.body` e passa a vir como binário —
  os nodes seguintes precisam ler o corpo já parseado pelo node de validação,
  nunca mais pelo node do webhook.
- O segredo mora **hardcoded no Code node**: o sandbox do Code node do n8n não lê
  Data Table nem credencial. É a mesma escolha feita para o Fathom.
- Ao ligar (ou girar) um segredo, gravar primeiro **na origem** e só depois subir a
  validação no n8n. A ordem inversa rejeita envio legítimo na janela entre os dois passos.

## Dados internos não são clientes

`leads.is_internal = true` marca registro da própria Verta (teste, "Cliente Zero").
Esses registros ficam fora da auditoria diária: não precisam de Organização no
Pipedrive nem de pasta no Drive, e sem essa marca geram alerta todo dia para sempre —
o que treina o time a ignorar o e-mail de auditoria, que é o pior resultado possível.
