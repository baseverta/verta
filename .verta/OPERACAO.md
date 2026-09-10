# OPERACAO.md

### Verta — Manual de Operação, Governança de Workflows e SLA

**Status:** Oficial e Ativo
**Versão:** 3.1
**Objetivo:** Estabelecer o padrão de engenharia para desenvolvimento no n8n, a mecânica de transbordo, a estrutura do chassi de fluxos e o compromisso contratual de nível de serviço.

---

## 1. Convenção de Nomenclatura

Projeto sem padrão de nomenclatura é impossível de manter sob pressão. A Verta adota **Prefix-Domain-Action**.

### 1.1 Workflows

**Formato:** `[GATILHO] - [DOMÍNIO] - [AÇÃO_EM_PASCAL_CASE]`

Prefixos permitidos:
- `WEB` — iniciado por webhook externo
- `CRON` — iniciado por tempo (Schedule Trigger)
- `SUB` — sub-workflow acionado por outro fluxo (Execute Workflow)
- `TRG` — iniciado por App Trigger nativo

Exemplos obrigatórios: `WEB - WhatsApp - InboundQualificacao`, `SUB - Global - TratamentoErro`, `CRON - Calendly - LembreteDiagnostico`, `WEB - Meta - StatusMensagem`.

### 1.2 Nós

Proibido manter nome padrão do n8n (`HTTP Request 1`, `IF 2`). O nome do nó funciona como contrato de variável.

**Formato:** `[MÉTODO/AÇÃO] [Sistema] - [Detalhe]`

- Ação: `POST Supabase - Criar Sessao`, `GET Pipedrive - Buscar Organizacao`
- Lógica: `IF - Dentro da Janela de 24h?`, `Switch - Intencao do Lead`
- **Nunca use `$json`.** Referencie pelo nome absoluto: `$('POST Supabase - Criar Sessao').item.json.id`. Renomear um nó quebra todas as referências subsequentes — trate renomeação como refactor, não como ajuste cosmético.

---

## 2. Arquitetura Modular (o chassi obrigatório)

Regras de negócio, prompts e CRM são personalizados por cliente, mas a arquitetura base é idêntica em todos. Isso garante que a engenharia saiba onde procurar falha sem decifrar fluxo espaguete.

1. **`WEB - WhatsApp - InboundQualificacao`** — motor principal. Recebe a mensagem, consulta a sessão no Supabase, chama a IA e executa o fluxo comercial. É aqui que a personalização acontece.
2. **`SUB - Global - TratamentoErro`** — captura falhas dos demais fluxos. Isolar o erro impede que uma queda do CRM derrube o envio da resposta no WhatsApp.
3. **`CRON - Calendly - LembreteDiagnostico`** — motor de redução de no-show. Consulta agendas e dispara lembretes, dentro ou fora da janela de 24h (usando template quando fora).
4. **`WEB - Meta - StatusMensagem`** — rota isolada para os webhooks de `statuses` (entregue, lido, falhou). Misturar isso no fluxo de inbound cria execução fantasma e estoura CPU da VPS.

---

## 3. Handoff: Discord como Inbox

A WhatsApp Cloud API oficial não tem aplicativo de celular nem WhatsApp Web. Para o humano assumir a conversa, seria necessária uma inbox paga (Chatwoot, Zendesk), que corrói a margem de um cliente que intervém pontualmente. A Verta usa Discord com Threads.

- **Gatilho de parada:** a IA atinge o limite de turnos, o usuário pede humano, ou a intenção é incerta. O n8n grava `human_takeover = true` na tabela `wa_sessions` do Supabase e a automação se cala.
- **Abertura da thread:** o n8n cria um tópico no canal `#transbordo` do Discord do cliente, com nome e telefone do lead, resumo da qualificação e a última mensagem recebida.
- **Intervenção:** o atendente responde na thread com `/r [mensagem]`. O n8n formata e envia pela API da Meta.
- **Devolução:** `/bot_on` grava `human_takeover = false` e a IA reassume no próximo contato.

Discord é o canal único de transbordo e de alerta interno. Telegram foi descontinuado nesta função (ver `DECISOES.md`).

---

## 4. Tratado de Nível de Serviço (SLA)

