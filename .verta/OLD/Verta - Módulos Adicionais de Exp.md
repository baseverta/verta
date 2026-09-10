# Verta — Módulos Adicionais de Expansão e Backoffice

## 1. Módulos Adicionais de Expansão

Além do catálogo básico de 7 módulos (Atendimento 24/7, Agendamento, Sincronização de CRM, Agente SDR, Agente de Renovação, Agente de Suporte e One-Page), a Verta oferece soluções sob medida para demandas específicas de backoffice, inteligência de tráfego e microsaas:

* **Automação de Gateways de Pagamento (Asaas, Mercado Pago, Stripe, Pagar.me):** Captura o webhook de eventos de pagamento (`payment_approved`). Promove a alteração automática da etapa do lead no CRM para "Ganho", aciona mensagens instantâneas de confirmação e onboarding pelo WhatsApp API e envia notificações internas para a equipe.


* **Inteligência de Anúncios e Tráfego Pago (Meta Conversion API - CAPI / AEO):** Conecta os eventos de conversão de fundo de funil (ex: lead qualificado por SDR ou venda concluída) de volta para o Gerenciador de Anúncios da Meta. Permite otimizar campanhas por conversões reais e reduz o Custo de Aquisição de Clientes (CAC) sem depender de cookies de navegador.


* **MicroSaaS, Portais Customizados e Leitura de Documentos:** Desenvolvimento de pequenos ecossistemas compostos por banco de dados no Supabase, interfaces no Webflow/Retool e orquestração no n8n. Inclui portais para equipes de campo e leitura inteligente via IA de arquivos em PDF (Notas Fiscais, comprovantes e contratos) para registro automatizado em sistemas do cliente.



---

## 2. Precificação e Modelos Financeiros

Para proteger a margem e evitar o descontrole de escopo, qualquer funcionalidade que vá além do núcleo é comercializada como Módulo de Expansão.

| Módulo de Expansão | Setup Adicional | Adicional na Mensalidade (SLA) | Justificativa Comercial |
| --- | --- | --- | --- |
| **Gateways de Pagamento** | R$ 1.500 – R$ 3.000

 | R$ 150 – R$ 300 / mês

 | Exige testes em ambiente de sandbox, tratamento de webhooks financeiros e regras de cobrança/inadimplência.

 |
| **Meta Conversion API / AEO** | R$ 2.000 – R$ 4.000

 | R$ 200 – R$ 400 / mês

 | Entrega otimização direta no orçamento de anúncios do cliente, aumentando a taxa de conversão.

 |
| **MicroSaaS / Portais e PDFs** | R$ 4.000 – R$ 10.000+

 | Reajuste proporcional de SLA

 | Trata-se de desenvolvimento de software e banco de dados sob medida para a operação.

 |

### Ancoragem de Preço da Operação Base

* **Rota 1 (Verta Start):** Setup fixo de **R$ 2.800** + **R$ 690 / mês** (atende empresas com faturamento de R$ 3.500 a R$ 15.000/mês).


* **Rota 2 (Proposta Modular):** Hora-base de **R$ 85/h** × 1,20 (buffer de 20%). Setup mínimo de **R$ 1.800**, teto de referência de **R$ 12.000** e mensalidade mínima de **R$ 690 / mês**.



---

## 3. Viabilidade Técnica e Arquitetura

A execução técnica dessas soluções utiliza uma infraestrutura leve e com custo reduzido de licenciamento.

```text
[Cliente / Anúncios / PDF]
          │ (Webhook / Upload)
          ▼
   [Cloudflare - DNS / SSL Gratis]
          │
          ▼
   [Hostinger VPS Linux (Docker)]
          │
          ├─► [n8n Self-Hosted (Orquestrador)]
          │        │
          │        ├─► [Claude 3.5 Sonnet / Haiku (Processamento / IA)]
          │        ├─► [Supabase / PostgreSQL (Sessões / Dados)]
          │        ├─► [Meta Cloud API (WhatsApp Oficial)]
          │        └─► [CRM: Pipedrive / HubSpot / Gateways]

```

* **Hospedagem e Servidor:** VPS Linux (Ubuntu 22.04/24.04 LTS) gerenciada via Docker e Docker Compose com volumes persistentes para impedir perda de dados em atualizações.


* **Segurança e DNS:** Gerenciamento gratuito no Cloudflare para roteamento de subdomínios (ex: `n8n.verta.com.br`) e fornecimento de certificado SSL (HTTPS) obrigatório para o recebimento de webhooks.


* **Orquestração:** n8n versão Community (Self-Hosted), sem limitação de execuções mensais.


* **Modelos de Inteligência Artificial:** Claude Haiku focado em triagens e extrações em JSON de baixo custo; Claude 3.5 Sonnet voltado para tratativas de alto contexto e conversas complexas.


* **Banco de Dados:** Supabase ou PostgreSQL nativo para persistência de estado das conversas, controle da janela de 24 horas da Meta e gestão de sessões.



---

## 4. Estrutura de Custos e Margem Operacional

