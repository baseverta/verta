# 09 — Módulos: o que todo cliente tem e o que depende dele

Nem todo cliente usa tudo. Alguns não têm formulário, outros não têm CRM, outros não
gravam reunião. Este protocolo separa o **básico** (sem isso não existe entrega) do
**opcional** (liga por contrato), e diz o que cada módulo exige para funcionar.

## A regra que sustenta os dois grupos

> Módulo opcional **degrada, nunca bloqueia**. Se ele não existe, o básico continua
> funcionando inteiro.

Isso não é elegância — é a mesma lição do protocolo 01: quando um passo importante
fica atrás de algo que pode não existir, um cliente sem aquele algo derruba a
operação inteira. Já aconteceu: cliente sem pasta no Drive matou a execução e levou
junto o envio do formulário, que não tinha nada a ver.

Na prática, todo consumo de módulo opcional precisa de uma guarda antes
(`Tem X?`) e `onError: continueRegularOutput` no que fala com serviço externo.

## Módulo base — todo cliente tem

| Módulo | O que é | Exige |
|---|---|---|
| Infraestrutura | Traefik, Postgres, n8n, Redis, embeddings | VPS + domínio (protocolo 08) |
| Banco de negócio | Supabase, um Project por cliente | conta Supabase |
| Canal WhatsApp | Evolution + número conectado | número dedicado, chip ativo |
| Conversa com IA | qualificação, objeções, respostas | base de conhecimento preenchida |
| Registro de conversa | histórico e sessões no banco | — |

Sem os cinco não há produto. A base de conhecimento é a que mais atrasa instalação:
ela não é técnica, é **conteúdo do cliente**, e depende de alguém sentar e escrever.
Comece a coletar no kickoff, não depois.

## Módulos opcionais

Cada linha vira uma decisão explícita na proposta — não um "a gente vê depois".

| Módulo | Liga quando | Exige | Se não tiver |
|---|---|---|---|
| **CRM** | cliente já tem CRM, ou compra um | webhook de mudança de negócio, API (protocolo 06) | o banco segue sendo a verdade; some o espelho para o time |
| **Formulário** | há captação por formulário | conta Typeform (ou equivalente) + assinatura (protocolo 04) | entrada só por WhatsApp |
| **Agenda** | há reunião agendada | Calendly (ou equivalente) + webhook | agendamento vira combinação manual na conversa |
| **Arquivos** | há documento por cliente | Drive + credencial (protocolo 05) | sem pasta, sem `RESUMO.md`, sem arquivo de transcrição |
| **Transcrição** | reuniões são gravadas | Fathom (ou equivalente) + webhook assinado | reunião não vira registro automático |
| **Relatório semanal** | cliente quer acompanhamento | e-mail configurado | acompanhamento manual |
| **Auditoria diária** | sempre que houver espelho a conferir | e-mail configurado | ninguém percebe dado faltando |
| **Detecção de objeção** | quando há volume para aprender | embeddings + base de objeções | a IA responde, mas não aprende objeção nova |

Duas observações que já custaram caro:

- **A auditoria diária parece opcional e não é**, em qualquer cliente com CRM ou
  Drive. Ela é o que faz alguém descobrir que o espelho quebrou. Sem ela o sistema
  falha em silêncio, que é o pior modo de falhar.
- **Transcrição depende de identificação**, e identificação depende de e-mail. Num
  cliente cujos leads chegam só por WhatsApp (sem e-mail), a cascata de
  identificação fica fraca antes de o módulo ser ligado. Ver protocolo 04.

## Ficha de instalação

Preencha **antes** de começar. Cada resposta vira config, não código.

```
Cliente:
Modelo:            ( ) VPS dedicada   ( ) VPS compartilhada
Domínio:
Supabase Project:
Número WhatsApp:

Módulos opcionais contratados:
  ( ) CRM ......... qual: ______  webhook? ( )sim ( )não
  ( ) Formulário .. qual: ______
  ( ) Agenda ...... qual: ______
  ( ) Arquivos .... qual: ______
  ( ) Transcrição . qual: ______
  ( ) Relatório semanal
  ( ) Auditoria diária
  ( ) Detecção de objeção

Base de conhecimento: quem entrega, até quando:
```

O campo "webhook? não" do CRM merece atenção: sem webhook, deixa de ser tempo real e
vira consulta agendada. Isso muda o desenho e o preço — **diga na proposta**, não
descubra na instalação.

## Ao ligar um módulo depois

Módulo ligado depois entra num sistema com dados já existentes. Duas coisas:

1. **Faça o retroativo de propósito ou decida não fazer.** Ligar o CRM no mês três
   não espelha sozinho os clientes dos meses um e dois. Ou você roda uma carga, ou
   aceita começar do zero — mas escolha, não deixe acontecer.
2. **Rode a auditoria logo depois.** Ela vai listar exatamente o que ficou para trás.

## Erros que já cometemos

**Tratar formulário como pré-requisito.** Ver protocolo 01. Cliente não responde,
setup trava.

**Ligar módulo sem guarda.** Nodes de Drive sem `Tem Pasta?` antes derrubaram
execução inteira quando o cliente não tinha pasta.

**Deixar módulo opcional implícito.** "A gente configura o CRM depois" vira
expectativa de um lado e escopo não previsto do outro. Ou está na ficha, ou não
existe.
