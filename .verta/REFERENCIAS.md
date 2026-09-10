# REFERENCIAS.md — Verta: Identificadores, Esquema e Infraestrutura

**Status:** Oficial e Ativo
**Versão:** 1.0 · auditado em 09/09/2026
**Objetivo:** Guardar os identificadores e o estado de configuração dos sistemas da Verta. Sem este documento, reconstruir a integração exige refazer a auditoria inteira à mão.

**Regra de uso:** as chaves abaixo **nunca são escritas direto nos workflows do n8n**. Elas vivem na tabela `crm_ref` do Supabase (view de compatibilidade: `pipedrive_config`) e são lidas de lá em tempo de execução. Este arquivo é a cópia humana, para conferência e recuperação.

---

## 1. Pipedrive — conta

Company ID `17171734`.

**Autenticação:** header `x-api-token`. O parâmetro `?api_token=` foi descontinuado na v2.
**Versões da API:** campos e funis são v2; `activityTypes` só existe na v1.

> **Pendência de segurança:** o token de API trafegou por chat e precisa ser regenerado em Configurações > API. O Pipedrive permite um token ativo por vez — ao trocar, atualizar o `.env` do n8n.

## 2. Funis e etapas

| Funil | ID | Etapa | ID | Prob. | Rot |
| --- | --- | --- | --- | --- | --- |
| 01 - Prospecção | 2 | Lista de Prospecção | 15 | 10% | 3 dias |
| | | Em Cadência | 16 | 20% | 25 dias |
| | | Qualificado - Formulário Preenchido | 17 | 40% | 5 dias |
| | | Diagnóstico Agendado | 26 | 60% | — |
| 02 - Fechamento | 4 | Diagnóstico & Proposta | 18 | 30% | 7 dias |
| | | Negociação & SLA | 19 | 60% | 10 dias |
| | | Onboarding | 20 | 100% | — |

Ganho e Perdido são **status** do negócio, não etapas.

## 3. Campos personalizados de Negócio

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

### IDs das opções

**Origem do Lead:** 96 LinkedIn · 97 E-mail · 98 Inbound Site · 99 Instagram · 100 WhatsApp direto · 101 Indicação

> Regra de preenchimento: o campo registra **onde o lead foi encontrado, não onde ele conversou**. Quem clicou no anúncio e mandou mensagem é Instagram. "WhatsApp direto" só para quem já tinha o número. Ver `COMERCIAL.md`, seção 7.2.

**ICP:** 102 A1 — Estética · 103 A2 — Odonto · 104 B — Advocacia · 105 Fora do ICP

**Rota Comercial:** 106 Rota 1 — Verta Start · 107 Rota 2 — Modular

## 4. Campo personalizado de Organização

| Nome | `key` | Tipo |
| --- | --- | --- |
| Faturamento Aproximado | `58f54ae6225863454cb946ba57f6c5a54ab5b712` | enum |

**Opções:** 108 Até R$ 15 mil · 109 R$ 15–100 mil · 110 R$ 100–500 mil · 111 Acima de R$ 500 mil

É contexto, **não critério de entrada**. O piso de faturamento foi eliminado na v4.0 do `COMERCIAL.md`.

## 5. Tipos de atividade

**A escrita exige a `key_string`, não o ID numérico.** `POST /activities` recusa o ID. O ID serve para leitura e filtro.

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

**Nativos (não excluir):** 1 Chamada `call` · 2 Reunião `meeting` · 3 Tarefa `task` · 4 Prazo `deadline` · 5 E-mail `email` · 6 Almoço `lunch`

Chamada e Reunião são usados pela sincronização com o Google Calendar. Almoço está marcado para desativação.

> As `key_string` dos nove tipos criados ainda **não foram levantadas**. Sem elas o Workflow 1 não consegue criar atividade. Levantar antes de rodar o prompt de cadência.

## 6. Etiquetas de Negócio

| ID | Nome | Situação |
| --- | --- | --- |
| 65 | Qualificado | manter |
| 66 | Incerto | manter |
| 67 | Sem fit | manter |
| 68 | Rota 1 (Start) | duplica o campo Rota Comercial — remover |
| 69 | Rota 2 (Modular) | duplica o campo Rota Comercial — remover |
| 70 | Origem: WhatsApp | duplica o campo Origem do Lead — remover |
| 71 | Origem: Typeform | duplica o campo Origem do Lead — remover |
| 72 | Origem: Calendly | duplica o campo Origem do Lead — remover |
| — | **Engajou** | **a criar** — sinal de engajamento lido pelo Workflow 3 |

