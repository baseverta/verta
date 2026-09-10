# ARQUITETURA.md — Verta: Sistemas, Dados e Infraestrutura Base

**Status:** Oficial e Ativo
**Versão:** 3.1
**Objetivo:** Fonte da verdade para a engenharia da Verta. Dita as regras de fluxo de dados, modelagem, infraestrutura, continuidade e resolução de problemas estruturais. Todo engenheiro deve seguir estas diretrizes para configurar novos clientes ou realizar manutenções. Qualquer desvio arquitetural deve ser documentado em `DECISOES.md`.

**Documentos revogados:** `Implantação de Infraestrutura Baseverta`, `Módulos Adicionais de Expansão` (parte técnica), `Estrutura Básica - Teste` e demais materiais anteriores a esta versão estão arquivados. Onde houver divergência, este arquivo prevalece.

---

## 1. Fonte da Verdade e Resolução de Conflitos

- **Supabase (a única fonte da verdade):** O PostgreSQL hospedado via Supabase é o núcleo lógico. Nele as automações leem e escrevem dados primários, histórico de conversas, embeddings da base de conhecimento, metadados de sessão e logs de auditoria.
- **CRM (o espelho humano):** Pipedrive (ou HubSpot/RD Station) atua exclusivamente como interface visual para a equipe do cliente. O CRM nunca dita regra para a automação e não é consultado em caminho quente (resposta de WhatsApp em tempo real), para evitar rate limit e latência.
- **Chaves opacas de CRM:** Campos customizados do Pipedrive têm chave hash ilegível (`e39a55...`). Nunca escreva a chave direto no workflow. Mapeie na tabela `pipedrive_config` com nome legível (`ORG_FIELD_CNPJ`).
- **Hierarquia de gravação:** Toda informação capturada é gravada primeiro no Supabase e imediatamente espelhada no CRM. Em divergência, o Supabase prevalece.

## 2. Modelagem de Dados, Entidades e Armazenamento

- **Entidade pai (`organizations`):** Detém todo o histórico comercial, deals, atividades e pastas no Google Drive.
- **Entidade filha (`leads` / `client_contacts`):** Pessoas físicas existem como satélites da organização, ligadas por `organization_id`. Se "João" for desligado e "Maria" assumir, cria-se um novo lead atrelado à mesma organização, preservando histórico e faturamento.
- **Armazenamento de arquivos (Google Drive):** Referência a pasta e arquivo é feita **exclusivamente por ID**, nunca por caminho ou busca de nome. Pastas homônimas e renomeações quebram fluxo baseado em texto.
- **Validação de inputs (UUIDs):** Dado vindo de URL, formulário ou webhook não é confiável. Texto injetado em query que espera `uuid` derruba a execução com erro 500. Valide o formato via regex antes de montar a query.
- **Flags de auditoria (`is_internal`):** Cadastros de teste da própria Verta recebem `is_internal = true` na tabela `leads`. A rotina de auditoria diária ignora a falta de espelhamento no CRM nesses registros, evitando alertas falsos que treinam a equipe a ignorar erro real.
- **Regra de deleção (DROP):** Nunca apague objeto (tabela, view, trigger) sem buscar referências internas antes — `DROP ... CASCADE` exclui dependência silenciosamente. Tabelas filhas podem não ter `ON DELETE CASCADE` (caso de `qualification_sessions`), exigindo deleção manual de baixo para cima.

## 3. Infraestrutura Base e Isolamento de Redes

- **Portabilidade e anti-lock-in:** A retenção é conquistada pelo SLA cumprido. É proibido criar barreira técnica artificial. Em rescisão, a infraestrutura (VPS, fluxos exportados, prompts, dados, backups) é repassada integralmente ao cliente em até 10 dias úteis.

- **Regra canônica de isolamento — modelo único:** Todos os clientes rodam em **isolamento lógico multi-tenant** na infraestrutura da Verta. Cada cliente recebe container próprio do n8n e do PostgreSQL interno; volumes e containers levam prefixo do cliente (`clienteA_n8n`, `clienteA_postgres_data`). O Traefik atua como roteador global na rede externa `proxy`, baseado em `Host`.

  **Critério de migração para VPS dedicada** — obrigatória quando qualquer condição for atingida:
  - mais de 10 clientes ativos na mesma máquina;
  - cliente com volume acima de 3.000 conversas/mês;
  - exigência contratual do cliente por instância isolada;
  - uso sustentado de CPU acima de 70% por 7 dias.

  O custo da VPS dedicada é repassado como item de infraestrutura na proposta.

- **Regra de ouro do Supabase:** O banco de negócio é **sempre** isolado em nível de *Project* — um projeto por cliente, nunca separação apenas por schema. Isso vale nos dois modelos acima, sem exceção.

