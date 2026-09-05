# Verta — Fluxo n8n WhatsApp Comercial

**Versão:** 1.0  
**Data:** agosto de 2026  
**Escopo:** WhatsApp da **própria Verta** (captação → qualificação → Diagnóstico).  
**Não é** o produto Atendimento 24/7 do cliente. Esse é outro workflow (mais módulos, CRM do cliente, prompts do cliente).

**Princípio:** Qualificador de 2 perguntas + handoff. Não é menu “digite 1”. Menu de bot contradiz o posicionamento.

---

## 1. O que este fluxo faz (e o que não faz)

**Faz:**
- Responde o primeiro contato em segundos
- Faz 2 perguntas (faturamento + gargalo)
- Classifica fit / sem fit / incerteza
- Envia link do Cal.com só para fit
- Cria/atualiza card no CRM
- Alerta você no Telegram quando precisar de humano
- Nunca falha em silêncio

**Não faz:**
- Vender, negociar preço, montar proposta
- Atender como “IA 24/7 da Verta”
- Segurar conversa longa
- Responder fora da janela de 24h com texto livre

---

## 2. Arquitetura

```text
WhatsApp Cloud API (WABA da Verta)
        │ webhook
        ▼
n8n  WF-01  Inbound + Qualificação
        │
        ├─ Postgres (sessão / estado)
        ├─ Claude Haiku (classificador, JSON)
        ├─ WhatsApp Cloud (resposta)
        ├─ HubSpot (deal/contact)
        ├─ Cal.com (só o link; o lead agenda)
        └─ Telegram (handoff + erro)

n8n  WF-02  Error Handler (Error Trigger)
n8n  WF-03  Lembrete Diagnóstico (Cron + Cal.com)
n8n  WF-04  Status de mensagem (entregue / falhou)
```

**Canal:** WhatsApp Cloud API oficial (produção).  
Evolution/WAHA: só em número de teste. Não usar no número público da Verta.

---

## 3. Restrição da API (obrigatório mapear antes de construir)

| Regra | Impacto no fluxo |
|-------|------------------|
| Janela de 24h após a última mensagem **do usuário** | Dentro da janela: texto livre. Fora: **somente template aprovado** |
| Templates precisam de aprovação | Ter 3 templates prontos antes do go-live |
| Webhook recebe mensagem **e** status | Filtrar `messages` vs `statuses` senão o fluxo dispara duas vezes |
| `messages[].id` é único | Deduplicar. Meta reenvia webhook |
| Rate limit | Retry com backoff no erro 429 / 5xx |
| Não armazenar mídia sensível sem necessidade | Ignorar áudio/imagem no comercial, pedir texto |

### Templates a submeter (categoria Utility)

1. `verta_inicio_qualificacao`  
   “Aqui é a Verta. Para ver se o Diagnóstico faz sentido: qual o faturamento mensal aproximado e o principal gargalo no atendimento hoje (latência, lead à noite, CRM desatualizado, no-show)?”

2. `verta_link_diagnostico`  
   “Com o que você descreveu, faz sentido o Diagnóstico de 30 min. Agenda: {{link}}”

3. `verta_lembrete_diagnostico`  
   “Lembrete: Diagnóstico Verta em {{data_hora}}. Se precisar reagendar, responda esta mensagem.”

Sem esses templates, o fluxo quebra no primeiro contato iniciado por vocês ou depois de 24h de silêncio.

---

## 4. Máquina de estados (sessão)

Tabela `wa_sessions` (Postgres/Supabase):

| Campo | Tipo | Uso |
|-------|------|-----|
| wa_id | text PK | telefone do lead (formato 55…) |
| phone_number_id | text | número da WABA que recebeu |
| state | text | ver abaixo |
| faturamento | text | faixa ou valor declarado |
| gargalo | text | latencia / lead_noite / crm / noshow / outro / bot_barato |
| intent | text | diagnostico / preco / sem_fit / incerteza / humano |
| last_user_msg_at | timestamptz | controle da janela 24h |
| last_message_id | text | dedup |
| human_takeover | boolean | true = bot cala a boca |
| hubspot_contact_id | text | |
| hubspot_deal_id | text | |
| cal_link_sent | boolean | |
| notes | text | recorte curto, não transcrição eterna |
| updated_at | timestamptz | |

**Estados:**

```text
NEW
  → ASK_FATURAMENTO
  → ASK_GARGALO
  → EVALUATE
       ├─ QUALIFIED  → envia Cal.com → BOOKED (quando Cal.com webhook confirmar)
       ├─ NO_FIT     → texto de desqualificação → CLOSED
       └─ HANDOFF    → Telegram → você assume
```

