# COMERCIAL.md

### Verta — Engenharia Comercial, Aquisição e Precificação

**Versão:** 4.1 (ICP em três faixas, regra de Origem do Lead, campos alinhados ao Pipedrive)
**Status:** Oficial e Ativo
**Objetivo:** Consolidar posicionamento, ICP, canais de aquisição, política de preços, qualificação por Índice de Recuperação (IR), roteiro da call e governança de CRM.

**Documentos revogados:** `Estratégia Comercial de Conversão`, `Framework de Aquisição e Funil`, `Preparação Comercial Mínima`, `Qualificação BANT Adaptado`, `Qualificação MEDDIC Adaptado`, `Técnica de Qualificação Avançada`, `estrategia-precificacao-v2` e `v3`. Onde houver divergência, este arquivo prevalece.

---

## 1. Posicionamento e Anti-Escopo

> "A maioria oferece um bot. A Verta instala e sustenta a operação que conecta o WhatsApp Oficial ao seu CRM e agenda, para a empresa parar de perder lead por demora."

- **O que vendemos:** Redução de trabalho manual, resposta rápida, agenda organizada e funil atualizado em tempo real. A entrega é infraestrutura de engenharia operada sob SLA (números em `OPERACAO.md`, seção 4).
- **O que NÃO vendemos:** "Robô de R$ 99", configuração self-service onde o cliente monta os fluxos, ou promessa de "aumento de vendas em X%" sem aferição prévia.
- **Arrumação da Casa:** A IA não conserta processo caótico. Se o processo for bagunçado, a Verta registra a limitação e exige uma etapa de Fundação antes de qualquer automação.

---

## 2. ICP — Perfil de Cliente Ideal

O critério que define o ICP da Verta é a combinação de **decisão rápida + ticket alto + WhatsApp como gargalo**. Decisor único encurta o ciclo de vendas de meses para dias; ticket alto faz o IR fechar com poucos leads recuperados.

São **três faixas**, não duas. Estética e odontologia foram separadas porque vendem de formas diferentes e exigem abordagens diferentes, mesmo tendo ticket parecido: estética vende por desejo, alimentada por Instagram e tráfego pago; odontologia premium vende por confiança clínica, alimentada por indicação e pela consulta de avaliação. Tratar as duas como um bloco só produziria mensagem morna que não converte em nenhuma das duas.

### ICP A1 — Clínicas de Estética Avançada

- **Ticket:** R$ 2.000 a R$ 15.000 (harmonização facial, fios de PDO, protocolos combinados).
- **Decisor:** o próprio doutor(a) ou o cônjuge que administra a clínica.
- **Origem do lead:** predominantemente Instagram e tráfego pago. Volume alto, concentrado em picos após publicação.
- **Por que sangram:** investem pesado em anúncio e a recepção acumula atendimento presencial, cobrança e WhatsApp ao mesmo tempo. O lead do anúncio espera — e desejo esfria rápido.
- **Jargão obrigatório:** avaliação, protocolo, no-show, agenda cheia, taxa de comparecimento.

### ICP A2 — Odontologia Premium

- **Ticket:** R$ 3.000 a R$ 15.000 (lentes de resina, implantes, reabilitação oral).
- **Decisor:** o próprio doutor(a) ou o gestor da clínica.
- **Origem do lead:** mistura de indicação e tráfego pago. Volume menor que A1, ciclo de decisão mais longo, valor por lead maior.
- **Por que sangram:** o lead vem quente por indicação e recebe tratamento de fila. Cadeira vazia é prejuízo direto, e remarcação não avisada custa a hora clínica inteira.
- **Jargão obrigatório:** cadeira vazia, avaliação, fechamento de plano, no-show, orçamento aprovado.

### ICP B — Advocacia Boutique com Captação Digital

- **Perfil:** 1 a 3 sócios, previdenciário, trabalhista ou empresarial, investindo em Google Ads.
- **Decisor:** sócio fundador.
- **Por que sangram:** quem busca advogado no Google tem urgência. Vinte minutos de demora e o lead fecha com o concorrente da aba de baixo. Além disso, boa parte do volume é curioso sem tese — e a hora do sócio está sendo gasta triando.
- **Jargão obrigatório:** triagem de curiosos, qualificação da tese, CPA, fechamento de contrato.

### Sequenciamento