Etiquetas de Pessoa (14–17) e Organização (10–13) são nativas do Pipedrive.

Duas fontes para o mesmo dado significam que uma fica desatualizada e ninguém sabe qual. Como o campo é o que entra em relatório, as etiquetas duplicadas saem.

## 7. Configurações sem endpoint de API

Feitas apenas pela interface:

1. **Motivos de perda** (lista obrigatória): IR inferior a 2 · Sem autoridade · No-show permanente · Perdido por preço · Silêncio · Processo caótico (Fundação recusada)
2. **Campos obrigatórios** para sair da etapa 17: Ticket Médio, Volume de Conversas/Mês, Índice de Recuperação
3. **Alerta de negócio sem atividade agendada**

> O `POST /dealFields` aceita os parâmetros `required_fields` e `important_fields`, que podem cobrir o item 2 por API. Não testado.

## 8. Supabase — esquema

Arquivos de migração: `001dicionariocrm.sql`, `002nucleorelacional.sql`.

**Núcleo relacional:** `organizations` é raiz absoluta; `contacts` é entidade filha única (substitui o par leads/client_contacts — o contato muda de `lifecycle_stage`, não de tabela, preservando o UUID); `deals` é entidade filha; `external_refs` é a ponte para IDs de CRM, com três FKs e CHECK em vez de polimórfico.

**Dicionário:** `crm_ref` guarda campo, opção, funil, etapa, tipo de atividade e etiqueta, com `provider` como coluna para o chassi rodar em clientes que usam outro CRM. A view `pipedrive_config` mantém compatibilidade com os workflows atuais e sai na Fase 3.

### Correções pendentes no esquema

| # | Item | Risco |
| --- | --- | --- |
| 1 | `contacts.telefone_e164` não é único | duas mensagens do mesmo número novo criam dois contatos |
| 2 | `pipedrive_config_bkp` herdou os grants antigos no rename | `anon` pode ter mantido select |
| 3 | View `pipedrive_config` sem `security_invoker` | fura o RLS ligado no `crm_ref` |
| 4 | Gatilho e RLS do `crm_ref` estão no 002, tabela nasce no 001 | rodar 001 sozinho deixa tabela sem toque nem RLS |
| 5 | `deals.stage` e `deals.motivo_perda` são texto livre | motivo escrito de duas formas vira duas categorias no relatório |
| 6 | Sem trava de cadeia de merge (A→B→C) | resolução por `merged_into_id` quebra em um salto |

## 9. Infraestrutura

**No ar:** VPS com Docker, Traefik v2.11 (fixo — v3.x não negocia a API do Docker em certas VPS), n8n self-hosted, PostgreSQL interno, Supabase, container de embeddings BGE-M3.

**Variáveis exigidas no container:** `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`, `NODE_FUNCTION_ALLOW_BUILTIN=crypto`, `PIPEDRIVE_API_TOKEN`, `DISCORD_WEBHOOK_CADENCIA`.

**Pendências de go-live** (`ARQUITETURA.md`, seção 4): rotina de backup, custódia da `N8N_ENCRYPTION_KEY` em cofre, primeiro teste de restauração.

## 10. Ferramentas — estado atual

| Função | Ferramenta | Situação |
| --- | --- | --- |
| CRM | Pipedrive | configurado e auditado |
| Agendamento | Calendly | criado; falta corrigir acento, duração 45min e remover perguntas de qualificação |
| Transbordo e alertas | Discord | canal único; Telegram descontinuado |
| Formulário | Tally (sugerido) | **não existe** — é o gargalo da porta de entrada |
| Site | Webflow | copy e wireframe prontos; não publicado |
| Lista de prospecção | Google Places API | escolhido; Apollo bloqueia busca de pessoas no plano gratuito e tem cobertura rasa de PME brasileira |
| Automação no LinkedIn | — | **proibida.** Quatro dos seis toques passam por lá; bloqueio de perfil encerra o canal |

## 11. Registros internos no Pipedrive

Organização 32 "Verta", negócio 71, pessoa 69 "Michael Jordan", atividade 84 "Diagnóstico (Meet) — Verta (teste)". São cadastro da própria Verta. Marcar como interno para não gerar alerta falso na auditoria diária de espelhamento — mesmo papel do `is_internal` no Supabase.
