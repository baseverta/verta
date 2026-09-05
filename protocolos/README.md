# Protocolos Verta

Este diretório é a memória operacional da Verta: o que aprendemos construindo o
sistema no **Cliente Zero** (a própria Verta), escrito para não repetir os mesmos
erros na instalação de cada cliente novo.

Não é documentação de arquitetura — para isso existe o `ARQUITETURA-DADOS.md` na
raiz. Aqui é **como fazer** e, principalmente, **onde a gente já tropeçou**.

## Índice

| Arquivo | Quando ler |
|---|---|
| [01 — Setup de cliente novo](01-setup-novo-cliente.md) | Toda vez que um cliente fecha. É o passo a passo. |
| [02 — Trabalhando com n8n](02-n8n.md) | Antes de criar ou editar qualquer workflow. |
| [03 — Supabase e dados](03-supabase-e-dados.md) | Antes de mexer em tabela, função, trigger ou query. |
| [04 — Webhooks e integrações](04-webhooks-e-integracoes.md) | Ao conectar qualquer ferramenta nova. |
| [05 — Armazenamento de arquivos](05-armazenamento-de-arquivos.md) | Ao mexer em pastas, arquivos ou no ciclo de vida do cliente. |
| [06 — CRM](06-crm.md) | Ao mexer em campo, etapa, etiqueta ou funil. |
| [07 — Nomenclatura e organização](07-nomenclatura-e-organizacao.md) | Ao nomear qualquer coisa nova. |
| [08 — Modelos de implantação](08-modelos-de-implantacao.md) | Ao provisionar infraestrutura de cliente. |
| [09 — Módulos por cliente](09-modulos-por-cliente.md) | Ao fechar escopo. O que é básico e o que é opcional. |

## Camada × ferramenta

Estes protocolos servem para **instalar cliente**, e cliente varia. Por isso os
documentos descrevem a **camada** — o papel que alguma ferramenta precisa cumprir —
e usam a ferramenta atual só como exemplo concreto.

| Camada | Ferramenta hoje | Varia por cliente? |
|---|---|---|
| Motor de automação | n8n | não — é o núcleo do que entregamos |
| Banco de negócio | Supabase | não — um *Project* por cliente, sempre |
| Infraestrutura | Docker + Traefik em VPS | modelo varia (protocolo 08), stack não |
| Canal de conversa | Evolution / WhatsApp | não, no produto atual |
| CRM | Pipedrive | **sim** — ou nenhum |
| Armazenamento de arquivos | Google Drive | **sim** |
| Formulário | Typeform | **sim** — ou nenhum |
| Agenda | Calendly | **sim** — ou nenhum |
| Transcrição | Fathom | **sim** — ou nenhum |

Quando a camada varia, o protocolo termina com um checklist do que precisa ser
respondido **antes** de escrever automação — porque a resposta muda o desenho, não
só a configuração. O caso mais caro: CRM que não emite webhook deixa de ser tempo
real e vira consulta agendada. Isso é escopo, e vai na proposta.

Ferramenta nova entra como chave de configuração, nunca como código espalhado.

## Como usar isto

**Antes de começar uma tarefa**, leia o protocolo do tema. Cada um tem uma seção
"Erros que já cometemos" — são erros reais, com o sintoma que apareceu na tela e a
causa de verdade. Eles custaram tempo uma vez; não precisam custar de novo.

**Depois de tropeçar em algo novo**, escreva aqui. Um erro que não virou protocolo
vai voltar. Registre o **sintoma** (o que apareceu, com a mensagem literal), a
**causa real** (quase nunca é a primeira hipótese) e a **regra prática**.

## Onde este conteúdo vive

1. **Repositório** — `protocolos/` no `baseverta-core`. É a origem: edite aqui.
2. **GitHub** — versionado, com o histórico de por que cada regra apareceu.
3. **Google Drive** — `Operacional / Protocolos`. Cópia para quem não abre o repositório.

O Drive é espelho; o repositório é a fonte da verdade — mesma lógica que usamos para
dados (protocolo 03).

Documentos de estratégia e SOPs de origem ficam em `.verta/`. Quando um protocolo
daqui tem um documento de origem lá, ele diz qual.