**Comece por A1 e rode sozinho.** Com três faixas e volume baixo, tocar todas ao mesmo tempo torna impossível ler o que funcionou: se a taxa de resposta cair, não dá para saber se o problema foi a mensagem, o nicho ou o canal. Cada faixa adicional divide a amostra e triplica o tempo até haver conclusão.

Ordem recomendada: **A1 → A2 → B**. A1 primeiro porque tem o maior volume de leads e o ciclo mais curto, o que gera dados de resposta mais rápido. Entre em A2 depois de 3 semanas de cadência completa ou do primeiro fechamento, o que vier antes.

Se optar por rodar duas faixas em paralelo, registre a decisão em `DECISOES.md` e aceite explicitamente que o teste comparativo de mensagem não vai existir neste ciclo. É uma escolha legítima por velocidade — só não pode ser feita sem saber o que se está abrindo mão.

### Mineração de dor (sem achismo)

Não pesquise em blog institucional. Vá onde o cliente final reclama.

- **Tática do Google Meu Negócio:** busque clínicas e escritórios da região no Maps e filtre avaliações de 1 estrela. O padrão que aparece: "o lugar é ótimo, mas liguei e mandei WhatsApp e responderam dois dias depois."
- **Uso no outbound:** o print (com o nome do estabelecimento borrado) vira conteúdo e abertura de conversa. Nunca cite ou exponha o concorrente do prospect — a peça ilustra o problema do setor, não ataca uma empresa nomeada.
- **Quebra-gelo contextual:** movimentos do setor abrem conversa sem parecer pitch. Exemplo em estética: mudanças nas regras de divulgação de "antes e depois" aumentam o volume de direct e orçamento, e o gargalo aparece logo depois.

---

## 3. Qualificação e Índice de Recuperação (IR)

O IR é o **único critério de aprovação**. Substitui BANT, MEDDIC e a antiga regra de teto de 3% do faturamento, que reprovava PME injustamente. Faturamento bruto não é mais régua de entrada.

### Pisos de triagem (antes do IR)

| Piso | Regra |
| --- | --- |
| Ticket médio | ≥ R$ 200 |
| Volume de entrada | ≥ 40 conversas/mês |
| Autoridade | Contato é o decisor ou tem acesso direto a ele |

O piso de volume é **mensal, não semanal**. A régua antiga de 30 conversas/semana (130/mês) reprovaria justamente o ICP A2: uma clínica de odontologia premium vive bem com 50 leads/mês e ainda assim sangra dinheiro por latência. Volume alto importa em ticket baixo; em ticket alto, quem manda é o IR.

### Cálculo do IR

```
Receita recuperável/mês = leads perdidos por mês × ticket médio × 20%
IR = Receita recuperável ÷ custo mensal Verta (R$ 690 + variáveis)
```

O fator de 20% é estimativa conservadora de conversão sobre a base recuperada.

### Como derivar "leads perdidos" sem achismo

Esse número o cliente não tem — é exatamente o que ele não mede. **Nunca pergunte "quantos leads você perde?"**, porque a resposta é chute e o vendedor tende a inflar o numerador para aprovar o negócio.

Derive na tela, ao vivo, durante a call:

1. Peça para o prospect abrir o WhatsApp na hora.
2. "Quantas mensagens chegaram ontem depois das 18h?"
3. "Quantas mensagens de sexta-feira ainda estão sem resposta?"
4. "Dessas, quantas eram de gente perguntando preço ou agenda?"

Pegue a amostra de 2 dias e multiplique por 22 dias úteis. O número resultante é verificável, foi o cliente que produziu, e é ele que alimenta o IR. Registre a amostra no campo do Pipedrive.

### Matriz de decisão

| IR | Status | Ação |
| --- | --- | --- |
| ≥ 4 | Verde | Forte fit. Oferta na própria call. |
| 2 – 4 | Amarelo | Fit moderado. Escopo enxuto e aferição rígida nos primeiros 60 dias. |
| < 2 | Vermelho | Sem fit. Desqualifica com transparência e encerra sem insistência. |

---

## 4. Precificação

Custos variáveis (tokens Claude/GPT, mensagens da Meta) são faturados à parte, com repasse transparente e sem markup.

### Rota 1 — Verta Start

Para operações com processo padronizado e escopo previsível. **Não há piso de faturamento** — a entrada é definida pelo IR e pelos pisos de triagem da seção 3.

