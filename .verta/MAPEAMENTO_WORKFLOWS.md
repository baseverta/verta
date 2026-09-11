# Mapeamento de Workflows n8n - Verta

## Visão geral

```text
Pipedrive (CRM humano)
  |
  | webhooks
  v
n8n workflows inbound  ---->  Supabase (fonte de verdade)
  |                                |
  |                                | triggers + outbox
  |                                v
  |                         n8n CRON outbound
  |                                |
  |                                v
  +--------------------------> Pipedrive
```

## Workflows existentes e função

### Sincronização (criados/ativados nesta sessão)

| Workflow | Trigger | Função | Destino no Supabase |
| --- | --- | --- | --- |
| `WEB - Pipedrive - SincronizarOrganizacao` | `change.organization` | Cria/atualiza empresa | `organizations` + `external_refs` |
| `WEB - Pipedrive - SincronizarContato` | `change.person` | Cria/atualiza contato | `contacts` + `external_refs` |
| `WEB - Pipedrive - SincronizarNegocio` | `change.deal` | Cria/atualiza negócio | `deals` + `external_refs` |
| `CRON - CRM - SincronizarOutbox` | a cada 1 minuto | Processa `crm_sync_outbox` | Pipedrive (atualiza/cria) |

### Cadência e prospecção (já existiam)

| Workflow | Trigger | Função | Dependência do sync |
| --- | --- | --- | --- |
| `WEB - Pipedrive - CriarCadencia` | `change.deal` (entra em `STAGE_EM_CADENCIA`) | Cria atividades T1-T4 no Pipedrive | Precisa do `deal_id`, `org_id`, `person_id` (agora vêm do webhook) |
| `WEB - Pipedrive - AvancarCadencia` | `change.activity` (atividade concluída) | Cria T5 ou T6, ou marca como perdido | Precisa de `label_ids` do negócio; mantém GET no Pipedrive |
| `CRON - Pipedrive - AgendaDoDia` | 07h dias úteis | Monta agenda do dia e posta no Discord | Só lê `pipedrive_config` + atividades do Pipedrive |
| `01 - Captura e Extracao de Pautas` | Telegram | Captura e extrai pautas com IA | Escreve/ler do Postgres interno (não conflita com sync) |
| `SUB - Global - TratamentoErro` | `errorTrigger` | Envia falhas no Discord | Recebe erros de todos os workflows |

## Dependências de dados

### `pipedrive_config` (Supabase)

Lida por quase todos os workflows antigos. Contém mapeamentos de IDs opacos do Pipedrive:

- `STAGE_EM_CADENCIA`
- `ATIVIDADE_T1`..`ATIVIDADE_T6`
- `LABEL_ENGAJOU`

Sempre que um ID mudar no Pipedrive, `pipedrive_config` deve ser atualizada para evitar quebra.

### `organizations`, `contacts`, `deals` (Supabase)

Novas tabelas populadas pelos workflows de sincronização. Futuramente podem alimentar os workflows de cadência, reduzindo chamadas ao Pipedrive.

## Otimizações aplicadas

### `WEB - Pipedrive - CriarCadencia`

1. **Removido** nó `GET Pipedrive - Buscar Negocio` redundante.
   - O webhook `change.deal` já entrega `id`, `title`, `org_id` e `person_id` no payload.
   - Isso elimina **uma chamada por deal** que entra em cadência.
2. **Substituído** `GET Pipedrive - Buscar Organizacao` por `GET Supabase - Buscar Nome Organizacao`.
   - Busca o nome da organização em `external_refs` com `organizations!inner(nome)`.
   - Se ainda não estiver sincronizada, faz fallback para `negocio.title`.
   - Elimina **mais uma chamada ao Pipedrive** por execução.

### `WEB - Pipedrive - AvancarCadencia`

1. **Substituído** `GET Pipedrive - Buscar Organizacao` por `GET Supabase - Buscar Nome Organizacao`.
   - Mesma query do Supabase, eliminando chamada ao Pipedrive.
   - Fallback para `negocio.title` quando o sync ainda não chegou.
2. **Mantido** `GET Pipedrive - Buscar Negocio`.
   - Webhook `change.activity` não traz `label_ids` do negócio; precisa buscar no Pipedrive.

## Validação

Foram criados deals de teste e movidos para `STAGE_EM_CADENCIA` (id `16`).

- `CriarCadencia` executou com `success` e criou T1-T4.
- `AvancarCadencia` executou com `success` ao concluir T4 e criou T6 (sem label de engajamento).
- Dados de teste foram removidos dos dois lados.

## Otimizações futuras recomendadas

1. **`AgendaDoDia`:**
   - Atividades poderiam ser pre-buscadas no Supabase se uma rotina de sync de atividades for criada no futuro.

2. **Cache de `pipedrive_config`:**
   - Considerar workflow separado que armazena a config no `staticData` do n8n ou em Redis para reduzir uma chamada por execução.

3. **Supabase como trigger da cadência:**
   - No futuro, os workflows `CriarCadencia` e `AvancarCadencia` poderiam ser disparados por triggers nas tabelas `deals`/`activities` do Supabase, eliminando a dependência de webhooks do Pipedrive e garantindo que os dados da org já estejam disponíveis.