Máximo **3 mensagens automáticas** por conversa. Na 4ª interação do lead, se ainda não classificou: HANDOFF. Sem discussão infinita.

---

## 5. WF-01 — Inbound (nós, na ordem)

### 1. Webhook
- Método POST
- Path: `/webhook/verta-wa`
- Verificar `hub.challenge` no GET (verify token) — pode ser um workflow separado ou o mesmo com IF method=GET
- Body: payload Cloud API

### 2. IF — é mensagem de usuário?
Passar só se existir:
`body.entry[0].changes[0].value.messages[0]`

Descartar:
- `statuses` (vai para WF-04)
- mensagens `from` = seu próprio número
- tipos `system`, `reaction`

### 3. Set — normalizar

```text
wa_id            = messages[0].from
message_id       = messages[0].id
type             = messages[0].type
text             = messages[0].text.body   (se type=text)
timestamp        = messages[0].timestamp
phone_number_id  = value.metadata.phone_number_id
name             = value.contacts[0].profile.name
```

Se `type != text`: responder (dentro da janela):

> “Para eu te atender bem, manda em texto: faturamento aproximado da operação e o principal gargalo no atendimento.”

Não transcrever áudio neste fluxo. Custo e risco de alucinação sem ganho.

### 4. Postgres — dedup
SELECT por `last_message_id = message_id`.  
Se já existe → Stop (webhook duplicado).

### 5. Postgres — load/create session
Se não existe: `state=NEW`, `human_takeover=false`.

### 6. IF — human_takeover = true
Não responder. Só atualizar `last_user_msg_at` e notificar Telegram:

> `[WA] Lead {{name}} ({{wa_id}}) mandou: {{text}}`

Stop.

### 7. IF — janela de 24h
`now - last_user_msg_at > 24h` **e** esta mensagem ainda não reabriu a janela.

Atenção: a mensagem **atual do usuário reabre a janela**. Ou seja, se ele escreveu agora, você PODE responder texto livre.  
A trava de 24h vale quando **você** quer falar e o lead está calado (lembrete, follow-up). Isso é WF-03, com template.

Neste WF-01, após mensagem inbound, a janela está aberta. Seguir.

### 8. HTTP Request — classificador (Claude Haiku)

**Por que Haiku:** volume baixo, tarefa determinística, custo menor. Sonnet só no produto do cliente.

**System prompt (copiar):**

```text
Você é o classificador da Verta, não um vendedor.

A Verta instala e sustenta operação de IA (WhatsApp Oficial + CRM + agenda). Não vende chatbot avulso.

Extraia JSON estrito, sem markdown:
{
  "intent": "diagnostico" | "preco" | "agendar" | "humano" | "sem_fit" | "info" | "incerteza",
  "faturamento_faixa": "abaixo_3_5k" | "3_5k_15k" | "acima_15k" | "nao_informado",
  "gargalo": "latencia" | "lead_noite" | "crm" | "noshow" | "qualificacao" | "bot_barato" | "outro" | "nao_informado",
  "quer_bot_barato": true | false,
  "pede_humano": true | false,
  "resumo": "uma frase"
}

Regras:
- quer_bot_barato=true se pedir chatbot barato, R$99, só setup, “IA de graça”, Meta Agent como substituto total.
- sem_fit se faturamento abaixo_3_5k OU quer_bot_barato sem abertura a operação.
- incerteza se a mensagem for ambígua, ofensiva, jurídica, ou você não tiver certeza.
- Nunca invente faturamento ou gargalo.
```

**User:** estado atual da sessão + texto da mensagem.

**Resposta:** `response_format: json` (ou parse + IF se JSON inválido → HANDOFF).

Timeout 12s. Retry 1. Se falhar → WF-02 + mensagem padrão ao lead:

> “Recebi. Vou olhar e te retorno em instantes.”

### 9. Switch — estado + intent

#### A) state = NEW
Enviar (texto livre, janela aberta):

```text
Aqui é a Verta — engenharia de IA operacional.

Não vendemos bot avulso. Instalamos e sustentamos a operação que conecta WhatsApp Oficial ao CRM e à agenda.

Duas perguntas, para ver se o Diagnóstico de 30 min faz sentido:

1) Qual o faturamento mensal aproximado da operação?
2) Qual o principal gargalo hoje?
(latência de resposta / lead perdido à noite / CRM desatualizado / no-show)

Com isso eu te digo se agenda ou se não somos a melhor opção.
```

