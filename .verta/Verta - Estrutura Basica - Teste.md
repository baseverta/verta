**Verta — Consolidação de Aprendizados e Laboratório de Testes (Cliente Zero)**

**O Que Foi Sólidamente Absorvido (A Visão da Verta)**

* **Posicionamento & Diferenciação de Guerra:** A Verta não compete no mercado amador de "chatbots de R$ 99" ou de promessas milagrosas. A empresa vende Engenharia de IA Operacional instalada, integrada e sustentada por contrato de SLA.


* **A Regra da Arrumação da Casa:** A IA não conserta processos caóticos ou bases de dados sujas. Antes da automação, é obrigatório realizar a etapa de Fundação (organização do CRM e padronização do processo comercial).


* **Engenharia Financeira & Margem Protegida:**
* *Rota 1 (Verta Start):* Setup fixo de R$ 2.800 + R$ 690/mês para empresas que faturam de R$ 3.500 a R$ 15.000/mês.


* *Rota 2 (Proposta Modular):* Hora-base de R$ 85/h × 1,20 (buffer de 20%), com setup mínimo de R$ 1.800 e mensalidade fixa a partir de R$ 690/mês para negócios acima de R$ 15.000/mês.


* *Repasse Transparente:* Tokens de IA e mensagens da Meta são cobrados à parte no cartão do cliente, garantindo uma margem líquida entre 75% e 85%[cite: 1, 3, 6].


* **A Stack "Completão":** Orquestração no n8n Self-Hosted (sem custos de licença)[cite: 1, 2], hospedagem VPS Linux na Hostinger[cite: 1, 17], gestão de DNS/SSL no Cloudflare[cite: 1, 2], contêineres Docker com volumes persistentes[cite: 2], WhatsApp Cloud API Oficial[cite: 1], banco PostgreSQL/Supabase[cite: 1, 15], cérebro Claude 3.5 Sonnet/Haiku[cite: 1, 15], CRM Pipedrive/HubSpot[cite: 1, 7], agendamento [Cal.com/Calendly](https://www.google.com/search?q=https%3A%2F%2FCal.com%2FCalendly)[cite: 7, 10] e front-end em Webflow[cite: 1, 6].

---

**Arquitetura da Stack do Teste**

```text
[Visitante / Anúncio] ──► [Site Verta em Webflow]
                                 │
                                 ▼ (Formulário / Webhook)
[WhatsApp Oficial Verta] ──► [Cloudflare (DNS/SSL)]
                                 │
                                 ▼
                    [Hostinger VPS Linux (Ubuntu)]
                                 │
                   [Docker + Docker Compose (v2)]
                                 │
                      [n8n Self-Hosted (Motor)]
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
[Claude Haiku (IA)]    [Supabase / Postgres]    [HubSpot CRM + Cal.com]
(Qualificação JSON)    (Sessão / Janela Meta)   (Card Criado + Agenda)

```

---

**O Plano de Teste Interno: A Verta Como Cliente Zero**

Antes de vender a primeira linha de código para terceiros, a Verta usará a própria operação comercial como campo de prova[cite: 15]. O objetivo é validar o motor n8n, garantir o controle de alucinação e automatizar a captura de agendamentos de Diagnósticos Operacionais de 30 minutos[cite: 7, 15].

**Passo 1: Infraestrutura de Servidor e Segurança**

* Subir a VPS na Hostinger escolhendo a imagem limpa do **Ubuntu 24.04 LTS**[cite: 1, 17].
* Acessar a VPS via SSH, criar o usuário seguro `verta` e instalar o Docker e o Docker Compose[cite: 2].
* Criar o diretório `n8n-verta` e configurar o `docker-compose.yml` garantindo a criação de **volumes persistentes** para impedir a perda de dados em reboots do servidor[cite: 2].
* No Cloudflare, apontar os DNS do domínio `verta.com.br` e criar um registro do tipo "A" para o subdomínio `n8n.verta.com.br` direcionando para o IP da VPS[cite: 1, 2, 14].

**Passo 2: Ativação da Cloud API do WhatsApp e Banco de Dados**

* Criar o app de produção no painel Meta for Developers, configurar o número oficial da Verta e conectar os webhooks de entrada no n8n[cite: 1, 15].
* Submeter os 3 templates obrigatórios na categoria *Utility* (Início de qualificação, envio de link do Diagnóstico e lembrete de reunião)[cite: 15].
* Criar a tabela de sessões (`wa_sessions`) no PostgreSQL/Supabase para controle da janela de 24 horas da Meta e controle da flag de transbordo humano (`human_takeover`)[cite: 15].

**Passo 3: Construção do Workflow de Qualificação (WF-01 no n8n)**

* Configurar a inteligência do fluxo com o **Claude Haiku** retornando extratos estruturados em JSON[cite: 15].
* Implementar a regra comercial de qualificação em no máximo 2 perguntas[cite: 15]:
1. *Faturamento mensal aproximado da operação*[cite: 15].
2. *Principal gargalo operacional no atendimento*[cite: 15].


* Definir o direcionamento autônomo baseado no retorno[cite: 15]:
* *Qualificado (Fit):* Recebe a mensagem automática com o link do Cal.com e tem um card criado na coluna "Diagnóstico Agendado" do HubSpot[cite: 15].
* *Sem Fit / Bot Barato:* Recebe mensagem transparente de desqualificação comercial e o fluxo é encerrado sem insistência[cite: 15].
* *Dúvida / Objeção / Solicitação do Humano:* O bot silencia a comunicação e dispara um alerta imediato via bot do Telegram para a equipe assumir o atendimento[cite: 15].



**Passo 4: Matriz de Testes Finais e Validação**

| Cenário de Teste | Entrada Enviada no WhatsApp | Comportamento Esperado do Sistema |
| --- | --- | --- |
| **Início Simples** | "Olá, gostaria de informações." | Envia mensagem institucional + solicita faturamento e gargalo[cite: 15]. |
| **Qualificação Direta** | "Faturo R$ 25k e perco leads à noite." | Classifica como *Qualified*, cria deal no CRM e envia o link do Cal.com[cite: 15]. |
| **Expectativa de Bot Barato** | "Quero um robô de R$ 99." | Classifica como *No_Fit*, envia desqualificação elegante e fecha a sessão[cite: 15]. |
| **Gatilho de Transbordo** | "Quero falar com um atendente humano." | Seta `human_takeover = true`, envia confirmação e apita alerta no Telegram[cite: 15]. |
| **Envio de Mídia Incompatível** | *Áudio de 30 segundos* | Responde pedindo para o usuário enviar a solicitação em formato de texto[cite: 15]. |

Após validar a execução dessa matriz de testes sem falhas na própria conta, o checklist de infraestrutura estará pronto para ser replicado na implantação dos primeiros clientes pagantes[cite: 2, 15].