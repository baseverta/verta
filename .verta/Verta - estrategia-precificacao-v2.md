# Estratégia de Precificação — Verta

**Versão:** 2.0  
**Status:** estratégia inicial de validação  
**Data:** agosto de 2026

## Tese

A Verta vende operação de IA instalada, integrada e sustentada — não licença de chatbot ou ferramenta avulsa. A proposta deve ser personalizada ao processo, à dor e à maturidade operacional do cliente.

Ao mesmo tempo, a Verta está na fase de **validação, caixa e criação de prova**. Por isso, a precificação tem duas rotas:

1. **Oferta de entrada padronizada** para negócios com faturamento mensal de até R$ 15.000: facilita a decisão, reduz esforço comercial e gera casos reais.
2. **Proposta modular personalizada** para negócios acima de R$ 15.000/mês: dimensiona preço pelo escopo selecionado, sem obrigar o cliente a comprar um pacote fechado.

A oferta de entrada pode conscientemente ficar abaixo da regra normal de horas. Isso não é o preço definitivo da Verta; é um investimento deliberado em aprendizado, caixa e prova. Só faz sentido se o escopo for rigidamente padronizado, houver limite de suporte e o resultado puder ser medido.

## Princípios

- O cliente compra redução de trabalho manual, resposta rápida, agenda organizada e funil atualizado — não “um bot”.
- Processo, dados e regras vêm antes de automação. Se a operação estiver caótica, a Verta registra a limitação, reduz o escopo ou inclui uma etapa de Fundação.
- Custos de ferramentas, BSP, API, IA e mensagens são separados/repassados conforme consumo e fornecedor; não devem corroer a mensalidade.
- Escopo novo, integrações fora do padrão e mudanças estruturais são nova proposta, não “manutenção”.
- Todos os primeiros projetos devem ter apontamento de horas, incidentes, suporte e custo de ferramentas. Os valores desta versão são hipóteses até serem recalibrados com entregas reais.
- Nunca prometer resultado financeiro sem dados fornecidos pelo cliente e um método de aferição acordado.

## Rota 1: Oferta de Entrada

### Público

Negócios com faturamento mensal entre **R$ 3.500 e R$ 15.000**. A Verta não recusa esse público na fase inicial, desde que o escopo seja repetível e a operação tenha condição mínima de usar WhatsApp, agenda ou CRM/planilha.

### Objetivo

- Gerar caixa inicial.
- Criar 3 a 5 casos instrumentados.
- Descobrir quais combinações de módulos têm demanda por nicho.
- Criar templates de fluxos, perguntas, handoff e integrações para reduzir o tempo de implantação seguinte.

### Oferta

| Item | Regra |
|---|---:|
| Nome interno | Verta Start |
| Setup | R$ 2.000, preço fixo |
| Operação mensal | R$ 450/mês, preço fixo |
| Escopo | Atendimento 24/7 + dois módulos definidos por nicho |
| Integrações padrão | WhatsApp Business API + CRM/planilha ou agenda; sem sistemas internos customizados |
| Go-live alvo | 5 a 7 dias úteis após acessos, conteúdo e aprovações |
| Suporte incluso | Até 2h/mês |
| Horas adicionais | R$ 150/h, mediante aprovação |
| Prazo comercial recomendado | Compromisso inicial de 6 meses |
| Custos variáveis | Ferramentas, BSP, API, IA e mensagens: pagos/repassados à parte |

### Regra de escopo

O módulo de Atendimento 24/7 é obrigatório. Os outros dois módulos devem ser escolhidos para resolver a dor econômica mais clara do nicho, e não por preferência técnica.

Combinações iniciais possíveis:

| Nicho / contexto | Módulos do Verta Start |
|---|---|
| Clínicas, estética e consultórios | Atendimento 24/7 + Agendamento + CRM |
| Escolas, cursos e serviços consultivos | Atendimento 24/7 + SDR + CRM |
| Imobiliárias e corretores | Atendimento 24/7 + SDR + Agendamento |
| Operações com pós-venda repetitivo | Atendimento 24/7 + Suporte + CRM |

Essas combinações são hipóteses. Elas devem ser confirmadas em conversas e pilotos antes de serem comunicadas como verticais oficiais.

### Limites

A oferta de entrada não inclui: integrações customizadas, ERP, múltiplos canais complexos, migração/limpeza extensa de dados, dashboard avançado, tráfego pago, produção de conteúdo, campanhas de marketing ou mudanças ilimitadas de fluxo.

Se uma dessas necessidades for crítica para o funcionamento, o projeto deixa de ser Verta Start e migra para proposta modular ou etapa de Fundação.

## Rota 2: Proposta Modular

### Público

Negócios com faturamento mensal **acima de R$ 15.000**. A proposta é montada após diagnóstico, com módulos selecionados de acordo com processo, volume, qualidade dos dados, integrações e impacto potencial.

### Fórmula do setup

```text
setup dos módulos = soma(horas dos módulos × R$ 70)
setup recomendado = setup dos módulos × 1,125
```

