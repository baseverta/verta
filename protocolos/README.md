# Protocolos Verta

Este diretório é a memória operacional da Verta: o que aprendemos construindo o
sistema no **Cliente Zero** (a própria Verta), escrito para não repetir os mesmos
erros na instalação de cada cliente novo.

Não é documentação de arquitetura — para isso existe o `ARQUITETURA-DADOS.md` na
raiz do projeto. Aqui é **como fazer** e, principalmente, **onde a gente já tropeçou**.

## Índice

| Arquivo | Quando ler |
|---|---|
| [01 — Setup de cliente novo](01-setup-novo-cliente.md) | Toda vez que um cliente fecha. É o passo a passo. |
| [02 — Trabalhando com n8n](02-n8n.md) | Antes de criar ou editar qualquer workflow. |
| [03 — Supabase e dados](03-supabase-e-dados.md) | Antes de mexer em tabela, função, trigger ou query. |
| [04 — Webhooks e integrações](04-webhooks-e-integracoes.md) | Ao conectar qualquer ferramenta nova. |
| [05 — Google Drive](05-google-drive.md) | Ao mexer em pastas, arquivos ou no ciclo de vida do cliente. |
| [06 — Pipedrive](06-pipedrive.md) | Ao mexer em campo, etapa, etiqueta ou pipeline. |
| [07 — Nomenclatura e organização](07-nomenclatura-e-organizacao.md) | Ao nomear qualquer coisa nova. |

## Como usar isto

**Antes de começar uma tarefa**, leia o protocolo do tema. Cada um tem uma seção
"Erros que já cometemos" — são erros reais, com o sintoma que apareceu na tela e a
causa de verdade. Eles custaram tempo uma vez; não precisam custar de novo.

**Depois de tropeçar em algo novo**, escreva aqui. Um erro que não virou protocolo
vai voltar. A regra é registrar o **sintoma** (o que apareceu), a **causa real**
(quase nunca é a primeira hipótese) e a **regra prática** que evita a repetição.

## Onde este conteúdo vive

Três lugares, sempre iguais:

1. **Repositório** — `protocolos/` no `baseverta-core`. É a origem: edite aqui.
2. **GitHub** — versionado, com histórico de por que cada regra apareceu.
3. **Google Drive** — `Operacional / Protocolos`. É a cópia para leitura de quem
   não abre o repositório.

Ao editar, edite no repositório, commite, e suba a cópia para o Drive. O Drive é
espelho; o repositório é a fonte da verdade — mesma lógica que usamos para dados
(Supabase manda, Pipedrive espelha).