- **Setup:** R$ 2.800
- **Mensalidade:** R$ 690
- **Escopo fechado:** Atendimento 24/7 + dois módulos de nicho (ex.: Agendamento + CRM)
- **Cota de ajustes:** até 2h/mês (cota de horas, não SLA)
- **Go-live alvo:** 5 a 7 dias úteis
- **Condição de saída:** este patamar se mantém até 3 cases instrumentados, validação de horas reais gastas e demanda que não dependa só de preço.

### Rota 2 — Proposta Modular

Para operações complexas ou com escopo fora do padrão.

- **Setup:** `(Soma das horas dos módulos × R$ 85) × 1,20`
- **Travas:** setup mínimo R$ 1.800, teto de referência R$ 12.000. Acima do teto, implantação em fases.
- **Mensalidade:** soma do custo mensal dos módulos, piso inegociável de R$ 690
- **Cota de ajustes:** 2h a 6h/mês conforme número de módulos

**Regra de roteamento:** a rota é definida pela complexidade do escopo levantado no diagnóstico, não pelo faturamento do cliente.

---

## 5. Prospecção Ativa (Outbound)

Fluxo de seis etapas, do mapeamento até a reunião.

### Etapa 1 — Construção da lista

Lista montada a partir do ICP vigente, com apoio de automação em n8n.

**Fontes permitidas:**
- Google Places API (clínicas e escritórios por região, com telefone, site e avaliação) — fonte primária, legítima e estruturada.
- Instagram público: perfis que anunciam, identificados manualmente.
- LinkedIn: navegação e coleta **manual**.

**Restrição obrigatória:** scraping automatizado do LinkedIn viola os termos de uso e leva a bloqueio permanente do perfil. Como o LinkedIn é canal de abordagem da etapa 2, perder a conta encerra o canal. A automação monta e enriquece a lista; a coleta no LinkedIn é feita a mão.

**Volume alvo:** 40 a 50 contatos qualificados por semana, todos com atividade digital recente (post, anúncio rodando ou avaliação nova).

### Etapa 2 — Primeiro contato (E-mail + LinkedIn)

Cadência de 6 toques em 3 semanas, combinando os dois canais. Nenhum toque pede reunião antes do T5.

| Toque | Dia | Canal | Conteúdo |
| --- | --- | --- | --- |
| T1 | D0 | LinkedIn | Comentário com substância em post do prospect. Nunca só curtida. |
| T2 | D2 | LinkedIn | Convite de conexão sem nota (ou nota < 150 caracteres se houver contexto forte). |
| T3 | D3 | E-mail | Primeiro contato com **uma única pergunta** sobre latência, no jargão do nicho. |
| T4 | D8 | LinkedIn ou E-mail | Adição de valor com dado do setor, se não houve resposta. |
| T5 | D14 | Canal que respondeu | **A oferta.** Convite para o Diagnóstico. Só para quem engajou em T3/T4 ou visitou o perfil. |
| T6 | D21 | Mesmo canal | Encerramento educado, deixando a porta aberta. |

**Pré-requisito:** 2 posts por semana no LinkedIn com as dores do nicho. Abordagem fria de perfil sem conteúdo tem taxa de resposta muito menor.

### Etapa 3 — Triagem na conversa

Confirmado o engajamento, colete quatro dados em no máximo 3 mensagens: faturamento aproximado, gargalo principal, volume de contatos e ticket médio. Se houver incerteza ou a quarta troca não completar os dados, passe para humano.

### Etapa 4 — Formulário como porta da agenda

**O link enviado não é o Calendly. É o formulário de qualificação.** O agendamento só é liberado após o preenchimento completo.

- **Passo 1 (triagem):** faturamento, gargalo, ticket médio, conversas/mês.
- **Passo 2 (identificação):** nome, empresa, WhatsApp, e-mail.
- **Liberação:** o link do Calendly aparece na tela de sucesso apenas se IR ≥ 2. Abaixo disso, o lead recebe mensagem transparente de desqualificação e o fluxo encerra sem insistência.
- **Alerta:** leads com ticket acima de R$ 5.000 ou faturamento acima de R$ 100k disparam notificação imediata no Discord da Verta.

**Ajuste necessário no Calendly:** como a qualificação já aconteceu no formulário, o Calendly deve pedir **apenas nome, e-mail e WhatsApp**. Repetir faturamento e gargalo na tela de agendamento faz o lead responder duas vezes a mesma coisa e derruba a conclusão. As perguntas de qualificação saem do Calendly.

### Etapa 5 — Documento de Tese

