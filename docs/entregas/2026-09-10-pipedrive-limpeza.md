# Relatório — Limpeza de Resíduos do Pipedrive

**Conta:** Verta (company_id `17171734`) · **Executado em:** 09/09/2026
**Resultado:** 7 escritas, todas com sucesso. Configuração de hoje intacta, verificada por hash.

**Arquivos:** `pipedrive-limpeza-antes.json` (estado antes de qualquer escrita) e `pipedrive-limpeza-depois.json` (verificação final).

---

## Correção importante da premissa

O prompt partia da ideia de que havia negócios, organizações e pessoas de teste a excluir. **Não havia.** Todos já estavam com `is_deleted: true` — a varredura confirmou registro por registro.

O que de fato sobrou foram **6 atividades órfãs**: elas sobreviveram à exclusão dos negócios pais e continuavam ativas, apontando para registros que já não existiam. É exatamente o sintoma que você descreveu. Essas 6 eram a totalidade do resíduo ativo da conta.

## 1. Auditoria completa

| Tipo | ID | Nome | Estado encontrado | Classificação | Ação |
| --- | --- | --- | --- | --- | --- |
| Negócio | 51 | WhatsApp - Francinete Leite | `is_deleted: true` | resíduo | já excluído |
| Negócio | 53 | TESTE - AlfaTesteLtda | `is_deleted: true` | resíduo | já excluído |
| Negócio | 70 | WhatsApp - Francinete Leite | `is_deleted: true` | resíduo | já excluído |
| Negócio | 1–70 | *(67 outros)* | `is_deleted: true` | resíduo | já excluídos |
| Organização | 18 | Manekin | `is_deleted: true` | resíduo | já excluída |
| Organização | 31 | Manekin | `is_deleted: true` | resíduo | já excluída |
| Pessoa | 54 | Francinete Leite da Silva Diniz | `is_deleted: true` | resíduo | já excluída |
| Pessoa | 68 | Francinete Leite | `is_deleted: true` | resíduo | já excluída |
| Atividade | 13 | Diagnostico Operacional | ativa, deal 51 | resíduo | **excluída** |
| Atividade | 14 | Reuniao de kickoff - Manekin | ativa, deal 51 | resíduo | **excluída** |
| Atividade | 15 | Chamada | ativa, deal 51 | resíduo | **excluída** |
| Atividade | 20 | Diagnostico realizado - AlfaTesteLtda | ativa, deal 53 | resíduo | **excluída** |
| Atividade | 27 | Diagnostico Operacional | ativa, deal 70 | resíduo | **excluída** |
| Atividade | 28 | Reuniao de kickoff - Manekin | ativa, deal 70 | resíduo | **excluída** |
| Negócio | 71 | Verta | ativo, etapa 15 | interno | preservado |
| Organização | 32 | Verta | ativa | interno | preservada |
| Pessoa | 69 | Michael Jordan | ativa | interno | preservada |
| Atividade | 84 | Reunião de Disgnóstico | ativa | interno | **ajustada** |

**Nenhum registro ficou como incerto.** As 6 atividades excluídas foram criadas em 05–06/09, todas apontando para negócios de teste já excluídos, com nomes inequívocos.

**Cobertura da varredura:** consultei também `deals/archived` (0 itens) e `deals?status=deleted` (70 itens). Os endpoints `organizations/archived` e `persons/archived` retornam **404 — não existem** na API v2.

### Sobre os 70 negócios excluídos

Todos criados entre 03 e 06/09, todos com nome de teste (`WhatsApp - Teste Cache`, `Padaria Teste Proposta`, `[Sample] Tony Turner…`, etc.). Já estão fora de qualquer relatório.

**Não é possível forçar exclusão permanente pela API** — o `DELETE` do Pipedrive é soft-delete e a purga definitiva ocorre automaticamente 30 dias depois. Como foram excluídos entre 03 e 06/09, desaparecem de vez entre **03 e 06/10/2026**. Nenhuma ação necessária.

## 2. O que foi excluído

| Tipo | ID | Nome | Negócio referenciado |
| --- | --- | --- | --- |
| Atividade | 13 | Diagnostico Operacional | 51 |
| Atividade | 14 | Reuniao de kickoff - Manekin | 51 |
| Atividade | 15 | Chamada | 51 |
| Atividade | 20 | Diagnostico realizado - AlfaTesteLtda | 53 |
| Atividade | 27 | Diagnostico Operacional | 70 |
| Atividade | 28 | Reuniao de kickoff - Manekin | 70 |

Cada exclusão foi precedida de um GET individual que revalidava o registro e recusava prosseguir se a atividade apontasse para um negócio fora da lista aprovada. A ordem atividades → negócios → pessoas → organizações foi respeitada; as três últimas etapas ficaram vazias por não haver o que excluir.

## 3. Etiquetas — inventário, nada excluído

### Negócio — 8 etiquetas, todas criadas por você

| ID | Nome |
| --- | --- |
| 65 | Qualificado |
| 66 | Incerto |
| 67 | Sem fit |
| 68 | Rota 1 (Start) |
| 69 | Rota 2 (Modular) |
| 70 | Origem: WhatsApp |
| 71 | Origem: Typeform |
| 72 | Origem: Calendly |

### Pessoa — 4 etiquetas, todas nativas

`14` Customer (verde) · `15` Hot lead (vermelho) · `16` Warm lead (amarelo) · `17` Cold lead (azul)

### Organização — 4 etiquetas, todas nativas

`10` Customer (verde) · `11` Hot lead (vermelho) · `12` Warm lead (amarelo) · `13` Cold lead (azul)

