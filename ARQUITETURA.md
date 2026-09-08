# ARQUITETURA.md — Verta: Sistemas, Dados e Infraestrutura Base

**Status:** Oficial e Ativo

**Objetivo:** Atuar como o manual definitivo e a fonte da verdade para a engenharia da Verta. Este documento dita as regras de fluxo de dados, modelagem, infraestrutura e resolução de problemas estruturais. Todo engenheiro ou programador da Verta deve seguir estas diretrizes para configurar novos clientes ou realizar manutenções. Qualquer desvio arquitetural deve ser documentado em `DECISOES.md`.

## 1. Fonte da Verdade e Resolução de Conflitos

A arquitetura da Verta blinda o motor de automação contra as limitações e latências de sistemas terceiros.

- **Supabase (a única fonte da verdade):** o banco de dados relacional (PostgreSQL) hospedado via Supabase é o núcleo lógico do sistema. É nele que as automações leem e escrevem os dados primários, armazenam histórico de conversas, embeddings da base de conhecimento, metadados de sessões e logs de auditoria.
- **CRM (o espelho humano):** o Pipedrive (ou HubSpot/RD Station) atua exclusivamente como uma interface visual para a equipe do cliente. O CRM nunca dita a regra para a automação e não é consultado em caminhos quentes (como respostas de WhatsApp em tempo real) para evitar gargalos de rate limit e latência.
- **Chaves opacas de CRM:** em sistemas como o Pipedrive, campos customizados possuem chaves hash ilegíveis (ex.: `e39a55...`). Nunca escreva essas chaves diretamente nos workflows do n8n. Elas devem ser mapeadas na tabela de configuração (`pipedrive_config`) com nomes legíveis (ex.: `ORG_FIELD_CNPJ`).
- **Hierarquia de gravação:** toda informação capturada (via WhatsApp, Typeform ou webhook) é gravada primeiramente no Supabase. Imediatamente após, o sistema espelha o dado atualizado no CRM. Em caso de divergência entre sistemas, o dado contido no Supabase prevalece.

## 2. Modelagem de Dados, Entidades e Armazenamento

A modelagem segue regras estritas de hierarquia para prevenir fragmentação de histórico e falhas em cascata.

- **A entidade pai (`organizations`):** a tabela de organizações detém a posse de todo o histórico comercial, deals no funil, atividades e as pastas de armazenamento no Google Drive.
- **A entidade filha (`leads` / `client_contacts`):** as pessoas físicas (contatos) existem apenas como satélites da organização, vinculadas pela chave estrangeira `organization_id`. Se o contato "João" for desligado e "Maria" assumir a conta, um novo lead é criado e atrelado à mesma organização, mantendo o histórico de integrações e faturamento intacto.
- **Armazenamento de arquivos (Google Drive):** a referência a pastas e arquivos é feita exclusivamente por ID, nunca por caminho ou busca de nome (ex.: `name = 'Clientes'`). Pastas com nomes idênticos ou renomeações acidentais quebram fluxos baseados em texto.
- **Validação de inputs (UUIDs):** dados vindos de URLs, formulários ou webhooks não são confiáveis. Textos injetados diretamente em queries esperando formato `uuid` derrubam a execução com erro 500. Valide o formato via regex antes de montar qualquer query.
- **Flags de auditoria (`is_internal`):** cadastros de teste da própria Verta devem possuir a flag `is_internal = true` na tabela `leads`. Isso instrui a rotina de auditoria diária a ignorar a falta de espelhamento no CRM, evitando alertas falsos que treinam a equipe a ignorar erros reais.
- **Regra de deleção (`DROP`):** nunca apague objetos (tabelas, views, triggers) sem buscar referências internas no Supabase antes, pois o `DROP ... CASCADE` pode excluir dependências silenciosamente. Além disso, tabelas filhas podem não ter `ON DELETE CASCADE` (como `qualification_sessions`), exigindo deleção manual de baixo para cima para evitar quebras.

## 3. Infraestrutura Base e Isolamento de Redes (Fase 2.1)

O alicerce tecnológico é idêntico para todos os clientes, garantindo estabilidade e permitindo que módulos específicos sejam acoplados sem refatoração.

