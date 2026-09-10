# Verta — Wireframe do Site (Versão 2.0 — Resultado + Engenharia)

**Projeto:** Verta  
**Data de consolidação:** Setembro de 2026  
**Status:** Aprovado para implementação no Webflow  
**Framework de Copy:** BAB + Unique Mechanism + StoryBrand (leve)  
**Objetivo do site:** Converter visitantes em **Agendamentos de Diagnóstico Operacional de 30 minutos**.  
**Público-alvo:** Donos e gestores de PMEs com faturamento entre R$ 30k e R$ 500k/mês.  
**Estilo visual:** Tech Precision Híbrido — 80% Light Mode Clean, 20% Dark Components (motor de IA).

---

## Princípios de Conteúdo (obrigatórios)

1. **Cliente é o herói.** A Verta é o guia técnico.
2. **Before → After → Bridge** em toda a narrativa.
3. **Unique Mechanism:** mostrar *como* a Verta opera diferente (infraestrutura instalada + SLA), não só o que faz.
4. **Resultado primeiro:** toda seção deve deixar claro o que muda na operação do cliente (tempo, custo, conversão, visibilidade).
5. **Diferença explícita:** ter a Verta vs. não ter (ou vs. bot genérico / operação manual).
6. **Zero linguagem de agência de bots.** Manter posicionamento de Engenharia de IA Operacional.

---

## Sumário