SLA na Verta não é jargão de marketing nem sinônimo de cota de horas. É compromisso numérico, escrito em contrato, com consequência definida. **Nenhuma proposta comercial sai sem este anexo preenchido.**

### 4.1 Escopo do compromisso

O SLA cobre **a camada operada pela Verta**: VPS, containers, motor n8n, banco interno, workflows e integrações mantidas por nós.

Não cobre indisponibilidade de terceiros — Meta, Anthropic/OpenAI, Google, CRM do cliente — nem falha causada por alteração feita pelo cliente na própria conta. Nesses casos vale o protocolo de comunicação de crise (4.4), não a penalidade.

### 4.2 Os quatro compromissos

| Compromisso | Meta | Medição |
| --- | --- | --- |
| **Disponibilidade mensal** | 99% da camada Verta | Uptime Kuma, ping a cada 60s, relatório mensal ao cliente |
| **Resposta a incidente crítico** | 4 horas úteis | Do alerta ou do aviso do cliente até a primeira resposta técnica |
| **Resolução de ajuste não crítico** | 2 dias úteis | Ajuste de prompt, correção de fluxo, mudança de regra |
| **Janela de atendimento** | Seg–Sex, 9h–18h (BRT) | Monitoramento é 24/7; intervenção humana é em horário comercial |

**Incidente crítico** = operação fora do ar ou perda de mensagens. Ajuste de comportamento da IA e mudança de escopo não são incidentes críticos.

### 4.3 Consequência de descumprimento

No primeiro ano de operação, descumprimento não justificado gera **crédito proporcional na fatura seguinte**, calculado sobre os dias de indisponibilidade. Não há multa financeira além do crédito.

Essa limitação é deliberada e honesta: uma operação solo não deve assinar penalidade que não consegue honrar. Prometer multa pesada e não pagar destrói mais reputação do que oferecer um compromisso menor e cumprir. A política é revista quando houver redundância de plantão.

### 4.4 Monitoramento e comunicação

- **Uptime Kuma:** container leve na VPS testando webhooks do n8n e Supabase a cada 60 segundos. Falha dispara `@here` no canal `#alertas-infra` do Discord da Verta.
- **Captura de erro da stack:** `SUB - Global - TratamentoErro` formata log e nome do nó e envia alerta detalhado para a engenharia.
- **Comunicação de crise:** em queda confirmada de terceiro, a Verta avisa antes do cliente perguntar. Mensagem padrão: *"Monitoramento Verta: identificamos instabilidade nos servidores da [fornecedor]. A recepção de mensagens pode apresentar latência. Nossa engenharia acionou o protocolo de contingência e acompanha o status oficial. Previsão de normalização: X."*
- **Relatório mensal:** disponibilidade apurada, incidentes do período e ajustes executados. Enviado sem o cliente pedir. É o que transforma o SLA de promessa em evidência.

---

## 5. Rotina de Continuidade (operação diária)

A política completa de backup está em `ARQUITETURA.md`, seção 4. A operação diária responsável por ela:

| Rotina | Frequência | Responsável |
| --- | --- | --- |
| Verificar sucesso do dump noturno | Diária, manhã | Engenharia |
| Commit dos workflows alterados | A cada deploy | Quem alterou |
| Conferir se a `N8N_ENCRYPTION_KEY` do cliente está no cofre | No go-live e a cada troca de VPS | Quem provisionou |
| Teste de restauração em VPS descartável | Mensal | Engenharia |
| Relatório de SLA ao cliente | Mensal | Engenharia |

Teste de restauração que falha é incidente e vira registro em `DECISOES.md`.

---

## 6. Checklist de Go-Live

Nenhum cliente entra em produção sem os oito itens marcados:

1. Health check completo verde (Supabase, CRM, auto-API do n8n).
2. Matriz de testes de conversa executada sem falha (início simples, qualificação, desqualificação, transbordo, mídia incompatível).
3. Handoff testado ponta a ponta: `/r` entrega no WhatsApp, `/bot_on` devolve o controle.
4. Uptime Kuma monitorando os webhooks do cliente.
5. `SUB - Global - TratamentoErro` conectado a todos os fluxos.
6. Rotina de backup rodando e **primeira restauração de teste concluída**.
7. `N8N_ENCRYPTION_KEY` registrada no cofre.
8. Anexo de SLA assinado e datado.