- **Portabilidade e anti-lock-in:** a retenção do cliente é conquistada pelo SLA. É terminantemente proibido criar barreiras técnicas artificiais. Em caso de rescisão, a infraestrutura (VPS, fluxos exportados, prompts, dados) é integralmente repassada ao cliente.
- **Isolamento multi-tenant:** em servidores compartilhados da Verta, o isolamento lógico é inegociável. Cada cliente recebe um container próprio do motor n8n e do banco PostgreSQL interno. Volumes e containers recebem o prefixo do cliente (ex.: `clienteA_n8n`).
- **Orquestração e redes (Traefik v2.11):** o Traefik gerencia o roteamento de domínios e a emissão automática de SSL (Let's Encrypt). A imagem deve ser estritamente fixada na versão `v2.11`. Evite a tag `:latest` para a imagem do n8n; atualizações major inesperadas quebram instâncias em produção no momento de um simples restart.
- **Separação de tráfego:** a infraestrutura utiliza duas redes Docker:
  - `proxy` — rede externa onde o Traefik expõe os serviços seguros (portas 80/443).
  - `internal` (`internal: true`) — rede cega sem saída para a internet. O PostgreSQL do n8n e o container de IA operam exclusivamente aqui.
- **Vetorização (embeddings) self-hosted:** para eliminar a dependência e os gargalos de rate limit de APIs externas (como Voyage AI), a stack inclui um container rodando o modelo BGE-M3 localmente na VPS, conectado apenas na rede `internal`.

## 4. Governança do Google Cloud Platform (GCP)

Automações que envolvem Calendar, Meet e Drive dependem de uma configuração cirúrgica no painel do GCP.

- **Estrutura de projetos:** sob a Organização Verta (ou a do cliente), cria-se um Projeto específico. Todas as permissões e o faturamento residem neste nível.
- **Ativação explícita:** configurar o escopo OAuth não liga o serviço. O engenheiro deve acessar **API e Serviços > Biblioteca** e clicar manualmente em **Ativar** para cada serviço (Workspace Events, Meet, Calendar, Drive).
- **Callback e tokens:** se um novo escopo for adicionado posteriormente no GCP, o programador deve reautenticar a credencial no n8n ("Sign in with Google") para forçar a renovação do token — caso contrário, o cache manterá o escopo antigo.

## 5. SOP: Passo a Passo do Setup de Novo Cliente

Execute este roteiro sequencialmente para provisionar a infraestrutura base de um novo contrato.

1. **Isolamento no Claude Code (vibe code):** crie uma pasta local exclusiva para o cliente no seu terminal. Inicie o Claude Code informando as chaves de API do Supabase via prompt, sem utilizar o conector MCP global.
2. **DNS e Cloudflare:** crie um registro tipo A apontando o subdomínio do orquestrador para o IP da VPS. Desative a nuvem laranja (proxy do Cloudflare) durante a emissão do certificado Let's Encrypt.
3. **Configuração da VPS e variáveis críticas:** atualize a máquina e instale o Docker. No arquivo `.env`, certifique-se de configurar `WEBHOOK_URL` e `N8N_EDITOR_BASE_URL` exatamente com o domínio real (sem barras no final, que quebram o roteador do n8n). Para permitir a validação de webhooks assinados, adicione `NODE_FUNCTION_ALLOW_BUILTIN=crypto` no arquivo.
4. **Deploy da infraestrutura:** execute `docker compose up -d`. O arquivo garante a subida do Traefik, do banco interno, do n8n e do container de Embeddings.
5. **Setup do banco de negócio (Supabase):** crie o Project na conta do cliente (ou da Verta). Execute os scripts SQL base para erguer as tabelas principais.
6. **Webhook e validação (Code Node):** webhooks públicos devem verificar a assinatura do payload. Para ler a assinatura, ative a opção `rawBody: true` no nó do Webhook. O segredo criptográfico deve ficar fixo (hardcoded) diretamente no Code Node de validação, já que o sandbox não consegue ler credenciais do n8n ou da tabela de configuração.

## 6. Base de Conhecimento: Erros, Incidentes e Resoluções

Antes de iniciar um debug profundo, consulte este log de incidentes validados na operação de campo.

| Componente | Sintoma ou Erro | Causa Raiz | Solução Padrão |
|---|---|---|---|
| Traefik Proxy | `404 Not Found` / `504 Gateway Timeout`, ou logs indicando `client version 1.24 is too old` | A versão v3.x do Traefik não consegue negociar a API do Docker em determinados provedores de VPS | Realize o downgrade da imagem fixando em `traefik:v2.11` |
| GCP / Auth | Retorno silencioso de `403 PERMISSION_DENIED` ao tentar inscrever evento via webhook | O escopo OAuth foi configurado, mas a API do serviço não foi habilitada no console do Google | Acesse a biblioteca de APIs do GCP, pesquise o serviço específico e clique em **Ativar** |
| Motor n8n (Code Nodes) | Uma cadeia de workflows funcional passa a retornar `undefined` silenciosamente após a inserção de um novo nó | O código utilizava a variável implícita `$json` ou `$json.body` para capturar dados. Inserir um novo nó sobrescreve a referência | Remova variáveis implícitas. Referencie pelo nome absoluto: `$('Nome do Node').item.json.body`. Cuidado extra: o nome do nó funciona como um contrato — renomeá-lo quebra todas as referências subsequentes |
| Webhooks Seguros | Nó seguinte ao webhook tenta ler a variável `$json.body` e recebe nulo ou processa objeto vazio | Habilitar `rawBody: true` para validar assinaturas transforma o corpo recebido em um binário de dados (`item.binary.data.data`) | Os nós subsequentes não devem mais ler os dados diretamente do nó do Webhook, mas sim do nó "Validar Assinatura" que já realizou o parse da estrutura |
| Integração Google Meet | O sistema não move o card do CRM para "Realizado" pois não consegue validar a reunião pelo Calendly | O Calendly retorna a URL do Meet com status `processing` no agendamento, ocultando o ID real da sala | Configure o n8n para aguardar 15s e buscar o evento no Google Calendar (extraindo o `conferenceId`). Inscreva esse ID no Pub/Sub da Workspace Events API |
| Google Drive | O nó de Mover Arquivo/Pasta executa, retorna sucesso, mas o arquivo permanece no mesmo local | Falha silenciosa da integração nativa do n8n com a API do Drive | Utilize um nó HTTP Request puro aplicando `PATCH`, informando os parâmetros `addParents`, `removeParents` (exige buscar o pai atual antes) e `supportsAllDrives=true` |
| Supabase (API/n8n) | O workflow executa normalmente, mas galhos param silenciosamente (sem erro do nó PostgreSQL) | Buscas (`SELECT`) sem resultados não geram erro no n8n; elas encerram a ramificação. Ou uma chamada com `limit` excedeu 250 itens e retornou um objeto de mensagem em vez de um array | Aplique `UNION ALL SELECT NULL` em buscas críticas para forçar uma linha vazia, permitindo que um node IF trate a ausência. Sempre cheque se a resposta possui a propriedade `data` no formato array |