A Verta trabalha com separação entre custos operacionais da agência e custos variáveis de consumo.

```
+-----------------------------------------------------------------------+
| Faturamento Mensal de Sustentação (SLA) da Verta                       |
+-----------------------------------------------------------------------+
  │
  ├─► [Custo Fixo Central Operacional]: ~R$ 53,00 a R$ 270,00 / mês
  │   (VPS Hostinger R$ 52,99 + n8n Grátis + Cloudflare Grátis + Supabase Grátis)
  │
  └─► [Custos Variáveis Repassados ao Cliente Integras]:
      ├─► Tokens de IA (Claude / GPT): R$ 30,00 – R$ 300,00 / mês
      └─► API WhatsApp Meta: Utility (~R$ 0,04) / Marketing (~R$ 0,31)

```

* **Custos Fixos Centrais:** A hospedagem VPS na Hostinger custa a partir de R$ 52,99 / mês e consegue absorver a infraestrutura central e até 10 clientes em instância compartilhada no início.


* **Repasse Transparente:** Os insumos de uso contínuo (tokens da IA e custos de envio da Meta) são cadastrados no cartão do cliente ou repassados de forma direta.


* **Margem Bruta:** A separação rigorosa dos custos variáveis garante uma margem bruta operacional mantida entre **75% e 85%**.



---

## 5. Matriz de Objeções e Respostas de Autoridade

### "Achei uma ferramenta que faz isso por R$ 99 / R$ 300 por mês."

> "Existem ferramentas baratas no mercado, mas com elas você mesmo precisa configurar e manter o sistema. A Verta entrega uma operação instalada, integrada ao seu processo e sustentada com SLA de funcionamento. A maioria dessas ferramentas de R$ 99 fica abandonada em 60 dias porque ninguém cuida da manutenção, das atualizações da Meta e do transbordo para atendentes humanos. Você está comparando uma licença de software com uma equipe de engenharia responsável pela sua operação."
> 
> 

### "Por que preciso pagar esses módulos adicionais por fora?"

> "O nosso plano principal cobre a estruturação completa do seu atendimento, qualificação e sincronização de CRM. Módulos de gateways ou otimização de anúncios exigem ambientes de teste específicos e integrações extras. Cobrar esses módulos à parte nos permite manter o seu setup inicial acessível, focando primeiro no que resolve o seu gargalo mais urgente."
> 
> 

### "Já tentei automação antes e não funcionou na minha empresa."

> "Projetos de automação costumam falhar por dois motivos principais: tentar automatizar um processo caótico sem arrumar a casa antes, e a ausência de alguém sustentando a infraestrutura depois que ela vai ao ar. Na Verta, nós organizamos a sua base antes da implementação e assumimos a operação contínua por contrato."
> 
> 

---

## 6. Gatilhos de Venda e Conversão

* **Nomeação da Dor (Tempo Morto e Latência):** Apontar a perda real de receita provocada por leads que chegam fora do horário comercial ou que esfriam por demora no primeiro atendimento.


* **Seleção e Filtro Ativo:** Explicar ao cliente potencial que a Verta não atende curiosos e só aceita empresas com gargalo operacional e volume de atendimento validados.


* **Diferenciação por Engenharia:** Evitar termos genéricos como "bot de IA" ou "aumento de vendas", mantendo o foco em infraestrutura instalada, integrações de APIs e controle de alucinação.


* **Transparência Radical nos Custos:** Apresentar a separação dos custos de tokens e mensagens como um compromisso de não cobrar margens ou pedágios velados sobre os insumos de tecnologia.



---

## 7. Posicionamento Estratégico da Verta

```text
       [ Agência de Chatbot Genérica ]             VS             [ Verta — Engenharia de IA ]
   ---------------------------------------                   ------------------------------------
   • Vende ferramentas soltas / "bots 24/7"                  • Instala e sustenta operação conectada
   • O cliente precisa configurar e manter                   • Entrega no modelo Done-for-You com SLA
   • Foco em promessas ilimitadas sem base                   • Mapeia gargalos, organiza dados e CRM
   • Risco de bloqueios (APIs não-oficiais)                  • Opera exclusivamente com APIs Oficiais Meta
   • Tenta reter o cliente por aprisionamento                • Portabilidade total de dados e código

```

* **Tese Verbal de Marca:** *"A maioria das empresas oferece apenas um bot. A Verta instala e sustenta a operação que conecta o seu WhatsApp Oficial ao seu CRM e à sua agenda, acabando com a perda de leads por demora no atendimento."*

* **Método Nomeado em 4 Fases:** Diagnóstico Operacional → Fundação (Arrumação da Casa) → Ativação da Arquitetura → Operação Contínua (SLA).


* **Garantia de Portabilidade (Anti-Lock-In):** A retenção de clientes é conquistada pela qualidade do SLA cumprido e pela entrega de resultados mensuráveis, sem criar barreiras técnicas artificiais para a saída do cliente. Caso o contrato seja encerrado, a Verta realiza a transferência integral dos acessos, documentações, prompts e cópias de segurança da infraestrutura.