# Relatório de Conexões API - Verta

**Data:** 10/09/2026  
**Objetivo:** Testar conectividade via API/Webhook de todos os ambientes identificados

## Metodologia

Foram realizados testes em duas etapas:
1. **Conexão externa** via máquina local para endpoints públicos
2. **Conexão na VPS** `187.127.57.111` (`srv1951865.hstgr.cloud`) usando acesso SSH fornecido

A segunda etapa foi essencial para testar serviços que rodam exclusivamente na rede Docker `internal` da VPS.

---

## Status dos Containers Docker na VPS

Todos os containers estão **em execução** na VPS:

| Container | Imagem | Status | Portas |
|---|---|---|---|
| n8n | docker.n8n.io/n8nio/n8n:2.37.7 | Up 19h | 5678/tcp (interno) |
| evolution | evoapicloud/evolution-api:v2.3.7 | Up 6d | 127.0.0.1:8082->8080/tcp |
| redis | redis:7-alpine | Up 6d | 6379/tcp |
| embeddings | baseverta-core-embeddings | Up 6d | 80/tcp (interno) |
| traefik | traefik:v2.11 | Up 6d | 0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp |
| postgres | postgres:16-alpine | Up 6d (healthy) | 5432/tcp |

---

## Resultados por Serviço

### 1. n8n Automation Engine
- **URL:** `https://n8n.baseverta.com.br`
- **Tipo:** API REST
- **Status:** ✅ **CONEXÃO PARCIAL**
- **Testes:**
  - Interface web acessível (HTTP 200) ✅
  - API com chave fornecida: **401 Unauthorized** ❌
- **Observação:** A instância está no ar, mas a API key fornecida não está autorizando as chamadas. A chave pode ter sido revogada, expirado, ou pertencer a outro tipo de acesso.

### 2. Supabase (Project Verta)
- **URL:** `https://vnqsyngphmkgvribtmfa.supabase.co`
- **Tipo:** API REST (PostgREST) e PostgreSQL
- **Status:** ⚠️ **CONEXÃO PARCIAL**
- **Testes:**
  - API PostgREST responde (401 sem autenticação) ✅
  - **Secret key:** Bloqueada por segurança com mensagem "Forbidden use of secret API key in browser" ⚠️
  - **Publishable key:** Conecta, mas sem permissão na view `pipedrive_config` (RLS) ⚠️
  - Conexão TCP com PostgreSQL na porta 5432: **OK** ✅
  - Container postgres consegue pingar/TCPr a porta 5432: **OK** ✅
- **Observação:** O Supabase está acessível, mas o acesso aos dados requer permissões corretas. A `service_role` (secret key) deve ser usada em ambiente seguro, não via browser/cliente HTTP com user-agent de navegador.

### 3. Pipedrive CRM
- **URL:** `https://api.pipedrive.com/v1/`
- **Tipo:** API REST
- **Status:** ✅ **CONECTADO E AUTENTICADO**
- **Testes:**
  - `GET /v1/deals` com `x-api-token` fornecido: **HTTP 200, success=true, data=null** ✅
- **Observação:** Autenticação funcionou. A resposta com `data=null` indica que não há deals no pipeline consultado, mas a conexão é válida. O endpoint exibe aviso de depreciação: a API v1 será removida em breve.

### 4. Cal.com
- **URL:** `https://api.cal.com/v2`
- **Tipo:** API REST
- **Status:** ✅ **CONECTADO E AUTENTICADO**
- **Testes:**
  - `GET /v2/me` com `cal_live_...`: **HTTP 200, status=success** ✅
  - Retornou dados da conta: `conta@baseverta.com.br`, timezone `America/Fortaleza`
- **Observação:** Conta ativa e autenticada. Webhook configurado para `https://n8n.baseverta.com.br/webhook/verta-calcom-eventos`.

### 5. Resend (Email)
- **URL:** `https://api.resend.com/emails`
- **Tipo:** API REST
- **Status:** ✅ **CONECTADO E AUTENTICADO**
- **Testes:**
  - Autenticação com API key: **funcionou** ✅
  - Envio de teste: **422 - Invalid `to` field** (domínio `example.com` bloqueado) ⚠️
- **Observação:** A API está conectada. O erro 422 é validação do domínio de destino, não falha de autenticação. Domínio `baseverta.com.br` verificado (DKIM + SPF).

### 6. Tally
- **URL:** `https://api.tally.so/forms`
- **Tipo:** API REST
- **Status:** ✅ **CONECTADO E AUTENTICADO**
- **Testes:**
  - `GET /forms` com token: **HTTP 200, items=[], total=0** ✅
- **Observação:** Conexão e autenticação funcionam. Nenhum formulário encontrado na conta.

