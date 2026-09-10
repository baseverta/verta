# Relatório — Correção da Configuração do Pipedrive

**Conta:** Verta (company_id `17171734`) · **Executado em:** 09/09/2026
**Resultado:** 26 escritas, todas com sucesso. Nenhum erro HTTP, nenhuma etapa alterada.

**Arquivos gerados:** `pipedrive-backup-antes.json` (estado íntegro antes de qualquer escrita) e `pipedrive-backup-depois.json` (verificação final).

---

## 1. Nomes dos funis — nenhuma ação necessária

A suspeita de inversão **não se confirmou**. Os nomes já descreviam o conteúdo correto:

| Funil | Nome antes | Nome depois | Conteúdo |
| --- | --- | --- | --- |
| 2 | `01 - Prospecção` | `01 - Prospecção` *(inalterado)* | etapas 15, 16, 17, 26 |
| 4 | `02 - Fechamento` | `02 - Fechamento` *(inalterado)* | etapas 18, 19, 20 |

Nenhum PATCH foi emitido em `/pipelines`.

## 2. Campos excluídos de Organização

**Prova de segurança antes de excluir:** existia **uma única organização** na conta (id 32, "Verta"). As 8 chaves retornaram explicitamente `null` no objeto dela — verificado no backup inicial e **revalidado por um novo GET imediatamente antes dos DELETEs**. Nenhum dado foi perdido.

Todos os 8 tinham `is_custom_field: true`, confirmando que nenhum campo nativo foi tocado.

| Nome | Key excluída | Tipo |
| --- | --- | --- |
| Origem do Lead | `074a2b2982bfa2108050a2c63697e3299bbdf301` | enum |
| ICP | `ad435c13c2a95ee684c3bc5546571321413cfdaa` | enum |
| Volume de Conversas/Mês | `3b6d87e558f273d46612fe9c305cb24d29bb06a6` | double |
| Ticket Médio | `6d2de0b6734194fc91f1c997ed5d9a98fcaaece8` | monetary |
| Leads Perdidos/Mês | `1f8fb7d1c3602e71a2159db5773b1ca15f863156` | double |
| Índice de Recuperação | `6e9818780c7275fa71c73c9dbd882a5a0d68138b` | double |
| Software Atual | `1e429433bf7d2631246b82ec8e3250e658a08b36` | varchar |
| Rota Comercial | `14c479df2bff18281accf39ebeab8d0644130f15` | enum |

`Faturamento Aproximado` **não estava** entre os 8 — foram 8 exclusões, e ele foi criado do zero.

## 3. ⭐ Campos criados em Negócio — chaves para o n8n

**Esta é a entrega principal.** Use estas keys nos workflows:

| Nome | `key` | Tipo |
| --- | --- | --- |
| Origem do Lead | `cf1d89d574bdec4674b046791949a99bd5ce59fa` | enum |
| ICP | `6191cc510bf3d5815ac8d4231b02f4fe2dd92021` | enum |
| Volume de Conversas/Mês | `44c6dc9d259349def6a64f6a0534b4ae34ad6c62` | double |
| Ticket Médio | `7a11436fe7cc27cedf80e0fff04f0bc83b1be264` | monetary |
| Leads Perdidos/Mês | `9ac324e99825c08e05d785a89a2e8866eb34393f` | double |
| Índice de Recuperação | `3048f51cd1c58b890a85a900d8c6263b3b389f7e` | double |
| Software Atual (CRM/Agenda) | `9315a06ccadb9af2d8f12b0b0cae265a142b6055` | varchar |
| Rota Comercial | `0ca3261dde48fb34c91d9997d9da69b03ac68ba6` | enum |

### IDs das opções (necessários para gravar valores de enum via API)

**Origem do Lead** — `96`=LinkedIn · `97`=E-mail · `98`=Inbound Site · `99`=Instagram · `100`=WhatsApp · `101`=Indicação

**ICP** — `102`=A1 — Estética · `103`=A2 — Odonto · `104`=B — Advocacia · `105`=Fora do ICP

**Rota Comercial** — `106`=Rota 1 — Verta Start · `107`=Rota 2 — Modular

> Conforme a arquitetura da Verta, essas chaves opacas devem ser mapeadas em `pipedrive_config` no Supabase com nomes legíveis, nunca escritas direto nos workflows do n8n.

## 4. Campo criado em Organização

| Nome | `key` | Tipo |
| --- | --- | --- |
| Faturamento Aproximado | `58f54ae6225863454cb946ba57f6c5a54ab5b712` | enum |

**Opções:** `108`=Até R$ 15 mil · `109`=R$ 15–100 mil · `110`=R$ 100–500 mil · `111`=Acima de R$ 500 mil

É o único campo personalizado que resta em Organização, como especificado. A faixa `108` alinha com a regra de Rota 1 até R$ 15 mil.

## 5. Tipos de atividade

**Já existiam (6 nativos, intocados):** Chamada, Reunião, Tarefa, Prazo, E-mail, Almoço.

**Criados (9):**

| ID | Nome | `icon_key` |
| --- | --- | --- |
| 7 | T1 — Comentário LinkedIn | `bubble` |
| 8 | T2 — Convite Conexão | `addressbook` |
| 9 | T3 — E-mail Abertura | `email` |
| 10 | T4 — Valor | `bulb` |
| 11 | T5 — Convite Diagnóstico | `calendar` |
| 12 | T6 — Break-up | `finish` |
| 13 | Triagem WhatsApp | `smartphone` |
| 14 | Ligação de Resgate | `call` |
| 15 | Diagnóstico (Meet) | `meeting` |

