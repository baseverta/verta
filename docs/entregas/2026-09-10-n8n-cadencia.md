# Relatório — Workflows de Cadência no n8n

**Executado em:** 09–10/09/2026 · **Instância:** `n8n.baseverta.com.br` (n8n 2.37.7)
**Resultado:** 4 workflows publicados, 2 subscrições de webhook criadas, **matriz de testes 8/8**, estado de teste desfeito.

---

## 1. Workflows criados

| Workflow | ID | Gatilho | Nós |
| --- | --- | --- | --- |
| `SUB - Global - TratamentoErro` | `na3Iqv9AOuHQJu49` | Error Trigger | 4 |
| `WEB - Pipedrive - CriarCadencia` | `XpFvLgtijsaUyYo9` | Webhook `deal.change` | 17 |
| `CRON - Pipedrive - AgendaDoDia` | `Gjq0xEKw1nNY8yPA` | Schedule `0 7 * * 1-5` | 7 |
| `WEB - Pipedrive - AvancarCadencia` | `VryqatFqsirmMMJv` | Webhook `activity.change` | 22 |

**URLs de webhook** — sem barra final:

- `https://n8n.baseverta.com.br/webhook/pipedrive-criar-cadencia`
- `https://n8n.baseverta.com.br/webhook/pipedrive-avancar-cadencia`

**Você não precisa cadastrá-las.** Já criei as duas subscrições no Pipedrive:

| ID | Objeto | Ação | Destino |
| --- | --- | --- | --- |
| `1904737` | `deal` | `change` | CriarCadencia |
| `1904738` | `activity` | `change` | AvancarCadencia |

Ambas na versão `2.0`, com Basic Auth. As credenciais foram geradas na própria VPS e **nunca passaram pelo chat** — vivem em `PIPEDRIVE_WEBHOOK_USER` e `PIPEDRIVE_WEBHOOK_PASS`.

Os três workflows apontam para `SUB - Global - TratamentoErro` em Settings → Error Workflow.

## 2. Nós, na ordem

### `SUB - Global - TratamentoErro`
1. `ERROR Trigger - Capturar Falha`
2. `CODE Formatar - Alerta De Falha`
3. `POST Discord - Alertar Engenharia`
4. `STICKY Nota - Chassi E Destino`

### `WEB - Pipedrive - CriarCadencia`
1. `WEBHOOK Pipedrive - Receber DealUpdated`
2. `CODE Validar - Autenticacao E Payload`
3. `GET Supabase - Ler PipedriveConfig`
4. `CODE Montar - Mapa De Configuracao`
5. `IF Filtrar - Entrou Em Cadencia`
6. `GET Pipedrive - Buscar Negocio`
7. `GET Pipedrive - Buscar Organizacao`
8. `GET Pipedrive - Buscar Atividades Do Negocio`
9. `CODE Calcular - Guarda E Datas Uteis`
10. `IF Guarda - Ja Existe T1`
11. `POST Discord - Log Cadencia Duplicada`
12. `POST Pipedrive - Criar T1`
13. `POST Pipedrive - Criar T2`
14. `POST Pipedrive - Criar T3`
15. `POST Pipedrive - Criar T4`
16. `POST Discord - Confirmar Cadencia`
17. `STICKY Nota - Escopo E Filtro`

### `CRON - Pipedrive - AgendaDoDia`
1. `SCHEDULE Trigger - 07h Dias Uteis`
2. `GET Supabase - Ler PipedriveConfig`
3. `GET Pipedrive - Buscar Atividades Pendentes`
4. `CODE Separar - Hoje E Atrasadas`
5. `CODE Formatar - Mensagem Discord`
6. `POST Discord - Postar Agenda`
7. `STICKY Nota - Somente Leitura`

### `WEB - Pipedrive - AvancarCadencia`
1. `WEBHOOK Pipedrive - Receber ActivityUpdated`
2. `CODE Validar - Autenticacao E Payload`
3. `GET Supabase - Ler PipedriveConfig`
4. `CODE Montar - Mapa De Configuracao`
5. `IF Filtrar - Toque Concluido`
6. `GET Pipedrive - Buscar Negocio`
7. `GET Pipedrive - Buscar Organizacao`
8. `GET Pipedrive - Buscar Atividades Do Negocio`
9. `CODE Avaliar - Engajamento E Guarda`
10. `SWITCH Rotear - PorTipoDeToque`
11. `POST Pipedrive - Criar T5`
12. `POST Discord - Notificar Engajamento`
13. `POST Pipedrive - Criar T6`
14. `POST Discord - Notificar BreakUp`
15. `POST Discord - Alertar Engajamento Tardio`
16. `IF Chave - Marcar Perdido Habilitado`
17. `PATCH Pipedrive - Marcar Negocio Perdido`
18. `POST Discord - Notificar Perda`
19. `POST Discord - Avisar Ramo Desligado`
20. `POST Discord - Log Guarda Idempotencia`
21. `STICKY Nota - Unico Ponto De Perda`
22. `STICKY Nota - Escopo E Sinal`