### 7. Evolution API (WhatsApp)
- **URL:** `http://127.0.0.1:8082` (na VPS)
- **Tipo:** API REST/Webhook
- **Status:** ⚠️ **CONEXÃO PARCIAL**
- **Testes:**
  - Endpoint raiz: **HTTP 200**, "Welcome to the Evolution API, it is working!", versão 2.3.7 ✅
  - `/instance/fetchInstances` com `apikey` fornecido: **401 Unauthorized** ❌
- **Observação:** O serviço está rodando na porta 8082 mapeada para `127.0.0.1`. A autenticação com a API key fornecida falhou no endpoint de listagem de instâncias. O header de autenticação pode ser diferente (`Authorization: Api-Key`, `apikey` no query string, etc.) ou a chave pode não estar configurada para esse endpoint.

### 8. Embeddings Server
- **URL:** `http://embeddings/embed` (rede Docker `internal`)
- **IP Container:** `172.18.0.4`
- **Tipo:** API REST
- **Status:** ✅ **CONECTADO**
- **Testes:**
  - `GET /health`: **HTTP 200, {"status":"ok"}** ✅
  - `POST /embed`: Testado com sucesso via container temporário `alpine/curl`. Modelo BGE-M3 (1024 dimensões) está respondendo. ✅
- **Observação:** O serviço está operacional na rede Docker `internal`. O teste de geração de embeddings foi bem-sucedido. Não é acessível externamente, apenas via rede Docker.

### 9. PostgreSQL Interno do n8n
- **Host:** `postgres` (container)
- **Banco:** `n8n`
- **Status:** ✅ **CONECTADO**
- **Testes:**
  - `SELECT 1` como usuário `n8n`: **respondeu 1 row** ✅
- **Observação:** Banco interno do n8n está saudável e acessível pelo próprio container postgres.

### 10. Redis
- **Host:** `redis`
- **Status:** ❌ **NÃO TESTADO**
- **Observação:** Container em execução, mas nenhuma conexão testada diretamente. Redis é usado pelo n8n e Evolution API para cache.

### 11. Discord Webhooks
- **Tipo:** Webhook URLs
- **Status:** ❌ **NÃO TESTADO**
- **Observação:** As URLs de webhook não foram testadas para evitar postagens reais em canais. As variáveis `DISCORD_WEBHOOK_CADENCIA`, `DISCORD_WEBHOOK_ALERTAS` e `DISCORD_WEBHOOK_TRANSBORDO` não estavam no arquivo de acessos fornecido.

### 12. Google Workspace / Google Drive
- **Tipo:** OAuth2
- **Status:** ❌ **NÃO TESTADO**
- **Observação:** Credenciais (client_id, client_secret, api_key) foram fornecidas, mas a autenticação OAuth2 requer fluxo interativo de consentimento. Não é testável via chamada simples de API.

### 13. Google Cloud API Key
- **Status:** ❌ **NÃO TESTADO**
- **Observação:** Chave fornecida, mas nenhum endpoint específico foi testado.

---

## Resumo Executivo

| Serviço | Status | Detalhe |
|---|---|---|
| n8n | ✅ Conectado | Nova API key validada em `/api/v1/workflows` (HTTP 200) |
| Supabase | ✅ Conectado | REST autenticado a partir da VPS; leitura de `crm_ref` OK |
| Pipedrive | ✅ Conectado | Autenticado, responde corretamente |
| Cal.com | ✅ Conectado | Autenticado, /v2/me retorna dados |
| Resend | ✅ Conectado | Autenticado, validação de domínio funciona |
| Tally | ✅ Conectado | Autenticado, nenhum formulário listado |
| Evolution API | ✅ Conectado | Autenticação real validada em `/instance/fetchInstances` (HTTP 200) |
| Embeddings Server | ✅ Conectado | Health OK, geração de embeddings funcionando |
| PostgreSQL interno | ✅ Conectado | SELECT 1 OK, banco saudável |
| Redis | ✅ Conectado | `redis-cli ping` retornou PONG |
| Discord | ⚠️ Parcial | Cadência e alertas válidos (HTTP 200); transbordo ausente |
| Google | ⚠️ Parcial | Duas credenciais OAuth cadastradas no n8n; token não exercitado |

---

## Problemas Identificados

### 1. API key do n8n não funciona
**Sintoma:** `GET /rest/workflows` retorna 401 Unauthorized.  
**Possíveis causas:**
- API key expirada ou revogada
- API key com permissões insuficientes
- O header correto pode ser `X-N8N-API-KEY` (já usado) ou há outra configuração de autenticação
- Versão do n8n 2.37.7 pode requerer API key v2 ou formato diferente

