# baseverta-core

Chassi de automação da Verta. Este repositório é replicado por cliente:
o que está aqui precisa funcionar numa instalação limpa, sem depender do
estado do projeto atual.

## Mapa

| Caminho | O que é |
| --- | --- |
| `.verta/` | **Fonte da verdade documental.** Cinco documentos oficiais. Em divergência com qualquer outro arquivo, estes prevalecem. |
| `migrations/` | Esquema do Supabase, em ordem numérica. |
| `embeddings-server/` | BGE-M3 self-hosted, na rede `internal`. |
| `docker-compose.yml` | Infraestrutura da VPS. Imagem do n8n com versão fixa, nunca `latest`. |
| `.agents/skills/` | Skills versionadas. `.claude/` é cópia local e fica fora do versionamento. |
| `docs/entregas/` | Relatórios datados de trabalho concluído. Histórico, não norma. |
| `docs/arquivo/` | Material superado, mantido só para consulta. |

Os cinco documentos oficiais em `.verta/`:

- **ARQUITETURA.md** — fluxo de dados, modelagem, infraestrutura
- **DECISOES.md** — desvios arquiteturais e o porquê de cada um
- **OPERACAO.md** — rotina, alertas, resposta a incidente
- **COMERCIAL.md** — funil, qualificação, motivos de perda
- **POSICIONAMENTO.md** — discurso e mercado

## Migrações

Instalação nova roda em ordem:

```
000-comum.sql            função de toque de updated_at
001-dicionario-crm.sql   crm_ref + view de compatibilidade
002-nucleo-relacional.sql organizations, contacts, deals, external_refs
```

`003-correcoes-integridade.sql` **não entra em instalação nova.** Existe só
para o projeto que rodou 001 e 002 nas versões anteriores a 10/09/2026;
em base limpa, 000→002 já produzem aquele estado e o 003 falha por
constraint duplicada. O cabeçalho do arquivo repete o aviso.

`organizations` é a raiz absoluta: nenhuma tabela operacional existe sem
`organization_id NOT NULL`.

## Segredos

Nada de valor real entra no repositório. `.env.example` lista **nomes** de
variável e serve de checklist de provisionamento — variável ausente no
container derruba o workflow em runtime, não no deploy.

O `.gitignore` protege por padrão, não por enumeração. A regra por
enumeração já falhou duas vezes: `.env.tally` e um arquivo de acessos em
texto puro na raiz, ambos a um `git add -A` do GitHub.

## Pontos em aberto

- Instalação nova não tem caminho de carga inicial do `crm_ref`. O seed em
  `docs/entregas/` popula a tabela **antiga**, anterior ao 001.
- Fase 2: migrar os nós do n8n da view `pipedrive_config` para `crm_ref`.
  Só então a Fase 3 derruba a view e o `_bkp`.
- Evolution API x API oficial da Meta segue indefinida. Sessões, mensagens
  e embeddings ficaram fora do 002 por isso.