**Como distingui-las:** as nativas são o conjunto padrão que o Pipedrive cria em toda conta — quatro etiquetas em inglês, com cores fixas atribuídas pelo sistema. As de Negócio estão em português, seguem a nomenclatura da Verta e não têm cor definida.

**`Engajou` não existe** em nenhuma das três entidades. Ao criá-la, ela entra como uma opção do campo `label_ids` (tipo `set`) da entidade escolhida.

### Divergência encontrada

O prompt afirmava que a **organização 32 tem a etiqueta 10**. Ela **não tem** — `label_ids` está vazio. No backup desta manhã ela tinha a `10`; a etiqueta foi removida em algum momento entre as duas execuções, e não por mim (a sessão anterior só tocou em campos personalizados).

O negócio 71 confirma o esperado: etiquetas `65` (Qualificado) e `69` (Rota 2 Modular).

## 4. Tipos de atividade nativos — recomendação

Nenhum foi excluído nem desativado. Os 6 seguem ativos.

| ID | Nome | `key_string` | Recomendação |
| --- | --- | --- | --- |
| 1 | Chamada | `call` | **manter** — vetado por você; usado pela sincronia com o Calendar |
| 2 | Reunião | `meeting` | **manter** — idem |
| 3 | Tarefa | `task` | manter — genérico e útil |
| 4 | Prazo | `deadline` | manter — útil para SLA |
| 5 | E-mail | `email` | manter — usado por sincronia de e-mail |
| 6 | Almoço | `lunch` | **desativar** — sem uso previsto na operação |

**Recomendo desativar apenas `Almoço` (id 6).** A atividade 84 comprova sua ressalva sobre Calendar: ela carregava uma sala real do Google Meet com `conference_meeting_id` ativo, criada via `call`.

Desativação é reversível: `PUT /api/v1/activityTypes/6` com `active_flag: false`. **Não executei** — aguardo sua decisão.

## 5. Atividade 84 — estado após os ajustes

| Campo | Antes | Depois |
| --- | --- | --- |
| `subject` | Reunião de Disgnóstico | **Diagnóstico (Meet) — Verta (teste)** |
| `type` | `call` | **`diagnostico_meet`** |
| `duration` | 00:30 | **00:45** |

Inalterados: data 10/09/2026, início 13:00, vínculos (negócio 71, pessoa 69, organização 32), status não-concluída.

**Sala do Meet preservada:** `https://meet.google.com/rap-kkwp-yhd` — o `conference_meeting_id` sobreviveu ao PATCH. O evento no Google Calendar foi atualizado e agora termina às **13h45** em vez de 13h30. O único participante é você (pessoa 69), então ninguém externo recebeu notificação de alteração.

**Detalhe técnico:** o campo `type` exige a `key_string` do tipo (`diagnostico_meet`), não o ID numérico 15. Passar `15` teria falhado ou gravado um tipo errado.

## 6. Verificação: configuração de hoje intacta

Comparação do objeto completo de cada coleção, antes e depois, via SHA256:

| Objeto | Itens | SHA256 antes | SHA256 depois | Resultado |
| --- | --- | --- | --- | --- |
| `stages` | 7 → 7 | `15066A7193C3454697B15F5719752D9C` | `15066A7193C3454697B15F5719752D9C` | **idêntico** |
| `pipelines` | 2 → 2 | `7487A4B81F745FDA6BC6163409899C4D` | `7487A4B81F745FDA6BC6163409899C4D` | **idêntico** |
| `dealFields` | 58 → 58 | `05F50051C2669E91BBB6C21DCF9C5635` | `05F50051C2669E91BBB6C21DCF9C5635` | **idêntico** |
| `organizationFields` | 35 → 35 | `D3635C8810621FD84A2784D61B065CB8` | `D3635C8810621FD84A2784D61B065CB8` | **idêntico** |
| `activityTypes` | 15 → 15 | `59BA0B07D5976CD5D2604E065BFF6959` | `59BA0B07D5976CD5D2604E065BFF6959` | **idêntico** |

**Nenhuma diferença em nenhum dos cinco.** O hash de `stages` é o mesmo registrado no relatório da configuração — as 7 etapas seguem sem qualquer escrita desde então.

Nenhuma chamada foi emitida contra `/stages`, `/pipelines`, `/dealFields` ou `/organizationFields`. As únicas escritas da sessão foram 6 DELETE e 1 PATCH, todas em `/api/v2/activities`.

## 7. Contagem final

| Entidade | Antes | Depois |
| --- | --- | --- |
| Negócios ativos | 1 | **1** |
| Organizações ativas | 1 | **1** |
| Pessoas ativas | 1 | **1** |
| Atividades ativas | 7 | **1** |

**Registros remanescentes:**

- Negócio `71` "Verta" — etapa 15, funil 2
- Organização `32` "Verta"
- Pessoa `69` "Michael Jordan"
- Atividade `84` "Diagnóstico (Meet) — Verta (teste)" — 10/09 13:00, 45min

A conta está limpa: só o conjunto interno da Verta, que você decide se mantém.

---

## Pendências para você decidir

1. **Desativar o tipo `Almoço` (id 6)?** Aguardo sua palavra.
2. **Criar a etiqueta `Engajou`** — diga em qual entidade (Negócio é o provável, dado o uso em cadência) que eu crio.
3. **Negócio 71 e organização 32** — se ficarem como cadastro interno, marque a organização com a flag de dado interno para não gerar alerta falso na auditoria diária de espelhamento.
4. **Regenerar o token de API** — continua pendente do relatório anterior. Ele passou pelo chat e segue válido.