1. [Estrutura geral da página](#estrutura-geral-da-página)
2. [Header](#header-fixo-no-topo)
3. [Dobra 1 — Hero Section](#dobra-1--hero-section)
4. [Dobra 2 — Bento Grid](#dobra-2--bento-grid--o-que-muda-na-prática)
5. [Dobra 3 — Método Done-for-You](#dobra-3--o-método-done-for-you-bridge)
6. [Dobra 4 — Quadro Comparativo](#dobra-4--quadro-comparativo-de-performance)
7. [Dobra 5 — Segurança e Governança](#dobra-5--segurança-e-governança)
8. [Dobra 6 — Formulário & Agendamento](#dobra-6--formulário-qualificado--agendamento)
9. [Footer](#footer)
10. [Anotações gerais de implementação](#anotações-gerais-de-implementação-webflow)

---

## Estrutura geral da página

- **Header fixo** (logo + navegação + CTA)
- **6 dobras principais:**
  1. Hero Section (split 50/50) — Before/After + CTA
  2. Bento Grid (4 cards) — Resultados operacionais concretos
  3. Método Done-for-You (3 passos) — A Bridge (como chegamos no After)
  4. Quadro Comparativo (tabela) — Diferença explícita: com Verta vs. sem Verta
  5. Segurança e Governança (3 pilares) — Redução de risco
  6. Formulário Qualificado & Agendamento (fundo escuro) — Oferta de Diagnóstico
- **Footer** (logo, links, indicador de status)

---

## HEADER (fixo no topo)

**Layout:**
- Logo Verta à esquerda
- Navegação central: `Solução | Engenharia | SLA | FAQ`
- CTA à direita: `[Agendar Diagnóstico]` (botão amarelo #EAB308)

**Comportamento:**
- Header fixo ao rolar.
- CTA rola suavemente até a Dobra 6.

**Cores:**
- Fundo: #FFFFFF ou #F8FAFC
- Texto: #0F172A
- CTA: #EAB308 (texto #0F172A)

---

## DOBRA 1 — HERO SECTION

**Layout:** Split 50/50 (canvas #F8FAFC)

### Lado esquerdo (texto + CTAs)

**Elementos:**

1. **Tag (topo, ciano #00D2FF):**  
   `● ENGENHARIA DE IA OPERACIONAL`

2. **Headline (H1, #0F172A):**  
   `Sua operação responde em segundos. Seu CRM se atualiza sozinho.`

3. **Sub-headline (#1E293B):**  
   `A Verta instala e sustenta a infraestrutura de IA que conecta WhatsApp oficial, CRM e sistemas internos.  
   Resultado: zero tempo morto no atendimento, leads qualificados e registros sempre atualizados — com go-live em até 14 dias.`

4. **CTA Primário (botão #EAB308):**  
   `Agendar Diagnóstico Operacional →`

5. **CTA Secundário:**  
   `Falar no WhatsApp`

6. **Micro-proofs (#64748B):**  
   - `Go-live em até 14 dias`  
   - `API Oficial Meta`  
   - `SLA de operação contínua`  
   - `Estimativa de impacto no diagnóstico`

### Lado direito (card dark — motor de IA)

- Fundo **#0B0F17**
- Mockup de chat em tempo real + card de CRM sendo atualizado automaticamente
- Linhas de conexão ciano (#00D2FF): WhatsApp → IA → CRM
- Representa o “motor rodando”, não decoração

**Intenção da dobra (BAB):**  
Mostrar o **After** logo de cara. O visitante deve sentir a diferença operacional em 5 segundos.

---

## DOBRA 2 — BENTO GRID (O que muda na prática)

**Layout:** Canvas #F8FAFC  
**Título (H2):**  
`O que muda quando a Verta opera a sua frente de atendimento e vendas`

**Subtítulo:**  
`Quatro resultados operacionais que eliminam tempo morto e aumentam a capacidade do seu time comercial.`

**Grid:** 2x2

### Card A (Grande — Dark #0B0F17)

**Título:** `Atendimento & Qualificação 24/7`  
**Texto:**  
Todo lead é respondido em segundos, a qualquer hora. A IA qualifica, tira dúvidas e entrega o contato pronto (ou agenda direto). Seu time só entra em conversa que tem potencial real.  

**Resultados:**  
- Resposta em menos de 1 minuto, inclusive madrugada e fim de semana  
- Qualificação automática antes do humano  
- Menos tempo gasto com curiosos, mais tempo fechando  

**Benchmark de referência:**  
Em operações implantadas, observamos aumento significativo na taxa de resposta de leads qualificados.

### Card B (Médio — Light #F1F5F9)

**Título:** `Conectividade real do ecossistema`  
**Texto:**  
Não é mais um app solto. Conectamos WhatsApp API oficial, CRM (HubSpot, Pipedrive, RD Station), agenda e sistemas internos. Tudo sincronizado, sem digitação manual.  

**Lista:**  
- WhatsApp Business API (Meta oficial)  
- CRM: HubSpot, Pipedrive, RD Station  
- Agenda: Google Calendar / Calendly  
- Sistemas internos via API ou webhook

### Card C (Pequeno — Light #F1F5F9)

**Título:** `Tempo de resposta como vantagem competitiva`  
**Texto:**  
Lead quente esfria em minutos. A arquitetura Verta reduz o tempo de resposta de horas (ou dias) para menos de 60 segundos em leads qualificados.  

**Métrica-alvo:**  
De horas → < 60 segundos

### Card D (Médio — Dark #0B0F17)

**Título:** `CRM sempre atualizado, sem esforço`  
**Texto:**  
Cada conversa vira registro. A IA move o lead no funil, preenche campos, adiciona tags e grava o histórico completo. Seu time comercial para de “lembrar de atualizar”.  

**Resultados:**  
- Funil com visibilidade real  
- Zero retrabalho de digitação  
- Decisões baseadas em dados atualizados

---

## DOBRA 3 — O MÉTODO DONE-FOR-YOU (A Bridge)

**Layout:** Canvas #F8FAFC  
**Título:**  
`Como a Verta leva sua operação do estado atual para o estado desejado`

**Subtítulo:**  
`Você não compra um bot. Contrata engenharia + operação contínua. Três etapas. Resultado mensurável.`

### Passo 01 — Diagnóstico & Mapeamento
Entendemos seu funil, gargalos, regras de qualificação e sistemas atuais.  
Definimos onde a IA entra, onde o humano entra e como vamos medir.  

**Entregáveis:**  
- Mapa do processo atual × processo com IA  
- Métricas de acompanhamento  
- Estimativa de impacto e plano de aferição em 60 dias

### Passo 02 — Engenharia & Conexão de APIs
Desenvolvemos a arquitetura, conectamos WhatsApp API, CRM, agenda e ferramentas internas.  
Testamos conversas, falhas e handoff para humano antes de ir ao ar.

### Passo 03 — Go-Live + Sustentação de SLA
Ativação, monitoramento de latência, ajuste fino e gestão de incidentes.  
Mantemos a operação estável e evoluindo conforme o negócio muda.  
Go-live funcional em até 14 dias após aprovação do escopo.

**Intenção:** Esta dobra é a **Bridge** do BAB. Mostra o caminho concreto entre o Before e o After.

---

## DOBRA 4 — QUADRO COMPARATIVO DE PERFORMANCE

**Layout:** Canvas #F1F5F9  
**Título:**  
`Com a Verta vs. sem a Verta`

**Subtítulo:**  
`A diferença operacional real entre manter o modelo atual (manual ou bot genérico) e ter infraestrutura de IA instalada e sustentada.`

**Tabela (2 colunas × 7 linhas):**

| Dimensão              | Sem a Verta (operação tradicional / bot genérico) | Com a Verta (Arquitetura instalada)          |
|-----------------------|---------------------------------------------------|---------------------------------------------|
| Tempo de resposta     | Horas ou dias                                     | < 60 segundos                               |
| Qualificação          | Manual ou inexistente                             | Automática antes do humano                  |
| CRM                   | Desatualizado / depende de disciplina             | Atualizado em tempo real                    |
| Atendimento noturno   | Perdido ou demorado                               | 24/7 com qualificação                       |
| Custo operacional     | Alto (horas humanas + retrabalho)                 | Redução de esforço repetitivo               |
| Velocidade do ciclo   | Lenta                                             | Acelerada (lead → reunião)                  |
| Visibilidade          | Baixa / intuitiva                                 | Funil e métricas claros                     |

**Anotação mobile:** Transformar em cards empilhados (Antes × Depois).

**Intenção:** Esta é a dobra mais importante de **diferença**. O visitante deve sair dela com clareza do custo de não agir.

---

## DOBRA 5 — SEGURANÇA E GOVERNANÇA

**Layout:** Canvas #F8FAFC  
**Título:**  
`Segurança, conformidade e controle desde o primeiro dia`

**Subtítulo:**  
`IA sem governança vira risco. A Verta opera com limites claros, APIs oficiais e handoff obrigatório.`

### Pilar 1 — Conformidade LGPD
Tratamento de dados com regras definidas em conjunto.  
Exclusão automática de dados sensíveis quando não são mais necessários.  
Controle de acesso e auditoria.

### Pilar 2 — APIs Oficiais Meta
Somente WhatsApp Business API oficial.  
Reduz risco de bloqueio e garante estabilidade para escala.

### Pilar 3 — Controle de Alucinação
Regras de escopo determinísticas.  
A IA não inventa fora da base.  
Handoff automático para humano em dúvida ou risco.

---

## DOBRA 6 — FORMULÁRIO QUALIFICADO & AGENDAMENTO

**Layout:** Fundo escuro #0F172A, split 50/50

### Lado esquerdo
**Título:**  
`Diagnóstico Operacional de 30 minutos`

**Subtítulo:**  
`Nesta reunião você não ouve pitch genérico. Mapeamos seu processo atual, identificamos os maiores gargalos e desenhamos na hora como a infraestrutura de IA entra na sua operação — com estimativa de impacto e plano de aferição.`

**O que você leva da reunião:**  
- Mapa rápido do funil e dos gargalos  
- Recomendação clara: onde automatizar, onde manter humano  
- Estimativa de impacto (tempo, leads, custo, conversão)  
- Caminho de implantação (prazo, escopo e investimento) se fizer sentido seguir

### Lado direito
**Formulário (card claro):**  
1. Nome completo  
2. Nome da empresa  
3. WhatsApp  
4. E-mail  
5. Faturamento mensal (select): Até R$ 30k | R$ 30k–100k | R$ 100k–500k+  
6. Maior gargalo operacional hoje (select):  
   - Atendimento lento / fora do horário  
   - Leads que somem depois do primeiro contato  
   - CRM desatualizado  
   - Processo de vendas pouco claro  
   - Outro

**CTA:** `Agendar meu diagnóstico →` (#EAB308)

**Micro-copy:**  
Análise técnica prévia realizada antes da reunião. Retorno em até 24 horas úteis.

**Integração:** Cal.com embutido.

---

## FOOTER

**Layout:** Fundo #0B0F17  
- Logo Verta  
- Links: Termos de Uso | Política de Privacidade | SLA  
- Indicador: `● All Systems Operational` (LED ciano com pulse)

---

## Anotações gerais de implementação (Webflow)

### Tipografia
- Títulos: Inter / Satoshi / General Sans  
- Corpo: Inter / IBM Plex Sans

### Cores principais
| Elemento                    | HEX       |
|----------------------------|-----------|
| Canvas                     | #F8FAFC   |
| Superfície leve            | #F1F5F9   |
| Motor de IA (dark)         | #0B0F17   |
| Títulos                    | #0F172A   |
| Corpo                      | #1E293B   |
| CTA                        | #EAB308   |
| Hover CTA                  | #D97706   |
| Ciano (conectividade)      | #00D2FF   |
| Azul institucional         | #2563EB   |

### Responsividade
- Hero: empilhar em mobile  
- Bento: 1 coluna mobile / 2 colunas tablet  
- Método: vertical em mobile  
- Comparativo: cards empilhados  
- Formulário: empilhar

### Animações
- Fade-in de seções  
- Hover sutil nos cards  
- Pulse no LED do footer

---

**Fim do Wireframe 2.0**  
Fonte da verdade para implementação + copy.