- **Orquestração (Traefik v2.11):** O Traefik gerencia roteamento de domínio e emissão de SSL (Let's Encrypt). A imagem é fixada estritamente em `v2.11`. Nunca use a tag `:latest` na imagem do n8n — atualização major inesperada quebra produção num simples restart. Fixe a versão e atualize com janela agendada.

- **Separação de tráfego:** Duas redes Docker.
  - `proxy`: rede externa onde o Traefik expõe os serviços (portas 80/443).
  - `internal` (`internal: true`): rede cega, sem saída para a internet. PostgreSQL do n8n e container de IA operam exclusivamente aqui.

- **Vetorização (embeddings) self-hosted:** Para eliminar rate limit de API externa, a stack inclui container com o modelo BGE-M3 rodando localmente, conectado apenas à rede `internal`.

## 4. Continuidade: Backup, Restauração e Custódia de Segredos

Esta seção é pré-requisito de entrada em produção. **Nenhum cliente vai ao ar sem a rotina de backup validada.** Sem ela, a promessa de portabilidade do item 3 é impossível de cumprir e um incidente de disco encerra a operação do cliente permanentemente.

### 4.1 O que é copiado

| Ativo | Método | Frequência |
| --- | --- | --- |
| PostgreSQL interno do n8n | `pg_dump` comprimido, via container sidecar | Diário, 03h |
| Projeto Supabase (dados de negócio) | Backup nativo do Supabase + `pg_dump` próprio | Diário |
| Workflows do n8n | Export JSON via API (`GET /api/v1/workflows`) para repositório Git privado | Diário e a cada deploy |
| Arquivos `.env` e `docker-compose.yml` | Repositório Git privado, com segredos referenciados e não versionados | A cada alteração |
| Prompts e base de conhecimento | Versionados no mesmo repositório do cliente | A cada alteração |

### 4.2 Destino e retenção

- Destino externo obrigatório, fora da VPS: Cloudflare R2 ou Backblaze B2, bucket por cliente, com credencial de escrita restrita.
- Retenção: 7 diários, 4 semanais, 3 mensais.
- Backup local na própria VPS não conta como backup.

### 4.3 Custódia da `N8N_ENCRYPTION_KEY`

**Backup do banco sem a chave de criptografia é inútil** — as credenciais do n8n voltam ilegíveis e a operação precisa ser reconstruída do zero.

- A chave de cada cliente fica em cofre de senhas (Bitwarden ou 1Password), em item nomeado `VERTA / <cliente> / N8N_ENCRYPTION_KEY`.
- Nunca no repositório, nunca em anotação local, nunca no mesmo lugar do backup de dados.
- Cópia de emergência offline (impressa ou em mídia fria) guardada fora do ambiente de trabalho.

### 4.4 Teste de restauração

Backup não testado é suposição. **Uma vez por mês**, restaure o backup mais recente de um cliente em VPS descartável, suba a stack, e valide: n8n abre, credenciais descriptografam, workflow de health check passa. Registre a data e o resultado. Um teste falho é incidente e vai para `DECISOES.md`.

## 5. Governança do Google Cloud Platform (GCP)

Automações com Calendar, Meet e Drive dependem de configuração cirúrgica no GCP.

- **Estrutura de projetos:** Sob a organização Verta (ou a do cliente), cria-se um projeto específico. Permissões e faturamento residem nesse nível.
- **Ativação explícita:** Configurar o escopo OAuth não liga o serviço. Acesse `APIs e Serviços > Biblioteca` e clique em **Ativar** para cada serviço (Workspace Events, Meet, Calendar, Drive).
- **Callback e tokens:** Ao adicionar novo escopo no GCP, reautentique a credencial no n8n ("Sign in with Google") para forçar renovação do token. Sem isso, o cache mantém o escopo antigo.

## 6. Tratamento de Segredos em Code Nodes

O sandbox do Code Node do n8n não acessa credenciais nem tabela de configuração, o que cria a tentação de fixar segredos no código. **Segredo hardcoded no Code Node é proibido** — o arquivo vai para o repositório e um `git push` distraído expõe a credencial do cliente.

Ordem de preferência para validação de assinatura de webhook:

1. **Variável de ambiente.** Declare o segredo no `.env` e habilite o acesso no container (`N8N_BLOCK_ENV_ACCESS_IN_NODE=false`), lendo com `$env.WEBHOOK_SECRET_<ORIGEM>`. É o padrão da Verta.
2. **Header validado no Traefik**, quando o provedor permitir, tirando a validação da camada de aplicação.
3. **Hardcode**, apenas como exceção temporária, e somente com: registro em `DECISOES.md`, `.gitignore` cobrindo o arquivo, e prazo definido para substituição.

O `.gitignore` de todo repositório de cliente inclui obrigatoriamente `.env`, `*.key`, `*.pem` e `acme.json`.

## 7. SOP: Setup de Novo Cliente

Roteiro sequencial para provisionar a infraestrutura base.

1. **Isolamento no Claude Code:** Crie pasta local exclusiva do cliente. Inicie o Claude Code informando as chaves do Supabase por prompt, sem usar conector MCP global.
2. **Repositório:** Crie repositório Git privado do cliente com `.gitignore` da seção 6 já aplicado, **antes** de qualquer arquivo de configuração existir.
3. **DNS e Cloudflare:** Registro tipo `A` apontando o subdomínio do orquestrador para o IP da VPS. Desative a nuvem laranja (proxy) durante a emissão do Let's Encrypt.
4. **VPS e variáveis críticas:** Atualize a máquina e instale Docker. No `.env`, configure `WEBHOOK_URL` e `N8N_EDITOR_BASE_URL` com o domínio real e **sem barra no final** — barra final quebra o roteador Express do n8n. Adicione `NODE_FUNCTION_ALLOW_BUILTIN=crypto` e `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`.
5. **Custódia da chave:** Gere a `N8N_ENCRYPTION_KEY` e registre no cofre (seção 4.3) **antes** do primeiro deploy.
6. **Deploy:** `docker compose up -d`, subindo Traefik, banco interno, n8n e container de embeddings.
7. **Supabase:** Crie o *Project* dedicado e execute os scripts SQL base.
8. **Webhooks assinados:** Ative `rawBody: true` no nó de Webhook e valide a assinatura lendo o segredo por variável de ambiente.
9. **Backup:** Configure a rotina da seção 4 e execute a primeira restauração de teste. **Só depois disso o ambiente é considerado entregue.**
10. **Health check:** Importe e execute o workflow de validação (Supabase, GitHub com `User-Agent`, e auto-API do n8n em `GET /api/v1/workflows`). Todos os nós verdes para aprovação final.

## 8. Base de Conhecimento: Erros, Incidentes e Resoluções

Consulte antes de iniciar debug profundo.

| Componente | Sintoma | Causa raiz | Solução padrão |
| --- | --- | --- | --- |
| **Traefik** | `404 Not Found`, `504 Gateway Timeout`, log `Loop client version 1.24 is too old` | Traefik v3.x não negocia a API do Docker em certos provedores de VPS | Fixar a imagem em `traefik:v2.11` |
| **Traefik / n8n** | `504` com o n8n em duas redes | Ambiguidade de rota: o Traefik não sabe por onde alcançar o container | Fixar labels `.service`, `.loadbalancer.server.port=5678` e `.docker.network=proxy` |
| **n8n (roteador)** | `Cannot GET /` | Barra no final de `WEBHOOK_URL` ou `N8N_EDITOR_BASE_URL` | Remover a barra final |
| **GCP / Auth** | `403 PERMISSION_DENIED` silencioso ao inscrever evento | Escopo OAuth configurado, mas API não habilitada no console | Ativar o serviço na biblioteca de APIs do GCP |
| **Code Nodes** | Cadeia funcional passa a retornar `undefined` após inserir um nó | Uso de `$json` ou `$json.body` — o novo nó sobrescreve a referência | Referenciar pelo nome absoluto: `$('Nome do Node').item.json.body`. O nome do nó é contrato: renomear quebra todas as referências |
| **Webhooks seguros** | Nó seguinte lê `$json.body` e recebe nulo | `rawBody: true` transforma o corpo em binário (`item.binary.data.data`) | Os nós seguintes leem do nó "Validar Assinatura", que já fez o parse |
| **Google Meet** | Card do CRM não move para "Realizado" | O Calendly retorna a URL do Meet com status `processing`, ocultando o ID real | Aguardar 15s e buscar o evento na API do Google Calendar, extraindo o `conferenceId` |
| **Google Drive** | Mover arquivo retorna sucesso e nada acontece | Falha silenciosa da integração nativa do n8n | `HTTP Request` puro com `PATCH`, informando `addParents`, `removeParents` e `supportsAllDrives=true` |
| **Supabase** | Workflow executa, mas ramificações param sem erro | `SELECT` sem resultado encerra a ramificação sem gerar erro; ou chamada com `limit` acima de 250 retorna objeto em vez de array | `UNION ALL SELECT NULL` em buscas críticas para forçar linha vazia e permitir tratamento por `IF`; sempre checar se a resposta traz `data` como array |
| **Cache / CDN** | `curl` responde 200, navegador mostra erro | Proxy, CDN ou navegador guardou a tela de erro | Guia anônima, rede móvel, hard reload ou *Purge Everything* no Cloudflare |
