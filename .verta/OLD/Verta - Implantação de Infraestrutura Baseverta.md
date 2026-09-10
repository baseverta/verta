Markdown
# SOP (Standard Operating Procedure): Implantação de Infraestrutura Baseverta

Este documento atua como o manual operacional definitivo para o provisionamento da infraestrutura padrão de novos clientes. Ele detalha a sequência exata de execução, desde a compra do servidor até o deploy automatizado, além de documentar o histórico de resolução de problemas.

## 1. Visão Geral e Estratégia de Arquitetura

A stack base de todo novo cliente é projetada para escalabilidade, segurança e desenvolvimento orientado a IA.

**Componentes Principais:**
*   **Orquestração:** Docker & Docker Compose em VPS.
*   **Proxy Reverso & SSL:** Traefik v2.11 (Obrigatório para estabilidade da API do Docker em certas VPS).
*   **Motor de Automação:** n8n (Self-hosted).
*   **Bancos de Dados:** PostgreSQL (interno, exclusivo do n8n) e Supabase (externo, para dados de negócio via API REST).
*   **Engenharia de IA:** Claude Code (CLI) integrado para programação de fluxos JSON direto via SSH/Git.

**Estratégia de Isolamento de Ambientes:**
Para garantir segurança e conformidade, a infraestrutura adota protocolos rígidos de separação:
*   **Isolamento Físico (Recomendado):** Uma VPS exclusiva e um projeto Supabase dedicado por cliente. O `docker-compose.yml` base deste documento é feito para este modelo, onde o Traefik gerencia as portas 80/443 de forma dedicada.
*   **Isolamento Lógico (Multi-Tenant):** Vários clientes dividem a mesma VPS. Exige a remoção do Traefik dos arquivos individuais e a criação de uma rede externa `web_proxy` com o Traefik atuando como roteador global baseado em domínios (`Host`).
*   **Regra de Ouro do Supabase:** Independentemente do modelo de orquestração, o banco de dados de negócio (Supabase) deve ser **sempre** isolado em nível de Projeto (um *Project* por cliente), nunca apenas por schemas.

## 2. Preparação da VPS e Acesso SSH

A base física da automação requer um ambiente Linux limpo e acesso administrativo total.

**Ferramentas e Terminais Recomendados:**
*   **Windows:** Windows Terminal, PowerShell ou Termius (interface visual).
*   **macOS/Linux:** Terminal nativo ou iTerm2.

**Passo a Passo de Setup do Servidor:**
1.  **Contratação (Hostinger ou similar):** Adquira um plano de VPS KVM. Escolha o Sistema Operacional **Ubuntu 22.04 LTS ou 24.04 LTS** (versões server, sem interface gráfica).
2.  **Configuração de DNS:** No painel de registro do seu domínio, aponte um registro tipo `A` (ex: `n8n.cliente.com.br`) para o endereço IP público fornecido pela VPS. Desative o proxy do Cloudflare (nuvem cinza) durante a instalação inicial do SSL.
3.  **Acesso Root via SSH:** Abra seu terminal local e conecte-se ao servidor utilizando a senha root definida no painel da hospedagem:
    ```bash
    ssh root@<IP_DA_VPS>
    ```
4.  **Atualização Básica e Instalação do Docker:** No terminal da VPS, atualize os pacotes do Ubuntu e instale o Docker:
    ```bash
    apt update && apt upgrade -y
    curl -fsSL [https://get.docker.com](https://get.docker.com) -o get-docker.sh
    sh get-docker.sh
    ```

## 3. Implantação da Stack (Docker, n8n, Traefik, Supabase)

Com o servidor pronto e o Docker rodando, iniciamos o provisionamento da infraestrutura do cliente conectado ao ecossistema de desenvolvimento (Git e Claude Code).