Nenhum nó com nome padrão do n8n. Nenhuma referência a `$json` — todo mapeamento usa o nome absoluto do nó.

## 3. Variáveis de ambiente

**Nenhuma das exigidas existia no container.** A auditoria mostrou 8 ausentes, incluindo `N8N_BLOCK_ENV_ACCESS_IN_NODE`, que o prompt afirmava já estar configurada.

| Variável | Antes | Agora |
| --- | --- | --- |
| `PIPEDRIVE_API_TOKEN` | ausente | definida |
| `PIPEDRIVE_WEBHOOK_USER` | ausente | gerada na VPS |
| `PIPEDRIVE_WEBHOOK_PASS` | ausente | gerada na VPS |
| `DISCORD_WEBHOOK_CADENCIA` | ausente | definida |
| `DISCORD_WEBHOOK_ALERTAS` | ausente | `#verta-infra` (`wh-verta-infra`) |
| `CADENCIA_MARCAR_PERDIDO` | ausente | `false` |
| `SUPABASE_URL` | ausente | definida |
| `SUPABASE_SECRET_KEY` | ausente | definida |
| `N8N_BLOCK_ENV_ACCESS_IN_NODE` | **ausente** | `false`, explícito |
| `NODE_FUNCTION_ALLOW_BUILTIN` | `crypto` | inalterada |

Os valores vivem em `/root/verta/.env`; o `docker-compose.yml` só os repassa por `${VAR}`. Backups gravados antes de qualquer edição: `docker-compose.yml.bak-20260909-231631` e `.env.bak-20260909-231631`.

## 4. SQL aplicado

`pipedrive_config` criada com **45 linhas** e RLS habilitado. O arquivo completo está em `pipedrive-config.sql`.

Duas colunas de valor, e a distinção importa: `valor_id` para leitura e comparação, `valor_texto` para escrita — a API de atividades exige a `key_string` (`t4__valor`), não o ID numérico.

Rodado via `psql` num container descartável na VPS, através do pooler `aws-0-us-west-2.pooler.supabase.com`. O host direto do Supabase resolve **apenas em IPv6** e a VPS não tem rota IPv6 — a conexão falha com `Network unreachable`. Fica registrado para a próxima vez.

## 5. Matriz de testes — 8/8

Todos com o negócio 71 e webhooks reais do Pipedrive, não simulados.

| # | Cenário | Esperado | Resultado | Evidência |
| --- | --- | --- | --- | --- |
| 1 | Mover para etapa 16 | 4 atividades, datas em dias úteis | ✅ | Atividades 85–88: T1 `10/09`, T2 `14/09`, T3 `15/09`, T4 `22/09` |
| 2 | Mover para 16 de novo | nada criado, guarda registra | ✅ | Exec `1215`: `ja_tem_t1: true` → `POST Discord - Log Cadencia Duplicada` |
| 3 | CRON manual | mensagem com grupos corretos | ✅ | Exec `1216` |
| 4 | CRON sem pendências | confirmação, sem silêncio | ✅ | Exec `1229` |
| 5 | T4 concluído **com** `Engajou` | T5 em +2 dias úteis | ✅ | Atividade 89, `due 14/09` |
| 6 | T4 concluído **sem** `Engajou` | T6 em +7 dias úteis | ✅ | Atividade 90, `due 21/09` |
| 7 | T6 concluído sem `Engajou` | negócio perdido, motivo Silêncio | ✅ | `status: lost`, `lost_reason: "Silêncio"` |
| 8 | Falha proposital | `TratamentoErro` captura e alerta | ✅ | Exec `1227`, `mode: error` |

**Teste 1** — o pulo de fim de semana está correto: 10/09 é quinta, e o T2 (+2 dias úteis) caiu na segunda 14/09, não no sábado.

**Teste 3** — mensagem postada:

```
📋 Cadência de hoje — quinta-feira, 10/09

VENCENDO HOJE (2)
• T1 Comentário LinkedIn (1): Verta
• Diagnóstico (Meet) (1): Diagnóstico (Meet) — Verta (teste)
```

**Teste 4** — `✅ Nada vencendo hoje e nada atrasado. Cadência em dia.`

**Teste 7, nas duas posições do interruptor:**

- Com `CADENCIA_MARCAR_PERDIDO=false`: o negócio **continuou aberto**. Exec `1222` mostra rota `marcar_perdido` → SWITCH saída 3 → `IF Chave` saída falsa → `POST Discord - Avisar Ramo Desligado`. O `PATCH Marcar Negocio Perdido` não executou.
- Com `true`: `status: lost`, `lost_reason: "Silêncio"`, `lost_time: 2026-09-10T03:43:05Z`.

O requisito de desligar só esse ramo sem quebrar o resto está comprovado nos dois sentidos.

**Teste 8** — o alerta montado:

```
🚨 Falha na stack Verta
Workflow: WEB - Pipedrive - CriarCadencia  (XpFvLgtijsaUyYo9)
No que falhou: CODE Validar - Autenticacao E Payload
Quando: 10/09/2026, 00:43:51 (BRT)
Erro: Credencial de webhook invalida [line 23]
```

Com stack e link direto para a execução.