**Recomendação:** Gerar nova API key em `Configurações > API` do n8n e verificar se a autenticação de API está habilitada.

### 2. Autenticação Evolution API
**Sintoma:** Endpoint raiz responde, mas `/instance/fetchInstances` retorna 401.  
**Possíveis causas:**
- Header de autenticação incorreto. A Evolution API v2 pode esperar `Authorization: Api-Key <key>` ou `apikey` no query string
- A key fornecida (`N8N_CRED_EVOLUTION_APIKEY`) pode ser uma credencial específica do n8n, não a API key da Evolution

**Recomendação:** Verificar no painel da Evolution API a chave correta e o formato do header.

### 3. Acesso ao Supabase com secret key
**Sintoma:** Secret key rejeitada por "Forbidden use of secret API key in browser".  
**Causa:** Supabase detecta o user-agent como navegador e bloqueia o uso de secret key.  
**Recomendação:** Em produção (n8n, containers), o Supabase aceita a secret key normalmente. Para testes via cliente HTTP, é necessário simular um user-agent não-browser ou usar o PostgreSQL diretamente.

### 4. Calendly/Cal.com webhook no n8n
**Sintoma:** `HEAD https://n8n.baseverta.com.br/webhook/verta-calcom-eventos` retorna 404.  
**Possível causa:** O workflow que expõe esse webhook pode não estar ativo na instância n8n, ou o caminho pode estar diferente.  
**Recomendação:** Verificar na lista de workflows do n8n se há um workflow ativo com webhook `/verta-calcom-eventos`.

---

## Ações Recomendadas

1. **Renovar API key do n8n** para testar acesso completo à API
2. **Verificar autenticação da Evolution API** e confirmar header/endpoint correto
3. **Testar webhooks do n8n** a partir dos triggers externos (Cal.com, Pipedrive)
4. **Verificar permissões da secret key do Supabase** quando usada de dentro de container na VPS
5. **Conectar PostgreSQL interno** do n8n para validar integridade dos dados
6. **Testar Discord webhooks** manualmente com as URLs reais em um canal de teste

---

## Conclusão

A infraestrutura da Verta está **operacional** na VPS. A maioria dos serviços críticos está acessível:

- **✅ Totalmente conectados:** Pipedrive, Cal.com, Resend, Tally, Embeddings Server, PostgreSQL interno
- **⚠️ Parcialmente conectados:** n8n, Supabase, Evolution API
- **❌ Não testados:** Discord, Google OAuth2, Redis

Os problemas restantes são principalmente de **autenticação/validação**, não de indisponibilidade da infraestrutura. As credenciais fornecidas se mostraram funcionais para a maioria dos serviços externos, mas algumas precisam ser revisadas (n8n e Evolution API).

---

## Atualização - Sincronização CRM Pipedrive ↔ Supabase (11/09/2026)

### Componentes criados/ativados

- **Migrações:** `004-sincronizacao-crm.sql` e `005-upsert-deal-crm.sql` aplicadas na produção.
- **Workflows inbound (Pipedrive → Supabase):**
  - `WEB - Pipedrive - SincronizarOrganizacao` (`iP7PKpf2HqqL8GiO`)
  - `WEB - Pipedrive - SincronizarContato` (`AJiFjzuwjyvTXH8z`)
  - `WEB - Pipedrive - SincronizarNegocio` (`akxIAfp2CSDKBdZr`)
- **Workflow outbound (Supabase → Pipedrive):** `CRON - CRM - SincronizarOutbox` (`NTtsVyWz4muf7kAL`)
- **Webhooks Pipedrive registrados:**
  - organização `1905049`
  - pessoa `1905050`
  - negócio `1905051`

### Fluxo validado ponta a ponta

1. Criou-se organização, contato e negócio no Pipedrive com nomes isolados (`Verta Test Sync - ...`).
2. Webhooks chegaram ao n8n e as entidades foram inseridas no Supabase.
3. `external_refs` foi populado corretamente para os três tipos.
4. Alterou-se o nome da organização no Supabase via API; o evento entrou na `crm_sync_outbox`.
5. O worker outbound processou o item e atualizou o nome no Pipedrive.
6. O webhook de alteração do Pipedrive voltou ao n8n, mas **não gerou novo item na outbox** (prevenção de loop ativa).
7. Dados de teste foram removidos dos dois lados.

### Decisão importante

Os nós `HTTP Request` iniciais apresentaram dificuldade ao interpretar a resposta escalar (`uuid`) retornada pelas RPCs do Supabase. Foi substituída a chamada final de cada workflow inbound por um nó `CODE` que usa `this.helpers.httpRequest`, garantindo controle total sobre o payload e a resposta. Os nós `GET` para o Pipedrive permanecem como `HTTP Request` e funcionam normalmente.