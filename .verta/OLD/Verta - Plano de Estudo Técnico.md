# Verta — Plano de Estudo Técnico Focado

**Versão:** 1.0  
**Data:** agosto de 2026  
**Objetivo:** Dominar apenas o que é necessário para entregar com qualidade e SLA os módulos da Verta (Atendimento 24/7, Agendamento, CRM, SDR, Renovação, Suporte e One-Page).

Não é um plano para virar especialista genérico. É um plano para conseguir implantar e sustentar a operação real dos clientes.

---

## Escopo do Plano

Foco exclusivo em quatro frentes:

1. **n8n** (orquestração)
2. **WhatsApp Business API Oficial** (Meta)
3. **Prompting com Controle de Escopo** (R4)
4. **Docker + VPS** (infraestrutura)

Tudo o que estiver fora disso será aprendido sob demanda, quando aparecer necessidade real em um projeto.

---

## 1. n8n (Prioridade Máxima)

### O que você precisa dominar de verdade

- Criação de workflows de produção (não só protótipo)
- Webhooks (entrada e saída)
- Tratamento de erro obrigatório (Error Trigger + notificações)
- Sub-workflows e reutilização de lógica
- Variáveis de ambiente e credenciais seguras
- Rate limiting e retry
- Execuções longas e filas básicas
- Logs e debugging eficiente
- Boas práticas de organização (naming, pastas, versionamento simples)

### O que pode deixar para depois

- Cluster / scaling avançado
- Custom nodes complexos
- Integrações exóticas que não aparecem nos módulos atuais

### Como estudar (aplicado)

1. Subir uma instância local ou em VPS de teste.
2. Reconstruir do zero os fluxos principais da Verta:
   - Recebimento de mensagem WhatsApp → decisão de resposta ou handoff
   - Criação/atualização de lead no CRM
   - Criação de evento no Google Calendar + confirmação
   - Fluxo de qualificação (SDR)
3. Forçar quebras de propósito (API fora, timeout, dado inválido) e criar rotas de erro + alerta.
4. Documentar o padrão de workflow que será usado em todos os clientes (template base).

**Critério de “já sei o suficiente”:**  
Consegue montar sozinho um fluxo completo de Atendimento 24/7 + Agendamento + CRM com tratamento de erro e handoff, em menos de 1 dia, usando apenas a documentação e seus templates.

---

## 2. WhatsApp Business API Oficial (Meta)

### O que você precisa dominar de verdade

- Diferença entre WhatsApp Business App e Cloud API
- Janela de 24 horas (service window)
- Categorias de mensagem (Utility, Marketing, Authentication, Service) e seus custos
- Templates (criação, aprovação e uso)
- Webhooks de mensagens recebidas e status
- BSP (Business Solution Provider) — como escolher e configurar
- Políticas de bloqueio e qualidade do número
- Boas práticas para não levar banimento
- Como repassar custos corretamente para o cliente

### O que pode deixar para depois

- Recursos avançados de marketing em escala
- Integrações com Instagram/Messenger (só se aparecer demanda)
- Recursos enterprise da Meta

### Como estudar (aplicado)

1. Criar uma conta de teste na Cloud API (ou via BSP).
2. Configurar webhook apontando para o n8n.
3. Enviar e receber mensagens reais.
4. Criar e submeter 2–3 templates úteis (confirmação de agendamento, follow-up, etc.).
5. Simular os cenários mais comuns de quebra (janela expirada, template rejeitado, número com restrição).
6. Documentar o fluxo padrão de onboarding de número do cliente.

**Critério de “já sei o suficiente”:**  
Consegue colocar um número novo em produção, conectar no n8n, configurar templates básicos e explicar para o cliente exatamente o que será cobrado e por quê.

---

## 3. Prompting com Controle de Escopo (R4)

### O que você precisa dominar de verdade

- System prompt determinístico (limites claros de atuação)
- Regras obrigatórias de handoff para humano
- Como evitar alucinação em preços, políticas e dados do cliente
- Uso de ferramentas (tool calling / function calling) de forma controlada
- Estrutura de prompt para:
  - Atendimento
  - Qualificação (SDR)
  - Agendamento
  - Suporte / renovação
- Técnicas de few-shot com exemplos reais do cliente
- Como versionar e testar prompts

### O que pode deixar para depois

- Técnicas avançadas de RAG complexo
- Fine-tuning
- Agentes multi-step muito elaborados

### Como estudar (aplicado)

1. Criar um prompt base de Atendimento 24/7 com regras rígidas de escopo e handoff.
2. Testar deliberadamente perguntas fora do escopo e verificar se o handoff acontece.
3. Criar variações para SDR e Agendamento.
4. Montar um pequeno banco de casos de teste (perguntas boas, ruins, armadilhas).
5. Definir o padrão de prompt da Verta (template que será adaptado por cliente).

**Critério de “já sei o suficiente”:**  
Consegue escrever um system prompt que:
- Responde bem dentro do escopo
- Recusa ou encaminha corretamente fora do escopo
- Nunca inventa preço ou política
- Tem handoff claro e testável

---

## 4. Docker + VPS

### O que você precisa dominar de verdade

- Subir e manter n8n via Docker Compose
- Configuração básica de domínio + SSL (Cloudflare ou similar)
- Backup e restore da instância
- Atualização segura do n8n
- Isolamento básico por cliente (quando usar instância dedicada)
- Monitoramento simples de uptime e uso de recursos
- Boas práticas de segurança (não rodar como root, secrets, etc.)

### O que pode deixar para depois

- Kubernetes
- CI/CD avançado
- Observabilidade completa (Prometheus, Grafana etc.)
- Alta disponibilidade

### Como estudar (aplicado)

1. Subir uma VPS barata de teste.
2. Instalar Docker + Docker Compose.
3. Subir n8n com volumes persistentes.
4. Configurar domínio e SSL.
5. Fazer backup e restaurar do zero.
6. Simular atualização de versão.
7. Documentar o procedimento padrão de criação de ambiente para novo cliente.

**Critério de “já sei o suficiente”:**  
Consegue subir uma instância nova de n8n pronta para produção (com domínio, SSL, backup e acesso seguro) em menos de 2 horas, seguindo seu próprio checklist.

---

## Ordem Recomendada de Estudo

| Semana | Foco principal | Meta prática |
|--------|----------------|--------------|
| 1      | Docker + VPS + n8n básico | Ambiente de produção funcionando |
| 2      | n8n avançado + Error Handling | Template base de workflow da Verta |
| 3      | WhatsApp Cloud API + Webhooks | Número de teste conectado e operando |
| 4      | Prompting + Controle de Escopo | Prompts padrão de Atendimento e SDR testados |
| 5      | Integração completa | Fluxo real: WhatsApp → IA → CRM → Agenda com handoff e métricas |

A partir da semana 5 você já consegue entregar o núcleo da oferta com segurança.

---

## Regra de Ouro do Plano

Só estude o que reduz risco de entrega ou aumenta velocidade de implantação dos módulos que a Verta já vende.

Tudo que for “interessante” mas não aparecer nos projetos reais fica para depois.

---

**Documento vivo.**  
Atualize conforme forem aparecendo padrões reais nos primeiros clientes.