**Divergência de método:** provoquei a falha com Basic Auth inválido em vez de derrubar o token do Pipedrive, para evitar um terceiro restart do container. A prova é equivalente e há uma segunda evidência independente: a exec `1211` capturou a falha real de `400` da API do Pipedrive durante o primeiro teste, antes da correção. Os dois caminhos acionaram o `TratamentoErro`.

### Dois defeitos encontrados e corrigidos

O primeiro teste falhou e expôs dois erros de formato da API. **A lógica estava correta desde o início** — Basic Auth, leitura do Supabase, filtro de transição e cálculo de dias úteis funcionaram na primeira execução.

1. **`person_id` é somente-leitura** no `POST /activities`. A API exige `participants: [{person_id, primary: true}]`. Corrigido nos 6 nós de criação de atividade dos Workflows 1 e 3.
2. **A v2 devolve `org_id` como número**, não como objeto com `.name`. O nome da organização saía como *"Organizacao sem nome"*. Corrigido com um nó `GET Pipedrive - Buscar Organizacao` em cada workflow.

## 6. Estado de teste desfeito

| Item | Antes | Depois |
| --- | --- | --- |
| Negócio 71 — etapa | 15 | **15** |
| Negócio 71 — status | `open` | **`open`** |
| Negócio 71 — `lost_reason` | vazio | **vazio** |
| Negócio 71 — etiquetas | `[65, 69]` | **`[65, 69]`** |
| Atividades do negócio | 1 (id 84) | **1 (id 84)** |
| Atividade 84 | 10/09 13:00, 45min, aberta | **idêntica** |
| `CADENCIA_MARCAR_PERDIDO` | `false` | **`false`** |

As seis atividades criadas pelos testes (85–90) foram excluídas. A etiqueta `Engajou` foi removida do negócio. A atividade 84 manteve horário, duração e a sala do Google Meet.

## 7. Decisões que tomei por conta própria

1. **Basic Auth no lugar de validação de assinatura.** O Pipedrive não assina webhooks — não existe HMAC em nenhuma versão. Registrado em `DECISOES.md`.
2. **`rawBody` desativado.** Sem assinatura para ler, ele só transformaria o corpo em binário e complicaria o parse.
3. **Filtro de transição verifica o campo alterado.** A condição do prompt (`previous.stage_id != 16`) tem um bug: na v2, `previous` só traz campos alterados, então editar um negócio já na etapa 16 deixa `previous.stage_id` ausente e `undefined != 16` é verdadeiro — recriaria a cadência a cada edição. O filtro exige `campos_alterados.includes('stage_id')`. Registrado em `DECISOES.md`.
4. **Interruptor por variável de ambiente**, não nó desativado: desativar pelo editor exige republicar e não sobrevive a um import.
5. **Imagem do n8n fixada em `2.37.7`.** O compose usava `:latest`, contra `ARQUITETURA.md` §3. Como eu precisava recriar o container para as variáveis, o `up -d` teria puxado a versão mais recente e poderia derrubar a produção. Registrado em `DECISOES.md`.
6. **Cálculo de dias úteis inline**, não em sub-workflow. São poucas linhas repetidas em dois lugares; um `SUB - Global - DiasUteis` seria mais correto a longo prazo, mas eu não criaria um quinto workflow sem você pedir.
7. **`neverError` nos nós do Discord.** Falha ao postar alerta não deve gerar erro dentro do tratador de erro.
8. **Ordem de exclusão invertida na limpeza:** criei tudo antes de apagar qualquer coisa, para que uma falha no meio nunca destruísse dado sem ter o substituto no lugar.

## 8. Pendências

1. ~~Criar o canal de alertas de infra.~~ **Resolvido em 10/09.** Os dois canais estão separados e verificados dentro do container:

   | Variável | Canal | ID do webhook |
   | --- | --- | --- |
   | `DISCORD_WEBHOOK_ALERTAS` | `#verta-infra` | `1547092251845468210` |
   | `DISCORD_WEBHOOK_CADENCIA` | `#verta-prosp` | `1547375285094064259` |

   Comprovado de ponta a ponta: a exec `1235` do `TratamentoErro`, disparada por uma falha real de autenticação, postou no canal de infra em 403ms. A separação por domínio que `OPERACAO.md` §4.4 exige está cumprida.

2. **Decidir o valor de `CADENCIA_MARCAR_PERDIDO`.** Está em `false`, então o único ponto de perda automática está desligado. Testado e funcionando nos dois estados.
3. **Rotacionar seis credenciais** que passaram pelo chat: token do Pipedrive, os dois webhooks do Discord, a secret key do Supabase, a senha do Postgres e o JWT do MCP do n8n.
4. **Desconectar o conector MCP do Supabase** — removi do `.mcp.json`, mas o conector em si continua autenticado na conta da Manekin.
5. **Limitação cosmética conhecida:** no `AgendaDoDia`, atividades cujo assunto não segue o padrão `Tipo: Organização` aparecem com o assunto inteiro em vez do nome da organização, porque a v2 não devolve o nome no objeto da atividade. Afeta só atividades fora da cadência.