Após o agendamento confirmado, o lead recebe por e-mail um documento de uma página com a leitura preliminar da operação dele. Cópia vai para a Verta.

**Conteúdo:** o que os dados do formulário indicam sobre o gargalo, a projeção preliminar de receita vazando, e as duas ou três perguntas que serão aprofundadas na reunião.

**Regras de execução:**
- Uma página. Não é proposta, não tem preço, não tem escopo fechado.
- Gerado por template preenchido automaticamente com os dados do formulário via n8n. **Não é redação manual** — escrever à mão para cada agendamento não sobrevive a 10 reuniões por semana, e boa parte vai dar no-show.
- Revisão humana de 2 minutos antes do envio, enquanto o volume permitir.
- É o que sustenta a promessa de "análise técnica prévia" feita no site e no e-mail de confirmação. Se não for enviado, a promessa sai dos materiais.

### Etapa 6 — Reunião de Diagnóstico

Ver seção 6.

---

## 6. A Call Única — Diagnóstico e Oferta

**Modelo adotado:** diagnóstico e oferta na mesma reunião. Dividir em dois encontros alonga o ciclo, esfria o lead e dobra a carga de agenda de quem acumula dono e closer.

**Duração: 45 minutos.** Trinta minutos não comportam descoberta com SPIN, quantificação do IR na tela, contraste técnico e pitch. O evento no Calendly deve ser ajustado, e a comunicação passa a dizer "45 minutos" em site, formulário e e-mails.

| Bloco | Tempo | O que acontece |
| --- | --- | --- |
| Alinhamento | 0–3 | Contexto, confirmação de tempo, o que a pessoa leva da conversa. |
| Situação | 3–12 | Mapa do funil: como o lead chega, quem responde, em que horário, com quais ferramentas. |
| Problema e quantificação | 12–22 | Derivação ao vivo dos leads perdidos (método da seção 3). O cliente abre o WhatsApp e produz o número. |
| Implicação | 22–28 | O cliente verbaliza o custo: cadeira vazia, contrato perdido, hora do sócio gasta com curioso. Quem diz o valor é ele. |
| Contraste | 28–36 | Como a engenharia da Verta entra: WhatsApp oficial → IA → CRM → agenda. Sem feature dumping. |
| Oferta | 36–43 | Rota 1 ou 2, escopo, prazo e investimento. Preço dito em voz alta, na call. |
| Próximo passo | 43–45 | Tentativa de fechamento. Se houver sócio a consultar, agenda-se o retorno com data. |

**Regras de fechamento:**
- O preço nunca é apresentado por PDF sem conversa. O PDF formaliza o que já foi acordado na call, nunca substitui a negociação.
- Se o cliente precisar validar com sócio ou caixa, o fechamento vira ligação curta ou WhatsApp com data marcada — não "te mando e você me diz".
- Nenhuma proposta sai sem o anexo de SLA preenchido.

---

## 7. Governança de CRM (Pipedrive)

### 7.1 Funil de vendas

| Etapa | Objetivo | Gatilho para avançar |
| --- | --- | --- |
| 1. Lead mapeado | Centralizar quem engajou no inbound ou foi mapeado no outbound | Lead respondeu ao primeiro toque ou preencheu o formulário |
| 2. Em triagem | Coletar os quatro dados e calcular o IR | IR ≥ 2, autoridade confirmada, convite aceito |
| 3. Diagnóstico agendado | Garantir comparecimento | Reunião ocorreu |
| 4. Diagnóstico realizado | SPIN, ancoragem do IR, oferta na mesa | Proposta apresentada |
| 5. Negociação | Objeções finais e alinhamento de escopo e SLA | Contrato assinado e setup pago |
| 6. Onboarding (Ganho) | Transição do comercial para a engenharia | Projeto iniciado conforme SOP de `ARQUITETURA.md` |

Nenhuma negociação pula etapa.

### 7.2 Campos customizados

Todos em **Negócio**, exceto onde indicado.

| Campo | Tipo | Opções / uso |
| --- | --- | --- |
| Origem do Lead | Opção única | LinkedIn · E-mail · Inbound Site · Instagram · WhatsApp direto · Indicação |
| ICP | Opção única | A1 — Estética · A2 — Odonto · B — Advocacia · Fora do ICP |
| Volume de Conversas/Mês | Numérico | Piso de triagem (≥ 40) |
| Ticket Médio | Monetário | Base do cálculo de receita recuperável |
| Leads Perdidos/Mês (amostra) | Numérico | Número derivado ao vivo na call, não estimado |
| Índice de Recuperação (IR) | Numérico | Termômetro de qualificação (aprova ≥ 2) |
| Software Atual (CRM/Agenda) | Texto | Mapear stack existente (RD, Doctoralia, planilha) |
| Rota Comercial | Opção única | Rota 1 — Verta Start · Rota 2 — Modular |
| Faturamento Aproximado *(em Organização)* | Opção única | Contexto. **Não é critério de entrada** — o piso de faturamento foi eliminado na v4.0 |