**3.1. Preparação do Repositório**
Clone a base de infraestrutura e crie o arquivo de ambiente.
```bash
git clone [https://github.com/baseverta/verta.git](https://github.com/baseverta/verta.git) /root/verta
cd /root/verta
nano .env
Preencha o .env com as variáveis do cliente:

Snippet de código
N8N_HOST=n8n.cliente.com.br
SSL_EMAIL=conta@baseverta.com.br
POSTGRES_USER=n8n_db_user
POSTGRES_PASSWORD=senha_segura
POSTGRES_DB=n8n_db
N8N_ENCRYPTION_KEY=chave_aleatoria_segura
3.2. Configuração do Orquestrador (docker-compose.yml)
Crie o arquivo docker-compose.yml utilizando o modelo abaixo, que já contém todas as correções de versão de API e roteamento de redes.

YAML
networks:
  proxy:
    name: proxy
  internal:
    name: internal
    internal: true

volumes:
  postgres_data:
    name: ${CLIENTE}_postgres_data
  n8n_data:
    name: ${CLIENTE}_n8n_data
  traefik_certs:
    name: ${CLIENTE}_traefik_certs

services:
  traefik:
    image: traefik:v2.11 # Mandatório para estabilidade em VPS
    container_name: traefik
    restart: unless-stopped
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencrypt.acme.email=${SSL_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--api.dashboard=false"
      - "--log.level=WARN"
    ports:
      - "80:80"
      - "443:443"
    networks:
      - proxy
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - traefik_certs:/letsencrypt

  postgres:
    image: postgres:16-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    environment:
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${N8N_HOST}
      - N8N_EDITOR_BASE_URL=https://${N8N_HOST}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - proxy
      - internal
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(`${N8N_HOST}`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls.certresolver=letsencrypt"
      - "traefik.http.routers.n8n.service=n8n-service"
      - "traefik.http.services.n8n-service.loadbalancer.server.port=5678"
      - "traefik.docker.network=proxy"
3.3. Deploy e Integração de IA
Suba a infraestrutura executando:

Bash
docker compose up -d
Após o deploy, o Claude Code pode ser conectado via SSH e repositório Git. Para criar automações, o Claude deve ser instruído a gerar o fluxo estruturado em JSON e injetá-lo no n8n. Comunicações com a API do GitHub pelo n8n ou Claude exigem o parâmetro User-Agent no Header.

4. Validação e Resolução de Problemas (Troubleshooting)
Protocolo de Validação (Health Check):
Antes de entregar o ambiente, importe e execute o workflow de Health Check (nó Start com 3 ramificações paralelas):

Supabase: GET REST com chave de API via Header genérico.

GitHub: GET no repositório validando a resposta com User-Agent.

n8n Auto-API: GET /api/v1/workflows autenticado com a própria chave de API do n8n (valida a malha interna).
Todos os nós devem exibir status verde para aprovação final.

Histórico de Incidentes e Correções:

Erro: Traefik Loop client version 1.24 is too old (404 Not Found):

Causa: O Traefik v3.x falha ao negociar a versão da API com o daemon Docker em certas hospedagens. Ele ignora a configuração da versão e cai para o padrão antigo, perdendo comunicação com os contêineres.

Solução: Manter estritamente a imagem traefik:v2.11 no orquestrador.

Erro: Falha de Roteamento n8n (504 Gateway Timeout ou Cannot GET /):

Causa (504): Ambiguidade de rede. Como o n8n está em redes proxy e internal, o Traefik não sabe por onde rotear. Solução: Fixar as labels .service, .loadbalancer.server.port=5678 e .docker.network=proxy.

Causa (Cannot GET /): Barras (/) no final das variáveis WEBHOOK_URL e N8N_EDITOR_BASE_URL quebram o roteador interno do n8n (Express.js). Remova qualquer barra final.

Erro: Retenção de Cache (Falso Positivo de 404):

Sintoma: Terminal local (curl) responde 200 OK, mas o navegador mostra erro.

Solução: O proxy/CDN (como Cloudflare) ou o navegador salvou a tela de erro. Teste em Guia Anônima, use a rede 4G, faça Hard Reload ou acione o Purge Everything no Cloudflare.