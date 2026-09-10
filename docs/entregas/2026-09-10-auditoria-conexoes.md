# Relatório de Conexões API - Verta

**Data:** 10/09/2026  
**Objetivo:** Testar conectividade via API/Webhook de todos os ambientes identificados

## Ambientes Identificados

Baseado no `.env.example`, arquivos de configuração e busca recursiva na área de trabalho:

### 1. n8n Automation Engine
- **URL:** `https://n8n.baseverta.com.br`
- **Tipo:** API REST
- **Status:** ✅ **CONECTADO**
- **Detalhes:**
  - Endpoint principal respondeu com HTTP 200
  - Interface web acessível
  - API requer autenticação (retornou 401 Unauthorized ao tentar `/rest/workflows`)
  - Necessário token de API para acesso completo

### 2. Supabase (Project Verta)
- **URL:** `https://vnqsyngphmkgvribtmfa.supabase.co`
- **Tipo:** API REST (PostgREST)
- **Status:** ⚠️ **PARCIALMENTE CONECTADO**
- **Detalhes:**
  - Endpoint base não responde (404)
  - Endpoint `/rest/v1/` responde com 401 Unauthorized
  - Serviço está ativo mas requer autenticação
  - Necessário `SUPABASE_SECRET_KEY` para acesso completo
  - Nota: MCP configurado no `.mcp.json` não tem acesso a este projeto

### 3. Pipedrive CRM
- **URL:** `https://api.pipedrive.com/v1/`
- **Tipo:** API REST
- **Status:** ⚠️ **PARCIALMENTE CONECTADO**
- **Detalhes:**
  - Endpoint `/v1/deals` responde com 401 Unauthorized
  - Serviço está ativo mas requer autenticação
  - Necessário `PIPEDRIVE_API_TOKEN` no header `x-api-token`
  - Webhooks usam Basic Auth (`PIPEDRIVE_WEBHOOK_USER`/`PASS`)

### 4. Evolution API (WhatsApp)
- **URL:** `http://127.0.0.1:8082`
- **Tipo:** API/Webhook (local)
- **Status:** ❌ **NÃO CONECTADO**
- **Detalhes:**
  - Endpoint local não acessível da máquina atual
  - Container provavelmente não está rodando
  - Porta 8082 mapeada para localhost only (`127.0.0.1:8082:8080`)
  - Necessário verificar se Docker Compose está rodando
  - Necessário `EVOLUTION_API_KEY` para autenticação

### 5. Discord Webhooks
- **Tipo:** Webhook URLs
- **Status:** ❌ **NÃO TESTADO**
- **Detalhes:**
  - Requer URLs específicas de webhook configuradas
  - Variáveis necessárias:
    - `DISCORD_WEBHOOK_CADENCIA`
    - `DISCORD_WEBHOOK_ALERTAS`
    - `DISCORD_WEBHOOK_TRANSBORDO`
  - Não é possível testar sem as URLs reais
  - Webhooks são específicos por canal/servidor

### 6. Embeddings Server
- **URL:** Interna (rede Docker `internal`)
- **Tipo:** API REST
- **Status:** ❌ **NÃO CONECTADO**
- **Detalhes:**
  - Container roda na rede Docker `internal` (sem acesso externo)
  - Acessível apenas via `EMBEDDINGS_INTERNAL_URL` dentro da rede
  - Modelo BGE-M3 self-hosted
  - Porta 80 exposta apenas na rede interna
  - Não acessível de fora da VPS

### 7. Outras Integrações (Identificadas mas não testadas)

#### Typeform
- **Status:** ❌ **NÃO TESTADO**
- **Requer:** `TYPEFORM_TOKEN`
- **Notas:** Webhooks assinados mencionados nos documentos

#### Google Workspace
- **Status:** ❌ **NÃO TESTADO**
- **Requer:** `GOOGLE_API_KEY`, OAuth setup
- **Notas:** Calendar, Meet, Drive integrations

