# 03 — Supabase e dados

## A decisão de fundo

**Supabase é a fonte da verdade. Pipedrive é o espelho completo.**

Três razões pelas quais não é o contrário:

1. A API do Pipedrive não faz JOIN nem query arbitrária. Qualquer cruzamento vira
   N chamadas HTTP.
2. Caminho quente (conversa de WhatsApp) não aguenta latência e limite de taxa de
   CRM.
3. Conversa, embedding e trilha de auditoria não são dado de CRM. Não cabem lá.

Espelho completo significa: **tudo que está no Supabase e faz sentido para uma
pessoa está também no Pipedrive.** O time trabalha no CRM; ninguém deve precisar
abrir o banco para saber algo sobre um cliente.

## Nunca dropar sem procurar dentro do banco

Este custou uma quebra em produção. Removemos `find_similar_objection()` depois de
um `grep` em todos os workflows do n8n não achar nenhuma referência. A função era
chamada **de dentro de um trigger do próprio banco**. O webhook de objeção passou a
devolver HTTP 500 e ficou quebrado silenciosamente até a auditoria seguinte.

Antes de qualquer `DROP`, rode as três buscas:

```sql
-- funções que citam o objeto no corpo
SELECT proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND prosrc ILIKE '%nome_do_objeto%';

-- triggers
SELECT trigger_name, event_object_table FROM information_schema.triggers
WHERE trigger_schema = 'public';

-- views
SELECT table_name FROM information_schema.views
WHERE table_schema = 'public' AND view_definition ILIKE '%nome_do_objeto%';
```

E depois do DROP, **dispare o fluxo que toca aquela tabela** e confira a execução.
O teste de fumaça é o que pega esse tipo de regressão.

**Corolário:** `DROP ... CASCADE` leva junto o que você não viu. Foi assim que
perdemos a view `kb_objection_underperforming` ao remover a tabela de log de que ela
dependia — e o relatório semanal só quebraria na segunda seguinte, longe do commit
que causou.

## O padrão anti-parada silenciosa

Um `SELECT` que retorna zero linhas **encerra o ramo** no n8n, sem erro. O workflow
"funciona" e não faz nada. Toda busca que pode não achar nada usa este formato:

```sql
WITH found AS (
  SELECT id, company FROM leads WHERE public_token = 'x'::uuid LIMIT 1
)
SELECT * FROM found
UNION ALL
SELECT NULL::bigint, NULL::text
WHERE NOT EXISTS (SELECT 1 FROM found);
```

Assim sempre vem uma linha, e o IF seguinte decide o que fazer — em vez de o
workflow morrer no meio sem ninguém saber.

## Ordem de CTE

Uma CTE só enxerga CTEs definidas **antes** dela. O erro é claro mas confunde:
*"There is a WITH item named X, but it cannot be referenced from this part of the
query"*. Ao montar SQL longo por concatenação em Code node, mantenha a ordem de
declaração igual à ordem de dependência.

## Cast de tipo em dado que veio de fora

Dado vindo de URL, formulário ou webhook **não é confiável**. `'texto'::uuid`
estoura e derruba a execução. Valide o formato antes de montar a query:

```js
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const tokenValido = !!token && UUID_RE.test(String(token).trim());
```

E tenha sempre um critério seguinte para cair (e-mail, telefone, CNPJ) em vez de
falhar.

## Apagar lead apaga o histórico junto

As tabelas filhas têm cascade. Apagar um lead de teste leva junto transcrições,
formulários e contatos dele. É o comportamento correto, mas explica sumiço que
parece bug: se uma linha "desapareceu" depois de uma execução bem-sucedida, confira
se o lead pai ainda existe antes de investigar o workflow.

## Dados internos não são clientes

`leads.is_internal = true` marca registro da própria Verta (teste, Cliente Zero).
A auditoria diária ignora esses registros.

Isso não é cosmético: alerta que grita todo dia sobre algo que ninguém vai corrigir
treina o time a ignorar o e-mail inteiro — e aí o alerta de verdade passa batido.
**Alerta que não gera ação é ruído, e ruído é dívida.**

## A auditoria diária

Roda às 08h30, varre o Supabase e manda e-mail **só quando há algo a corrigir**.
Ela checa: lead sem Deal, sem Person, empresa sem Organização, Organização sem pasta
no Drive, lead sem e-mail, e transcrição arquivada sem cliente identificado.

Quando ela reclama, ou o dado falta mesmo (aja) ou a regra está errada (conserte a
regra). O que não vale é conviver com o alerta.

## Erros que já cometemos

**Status inválido derrubando webhook.** Gravamos `pending_review` num campo com
`CHECK` que só aceitava `pending/promoted/merged/rejected`. HTTP 500 sem pista.
Antes de gravar valor em campo de status, confira as constraints da tabela.

**Concluir que uma tabela está vazia por causa da resposta de uma API.** Ver
protocolo 02, seção de armadilhas — `limit` alto devolve objeto de erro, não lista.