O fator de 1,125 é um buffer de 12,5% para ajustes previsíveis de implantação. Não há cobrança fixa de “base operacional” nesta versão. Quando o diagnóstico revelar demanda alta, dados ruins, urgência ou integrações não padronizadas, a Verta deve precificar isso como Fundação, módulo adicional ou escopo personalizado — não esconder o esforço no buffer.

**Travas atuais:** mínimo de setup de R$ 1.500 e teto de referência de R$ 10.000. Acima do teto, dividir a implantação em fases ou redesenhar o escopo.

### Serviços modulares

| # | Serviço | Escopo resumido | Horas de referência | Setup-base | Mensalidade |
|---|---|---|---:|---:|---:|
| 1 | Atendimento 24/7 com IA | WhatsApp oficial, respostas inteligentes, triagem e handoff humano | 18h | R$ 1.260 | R$ 360/mês |
| 2 | Agendamento automático | Agenda, confirmação, reagendamento e lembretes | 12h | R$ 840 | R$ 225/mês |
| 3 | Registro e movimentação de CRM | Criação de lead, preenchimento de campos e movimentação de cards | 10h | R$ 700 | R$ 180/mês |
| 4 | Agente SDR (qualificação) | Critérios de fit, qualificação e entrega ao comercial | 10h | R$ 700 | R$ 180/mês |
| 5 | Agente de renovação | Retomada de clientes, renovação e oportunidades de upsell | 10h | R$ 700 | R$ 180/mês |
| 6 | Agente de suporte | Triagem pós-venda, resolução inicial e abertura de tickets | 10h | R$ 700 | R$ 180/mês |
| 7 | One-Page / Hot-Page | Página Webflow para captação com formulário integrado ao CRM | 14h | R$ 980 | R$ 135/mês |

**Exemplo:** Atendimento + Agendamento = R$ 2.100 de setup-base. Com buffer de 12,5%, o setup recomendado é R$ 2.362,50, arredondado comercialmente para R$ 2.363. A mensalidade é R$ 585/mês.

### Operação contínua e suporte

A mensalidade cobre monitoramento, ajustes dentro do escopo, manutenção dos fluxos e suporte. Ela não é receita passiva.

| Módulos contratados | Suporte incluso | Hora extra |
|---:|---:|---:|
| 1–2 | 2h/mês | R$ 150/h |
| 3–4 | 4h/mês | R$ 150/h |
| 5–7 | 6h/mês | R$ 150/h |

**Mensalidade mínima na proposta modular:** R$ 500/mês. A calculadora soma as mensalidades dos módulos e aplica esse piso quando necessário.

### Capacidade de pagamento

A calculadora exibe como referência um teto de mensalidade equivalente a **3% do faturamento mensal**. É um alerta comercial, não uma regra automática: se a mensalidade ultrapassar essa faixa, validar com mais rigor o valor gerado, o caixa do cliente e o escopo.

## Sugestão por faturamento

A sugestão automática serve para iniciar a conversa e aumentar a relevância da proposta. Ela não substitui a descoberta de dor, volume e processo.

| Faturamento mensal | Caminho sugerido |
|---:|---|
| R$ 3.500–15.000 | Verta Start: Atendimento 24/7 + dois módulos por nicho |
| R$ 15.001–100.000 | Atendimento + Agendamento + CRM + SDR, quando a operação tiver leads e agenda |
| R$ 100.001–300.000 | Base anterior + Renovação, se houver carteira/base inativa e processo comercial estabelecido |
| R$ 300.001–500.000 | Base anterior + Suporte, quando pós-venda tiver volume e regras repetíveis |
| Acima de R$ 500.000 | Diagnóstico mais profundo; avaliar jornada integrada, One-Page e implantação por fases |

A recomendação só deve ser aplicada se houver dor correspondente. Por exemplo, não vender Agendamento a uma empresa que não agenda reuniões e não vender Renovação sem base de clientes elegíveis.

## Governança comercial

Antes de apresentar preço, registrar:

- Processo atual e principal gargalo.
- Volume de leads, conversas, agendamentos ou tickets.
- Sistemas existentes e qualidade dos dados.
- Critérios de qualificação, handoff e responsável humano.
- Métrica que será acompanhada: tempo de resposta, leads qualificados, agendamentos, no-show, reativação, tickets ou conversão.
- Custos de tecnologia e mensagens que serão repassados.
- O que ocorre quando a IA falhar ou não tiver informação.

## Auditoria futura

Após os primeiros três projetos, revisar obrigatoriamente:

1. Horas reais por módulo e por integração.
2. Tempo gasto em diagnóstico, testes, treinamento e suporte.
3. Custo efetivo de BSP, IA, hospedagem e mensagens.
4. Número de incidentes e alterações fora de escopo.
5. Churn, tempo de permanência e motivo de cancelamento.
6. Se R$ 2.000 + R$ 450 do Verta Start está gerando caixa, aprendizado e case suficientes para justificar a exceção.

Se a oferta de entrada exigir customização ou suporte recorrente acima do limite, seu preço deve subir, o escopo deve reduzir ou o cliente deve migrar para a proposta modular.