**Regra de preenchimento de Origem do Lead — o canal é onde o lead foi encontrado, não onde ele conversou.**

Quase todo lead da Verta vai acabar falando por WhatsApp, porque é o canal que a operação usa. Se "WhatsApp" for preenchido sempre que a conversa passou por lá, o campo registra 100% WhatsApp, não mede canal nenhum e a decisão de onde investir esforço perde a base.

- Quem clicou no anúncio e mandou mensagem → **Instagram**.
- Quem preencheu o formulário do site → **Inbound Site**.
- Quem veio do T5 da cadência → **LinkedIn** ou **E-mail**, conforme o canal que respondeu.
- **WhatsApp direto** só para quem já tinha o número e escreveu sem passar por nenhum canal de aquisição: indicação informal, cliente antigo, contato de evento.

**Chaves de API:** os campos do Pipedrive têm chave hash ilegível. Elas nunca são escritas direto nos workflows — o mapeamento nome → chave vive na tabela `pipedrive_config` do Supabase, conforme `ARQUITETURA.md`, seção 1.

### 7.3 Regra da próxima atividade

Um negócio **nunca** fica sem atividade agendada. Ao concluir o T2, o sistema força o agendamento do T3. Card sem atividade futura significa lead abandonado.

### 7.4 Cadências

São duas, distintas, e não devem ser confundidas:

- **Cadência de Outbound (6 toques / 21 dias):** LinkedIn + e-mail, seção 5, etapa 2. Para prospect frio.
- **Cadência de Triagem (7 toques / 21 dias):** para lead que já levantou a mão e parou de responder. T1 WhatsApp em 10 min, T2 ligação D1, T3 WhatsApp D3, T4 ligação D7, T5 WhatsApp D11, T6 ligação D15, T7 encerramento D21. Lead sem fit é interrompido no T1.

### 7.5 Motivos de perda

Obrigatórios ao marcar Perdido, para auditoria mensal do funil:

- **IR inferior a 2 (baixo volume):** sem gargalo que justifique a infraestrutura.
- **Sem autoridade:** travou com funcionário sem poder de compra.
- **No-show permanente:** agendou, faltou, parou de responder.
- **Perdido por preço:** tem o gargalo, não tem maturidade para pagar por SLA e infraestrutura.
- **Silêncio:** esgotou a cadência sem interagir.
- **Processo caótico (Fundação recusada):** tem gargalo, mas recusou a etapa de arrumação da casa.

---

## 8. Matriz de Objeções

**"Achei mais barato / vi um sistema de R$ 99."**
> "Existem boas ferramentas baratas, mas você mesmo as configura e mantém. Nós entregamos a operação instalada e integrada, cuidando do SLA, das políticas da Meta e do handoff para o seu time. Você está comparando uma assinatura de ferramenta com infraestrutura de engenharia."

**"O agente de negócios da Meta é de graça."**
> "Ele é porta de entrada básica, mas não integra com o seu CRM nem executa ação customizada no seu funil. Quando o volume sobe, você precisa de uma camada de engenharia cuidando disso continuamente. É esse gap que nós preenchemos."

**"Não quero mensalidade, só o setup."**
> "A mensalidade cobre o SLA de operação, correções, ajuste de prompts e atualização de APIs. Automação sem sustentação quebra e vira problema em 60 dias. Nós só trabalhamos com operação sustentada."

**"Já tentei automação antes e não funcionou."**
> "Costuma falhar por dois motivos: automatizar processo caótico sem arrumar a casa antes, e não ter ninguém sustentando a infraestrutura depois do go-live. Nós organizamos a base antes e assumimos a operação contínua por contrato."

**"Minha secretária já dá conta."**
> "Ela dá conta no horário comercial, com o telefone tocando e paciente na sala. A pergunta é quem responde às 21h de sexta. Vamos abrir o seu WhatsApp e olhar quantas mensagens chegaram ontem depois das 18h?"