Set `state=ASK_FATURAMENTO` (se só veio saudação)  
Se a primeira mensagem **já trouxe** faturamento e gargalo, pular para EVALUATE.

#### B) Coleta incompleta
Se falta faturamento → perguntar só isso.  
Se falta gargalo → perguntar só isso.  
Não repetir o texto institucional.

#### C) EVALUATE — QUALIFIED
Critério automático (espelha a Técnica de Qualificação):

- Faixa `3_5k_15k` ou `acima_15k`
- Gargalo em {latencia, lead_noite, crm, noshow, qualificacao}
- `quer_bot_barato = false`

Resposta:

```text
Pelo que você descreveu, tem gargalo concreto. Faz sentido o Diagnóstico Operacional de 30 min.

Você sai com o mapa do processo e um sim ou não honesto.

Agenda aqui: {{CAL_LINK}}

Se preferir, me fala um horário e eu confirmo.
```

Ações:
- HubSpot: contact + deal estágio `Diagnóstico agendado` (ou `Qualificado` se ainda não clicou)
- `cal_link_sent=true`, `state=QUALIFIED`
- Telegram opcional: `[FIT] {{name}} | {{faixa}} | {{gargalo}}`

#### D) NO_FIT

```text
Pelo que você descreveu, não vejo gargalo/operação no que a Verta entrega.

A gente não trabalha com chatbot avulso nem com operação sem volume/dor clara. Existem ferramentas mais baratas para o que você precisa agora.

Se no futuro aparecer latência de atendimento, lead perdido fora do horário ou CRM parado, a gente conversa.
```

Deal HubSpot: `Sem fit`. `state=CLOSED`. Não insistir.

#### E) PREÇO (intent=preco, mas ainda sem desqualificar)

```text
O valor depende da rota (operação padronizada ou modular) e não é comparável a assinatura de bot.

A mensalidade cobre SLA e sustentação. Custos de mensagem da Meta e tokens são repassados.

O próximo passo certo é o Diagnóstico de 30 min — lá a gente vê se existe gargalo e qual rota cabe.

Quer que eu te mande o link para agendar?
```

Não citar R$ 2.800 / R$ 690 no WhatsApp automático. Preço na proposta, depois do Diagnóstico.

#### F) HUMANO / INCERTEZA
Resposta ao lead:

```text
Vou passar isso para o responsável e te retorno por aqui.
```

Telegram para você:

```text
HANDOFF WA
{{name}} | {{wa_id}}
intent={{intent}}
msg={{text}}
sessão={{state}} | fat={{faturamento}} | gargalo={{gargalo}}
```

`human_takeover=true`. Bot para.

**Comando seu no Telegram (opcional, WF extra):**  
`/bot_on 5511...` → `human_takeover=false`  
`/bot_off 5511...` → takeover

### 10. WhatsApp Cloud — Send Message
Node oficial n8n: WhatsApp Business Cloud → Send message.  
`phoneNumberId` da sessão.  
`recipientPhoneNumber` = wa_id.

### 11. Postgres — update session
Sempre: `last_user_msg_at`, `last_message_id`, campos extraídos, `updated_at`.

### 12. HubSpot
- Create/update contact: phone, firstname (profile.name), origem = `whatsapp`
- Deal: pipeline Verta, stage conforme estado
- Propriedades custom: `gargalo`, `faixa_faturamento`, `origem_detalhe`

Se HubSpot falhar: **não** falhar a resposta ao lead. Log + alerta Telegram. O WhatsApp tem prioridade.

---

## 6. WF-02 — Error Handler

Trigger: Error Trigger (ligado aos workflows 01, 03, 04).

Nós:
1. Set: workflow name, node, message, wa_id se existir
2. Telegram:

```text
ERRO n8n {{workflow}}
node: {{node}}
wa_id: {{wa_id}}
{{error.message}}
```

3. Se o erro foi **depois** de receber mensagem e **antes** de responder: tentar Send Message padrão (“Recebi. Já te retorno.”). Se isso também falhar, só o Telegram basta — você assume.

Nenhum `continueOnFail` silencioso em: Webhook, Send Message, classificador.  
`continueOnFail=true` só no HubSpot (secundário).

---

## 7. WF-03 — Lembretes de Diagnóstico

1. Cron a cada 15 min **ou** webhook Cal.com `BOOKING_CREATED` / `BOOKING_RESCHEDULED`
2. Salvar `booking_start`, `wa_id` (campo custom no Cal.com: telefone)
3. Em T-24h e T-2h: se janela 24h **fechada** → template `verta_lembrete_diagnostico`  
   se **aberta** → texto livre equivalente
