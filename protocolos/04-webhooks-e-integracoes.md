# 04 — Webhooks e integrações

## Todo webhook público é assinado

URL de webhook do n8n é pública. Sem verificação, qualquer um que descubra o
endereço injeta evento falso: cria lead, dispara e-mail para cliente, mexe no CRM.

O padrão, igual em todos:

```
Webhook → Validar Assinatura (Code) → Assinatura OK? (IF)
                                       ├─ verdadeiro → fluxo normal
                                       └─ falso      → nada (motivo fica no log)
```

O galho de recusa não vai a lugar nenhum de propósito. Responder 401 exigiria
`responseMode: responseNode`, e não vale a complexidade: quem manda evento falso não
merece diagnóstico.

### Estado atual

| Origem | Assinatura | Formato |
|---|---|---|
| Fathom | sim | Standard Webhooks: `webhook-id`, `webhook-timestamp`, `webhook-signature`; HMAC-SHA256 sobre `id.timestamp.corpo`; janela de 5 min; segredo é base64 depois de `whsec_` |
| Typeform ×3 | sim | `Typeform-Signature: sha256=<base64>`; HMAC-SHA256 sobre o corpo bruto; um segredo por formulário |
| Pipedrive | própria | autenticado na origem |
| Calendly | **não** | suporta; próximo da fila |

## As três pegadinhas de ligar assinatura

**1. Validar exige o corpo bruto, e isso quebra quem lia o corpo.**
Ligar `options: { rawBody: true }` no webhook faz o corpo parar de chegar em
`$json.body` — vem como binário em `item.binary.data.data`, base64. Todo node que
lia o webhook precisa passar a ler o node de validação:

```js
// antes
const body = $('Webhook Onboarding').item.json.body;
// depois
const body = $('Validar Assinatura Typeform').item.json.body;
```

Esquecer isso é falha silenciosa: o workflow passa a validação e normaliza um objeto
vazio.

**2. O segredo fica hardcoded no Code node.** O sandbox não lê Data Table nem
credencial. É consciente, não preguiça.

**3. A ordem de ligar importa.** Grave o segredo **na origem primeiro** (o workflow
ainda ignora o header e segue funcionando) e só depois suba a validação. Na ordem
inversa existe uma janela em que envio legítimo de cliente é rejeitado.

Mesma regra para **girar** um segredo.

## Como testar assinatura sem sujar dados

Três casos, sempre: sem assinatura, assinatura errada, assinatura válida. Os dois
primeiros são seguros em qualquer workflow — são justamente os que não devem passar.

O terceiro exige cuidado: em fluxo que **cria** registro (o formulário de
diagnóstico cria lead, Organização e pasta), um teste com assinatura válida cria
tudo de verdade. Duas saídas:

- Use um workflow de estrutura idêntica que **não** cria nada — no nosso caso o
  Kickoff e o Onboarding param sozinhos quando o lead não é encontrado.
- Ou aceite não testar o caminho válido nesse workflow, e **diga isso** no relato,
  em vez de fingir cobertura.

Depois de qualquer teste, confira que o banco não ficou com resíduo.

## Registro do webhook na origem — conferir, não presumir

Já perdemos horas com webhook que "não disparava" e estava certo. Antes de
investigar workflow, confirme na origem:

```
Pipedrive:  GET /v1/webhooks
Calendly:   GET /webhook_subscriptions?organization=...&scope=organization
Typeform:   GET /forms/{id}/webhooks   (confira também enabled: true)
```

Confira **três** coisas: existe, aponta para o path certo, e está habilitado.

### O caso Fathom

O webhook não disparava por dois motivos ao mesmo tempo, nenhum deles bug:

1. Estava configurado para incluir Summary e Action Items, que **nunca foram
   gerados** para uma gravação de 44 segundos. Sem eles, não dispara.
2. Depois de recriado, só dispara para gravações feitas **depois** da criação do
   webhook. Gravação antiga não volta.

Regra geral: ao criar webhook em qualquer ferramenta, **faça um evento novo para
testar**. Não conte com histórico.

## Identificar o cliente sem chutar

O fluxo de transcrição usa cascata com prioridade, e **recusa decidir** quando fica
ambíguo — manda para uma pasta central com alerta em vez de arquivar no cliente
errado:

1. `email_exato` — e-mail do participante bate com `leads.email`
2. `pipedrive_org` — e-mail é de uma Pessoa no Pipedrive → Organização → lead
3. `dominio_email` — domínio corporativo bate (ignora gmail, hotmail e afins)
4. `titulo_reuniao` — nome da empresa aparece no título

Cada arquivamento registra `matched_by`, então dá para auditar por qual regra cada
decisão passou.

**Não preencha o e-mail principal do lead com e-mail de participante de reunião.**
Pode ser outra pessoa da empresa, e você grava contato errado como principal.
Participante vai para `client_contacts`, que é o lugar dele.

## Idempotência

Todo webhook pode chegar duas vezes. Chave única na origem do evento resolve — em
transcrição é `meeting_transcripts.recording_id`, com `ON CONFLICT DO NOTHING`.
Antes de conectar qualquer ferramenta nova, responda: **qual campo do evento é o
identificador único?** Se não houver, invente um a partir do conteúdo.