Nenhum dos 9 existia antes. Todos os `icon_key` saíram da lista válida documentada.

## 6. Verificação final

GET de confirmação após todas as escritas (`pipedrive-backup-depois.json`):

- `dealFields` → **8** campos personalizados, exatamente os da seção 3
- `organizationFields` → **1** campo personalizado, o da seção 4
- `activityTypes` → **15** tipos: 6 nativos + 9 criados
- `pipelines` → 2 funis, nomes inalterados

## 7. Prova de que nenhuma etapa foi alterada

Comparação do objeto **completo** das 7 etapas entre o backup inicial e a verificação final — incluindo `update_time`, que mudaria em qualquer escrita:

```
SHA256 antes : 15066A7193C3454697B15F5719752D9C
SHA256 depois: 15066A7193C3454697B15F5719752D9C
→ IDÊNTICO byte a byte
```

| Funil | ID | Etapa | Prob. | Rot | Dias |
| --- | --- | --- | --- | --- | --- |
| 2 | 15 | Lista de Prospecção | 10% | sim | 3 |
| 2 | 16 | Em Cadência | 20% | sim | 25 |
| 2 | 17 | Qualificado - Formulário Preenchido | 40% | sim | 5 |
| 2 | 26 | Diagnóstico Agendado | 60% | não | — |
| 4 | 18 | Diagnóstico & Proposta | 30% | sim | 7 |
| 4 | 19 | Negociação & SLA | 60% | sim | 10 |
| 4 | 20 | Onboarding | 100% | não | — |

Nenhuma chamada foi emitida contra `/stages` além de GET.

## 8. Registros de teste encontrados

Nada foi apagado — reportado para sua decisão.

| Tipo | ID | Identificação | Situação |
| --- | --- | --- | --- |
| Negócio | 71 | "Verta" | etapa 15, funil 2, status aberto, valor R$ 0 |
| Organização | 32 | "Verta" | a própria empresa; `baseverta.com.br`, endereço em Areial-PB |
| Pessoa | 69 | — | vinculada ao negócio 71 |

São os **únicos** registros da conta — 1 organização e 1 negócio no total. Não há outros candidatos a teste.

**Recomendação:** se a organização 32 for permanecer como cadastro real da Verta, marque-a com a flag de dado interno, para que a auditoria diária de espelhamento não gere alerta falso.

## 9. Pendências de interface (sem endpoint na API)

Confirmado que não há endpoint público. **Precisam ser feitas por você na interface:**

1. **Motivos de perda** — lista predefinida e obrigatória: IR inferior a 2 · Sem autoridade · No-show permanente · Perdido por preço · Silêncio · Processo caótico (Fundação recusada).
2. **Campos obrigatórios por etapa** — `Ticket Médio`, `Volume de Conversas/Mês` e `Índice de Recuperação` obrigatórios para sair de "Qualificado - Formulário Preenchido" (etapa 17).
3. **Alerta de negócio sem atividade agendada.**

Observação: o POST de `dealFields` aceita os parâmetros opcionais `required_fields` e `important_fields`, que **podem** cobrir o item 2. Não foram usados por estarem fora do escopo autorizado. Vale testar antes de configurar manualmente.

## 10. Divergências entre o pedido e a execução

| # | Pedido | Realidade | Resolução |
| --- | --- | --- | --- |
| 1 | Renomear funis | Já estavam corretos | Nenhuma escrita |
| 2 | Base `api/v1` | Campos e pipelines são **v2**; `activityTypes` só existe em **v1** | Uso misto |
| 3 | — | v1 saiu de suporte em 01/08/2026, mas só uma lista seleta (Deals, Orgs, Persons, Activities, Products, Pipelines, Stages). `activityTypes` não está nela | `POST /api/v1/activityTypes` funcionou (HTTP 201) |
| 4 | Autenticação | `?api_token=` descontinuado na v2 | Header `x-api-token` |
| 5 | Body `name` | v2 usa **`field_name`** | Ajustado |
| 6 | Distinguir por `add_time` | v2 **não retorna** `add_time` em fields | Usado `is_custom_field`, discriminador mais confiável |
| 7 | Ticket Médio "monetário (BRL)" | Moeda não é configurável por campo | Moeda padrão da conta já é **BRL** e o negócio 71 também — opera em BRL naturalmente |
| 8 | Origem do Lead com 5 opções | O campo antigo tinha **WhatsApp** | Incluído, com sua aprovação — 6 opções |
| 9 | ICP agrupando Estética/Odonto | Estavam separados | Mantidos separados (A1/A2), com sua aprovação |
| 10 | Ordem: excluir (T2) antes de criar (T3) | — | **Invertida de propósito:** criei tudo primeiro e excluí por último, para que uma falha no meio nunca destruísse campos sem ter os novos no lugar |

---

## Ação pendente de segurança

O token de API foi transmitido pelo chat durante a execução. **Regenere-o em https://app.pipedrive.com/settings/api.** Como o Pipedrive permite apenas um token ativo por vez, atualize junto qualquer integração que use o valor atual — n8n em primeiro lugar.