4. Se booking cancelado: parar lembretes, deal `No-show risco` ou `Cancelou`

Não mandar mais de 2 lembretes. Sem sequência de nutrição no WhatsApp.

---

## 8. WF-04 — Status de entrega

Webhook `statuses`:
- `failed` → Telegram + marcar sessão `last_send_failed=true`
- `failed` com código de template/janela → você reenvia template manualmente
- `delivered` / `read` → só log, sem ação

---

## 9. Cal.com → n8n (fechamento do ciclo)

Webhook Cal.com no n8n:
- `BOOKING_CREATED` → deal `Diagnóstico agendado`, `state=BOOKED`
- `BOOKING_CANCELLED` → stage `Cancelou`
- `BOOKING_RESCHEDULED` → atualizar data

Campo obrigatório no evento Cal.com: telefone (para achar `wa_id`).

---

## 10. Prompt e limites (R4 aplicado na Verta)

O classificador **não conversa**. Só devolve JSON.  
Quem “fala” com o lead são **textos fixos** acima. Isso elimina alucinação de preço, prazo e escopo.

Handoff imediato se:
- JSON inválido
- intent=incerteza
- pede_humano=true
- assunto jurídico / LGPD detalhado / reclamação
- 3 turnos sem classificar faixa+gargalo
- tom agressivo

---

## 11. LGPD (mínimo neste fluxo)

- Guardar em `notes` só resumo de 1 linha, não o histórico completo
- Retention: sessões `CLOSED` / `NO_FIT` apagar PII em 90 dias (cron)
- Não baixar áudio/imagem
- No texto de ausência/início, não precisa de “concordo com termos” teatral; no site/contrato sim
- Acesso ao Postgres só no n8n e no seu user

---

## 12. Variáveis de ambiente no n8n

```text
WA_PHONE_NUMBER_ID
WA_ACCESS_TOKEN
WA_VERIFY_TOKEN
WA_BUSINESS_ACCOUNT_ID
CLAUDE_API_KEY
HUBSPOT_TOKEN
TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID
CAL_LINK=https://cal.com/verta/diagnostico
DATABASE_URL
```

Credenciais no n8n Credentials, não hardcoded em nós.

---

## 13. Ordem de montagem (não pular)

1. WABA + número de **teste** + webhook apontando para n8n  
2. Tabela `wa_sessions`  
3. WF-01 até o ponto de eco (receber e responder “ok”) **sem** IA  
4. WF-02 erro  
5. Classificador Haiku + estados  
6. Textos de QUALIFIED / NO_FIT / PREÇO / HANDOFF  
7. HubSpot  
8. Templates aprovados  
9. WF-03 lembretes  
10. Trocar para número público da Verta  

Critério de “pronto”: você manda 5 mensagens reais (saudação, preço, bot barato, faturamento+gargalo, áudio) e o fluxo se comporta como a matriz abaixo.

---

## 14. Matriz de teste (obrigatória)

| Entrada do lead | Estado esperado | Resposta |
|-----------------|-----------------|----------|
| “Oi” | ASK_FATURAMENTO | Texto institucional + 2 perguntas |
| “Fatura 8 mil, perco lead à noite” | QUALIFIED | Link Cal.com |
| “Quero um bot de 99 reais” | NO_FIT | Desqualificação |
| “Quanto custa?” | (preço) | Contraste + convite Diagnóstico, sem tabela de preço |
| Áudio | — | Pedir texto |
| “Quero falar com alguém” | HANDOFF | Confirmação + Telegram |
| 2ª mensagem depois de takeover | — | Silêncio do bot + Telegram |

---

## 15. Diferença para o fluxo do CLIENTE (não misturar)

| | WhatsApp comercial Verta (este doc) | Produto do cliente |
|--|-------------------------------------|--------------------|
| Objetivo | Qualificar e agendar Diagnóstico | Atender / agendar / CRM do cliente |
| Turnos de IA | Máx. 3, textos fixos | Prompt do cliente + handoff |
| CRM | HubSpot da Verta | CRM/planilha do cliente |
| Templates | 3 da Verta | templates do nicho do cliente |
| Risco | Lead ruim no seu tempo | Operação 24/7 com SLA |

Não reutilize este workflow como template da Rota 1. Copiar gera menu de bot no cliente e quebra o produto.

---

**Construir nesta ordem. Se o classificador começar a “conversar”, você perdeu o controle de escopo — volte para textos fixos.**