#### Calendly
- **Status:** ❌ **NÃO TESTADO**
- **Requer:** `CALENDLY_TOKEN`, `CALENDLY_WEBHOOK_SECRET`
- **Notas:** Padrão para agendamento

#### ReSend (Email)
- **Status:** ❌ **NÃO TESTADO**
- **Requer:** `RESEND_API_KEY`, `RESEND_FROM`

#### PhantomBuster
- **Status:** ❌ **NÃO TESTADO**
- **Requer:** `PHANTOMBUSTER_API_KEY`
- **Notas:** Coleta para lista de prospecção

## Resumo Executivo

| Serviço | Status | Observação |
|---------|--------|------------|
| n8n | ✅ Conectado | Requer autenticação para API |
| Supabase Verta | ⚠️ Parcial | Requer autenticação |
| Pipedrive | ⚠️ Parcial | Requer autenticação |
| Evolution API | ❌ Não conectado | Container não acessível localmente |
| Discord | ❌ Não testado | Requer URLs de webhook |
| Embeddings Server | ❌ Não conectado | Rede Docker interna |
| Outras APIs | ❌ Não testadas | Requer credenciais |

## Arquivos de Ambiente Encontrados

Arquivos acessíveis:
- ✅ `.env.example` - Template com nomes de variáveis (sem valores reais)

Arquivos encontrados mas protegidos por .gitignore (não acessíveis via ferramenta):
- ❌ `.env.supabase` - Credenciais Supabase
- ❌ `.env.n8n` - Credenciais n8n e configurações
- ❌ `.env.typeform` - Token Typeform
- ❌ `.env.tally` - Credenciais Tally
- ❌ `.env.calcom` - Credenciais Cal.com (residual)

Outros arquivos de ambiente encontrados em projetos relacionados:
- `Manekin-ai/dev-manekin-ai/.env`
- `Manekin-ai/dev-manekin-ai/.env.local`
- `verta-conteudo/.env.discord`
- `verta-conteudo/.env.n8n_conteudo`

**Nota:** Os arquivos `.env.*` estão protegidos pelo `.gitignore` (e arquivos similares em outros projetos) conforme ARQUITETURA.md seção 6. As ferramentas de leitura não conseguem acessar esses arquivos devido a restrições de segurança configuradas nos projetos (`.gitignore`, `.codeiumignore`, `.windsurfignore`, `.devinignore`).

**Busca realizada:** Foi executada busca recursiva em toda a área de trabalho (`C:\Users\micha\OneDrive\Área de Trabalho`) conforme solicitado, identificando arquivos de ambiente em projetos relacionados (Manekin-ai, verta-conteudo), mas todos permanecem inacessíveis devido às restrições de segurança.

## Recomendações

1. **Docker Compose Status:** Verificar se os containers estão rodando:
   ```bash
   docker-compose ps
   ```

2. **Evolution API:** Se necessário testar localmente, verificar se o container está rodando e acessível

3. **Credenciais:** Para testes completos de API, seriam necessárias as credenciais dos arquivos `.env` protegidos

4. **Embeddings Server:** Teste direto não é possível fora da rede Docker interna

5. **Discord:** Teste requer URLs específicas de webhook que não estão disponíveis

## Conclusão

Dos serviços principais testados:
- **2 serviços** estão parcialmente conectados (respondem mas requerem autenticação)
- **1 serviço** totalmente conectado (n8n web interface)
- **4 serviços** não conectados/não testados (local, rede interna, ou sem credenciais)

**Nota sobre Supabase Manekin:** Este projeto foi removido dos testes conforme solicitação do usuário e não deve ser utilizado nesta sessão.

A infraestrutura base parece estar operacional, mas testes completos requerem acesso às credenciais armazenadas nos arquivos `.env` protegidos. Foram identificados arquivos de ambiente em projetos relacionados na área de trabalho, mas todos permanecem inacessíveis devido às restrições de segurança configuradas.