# Verta System Architecture Diagram

## Overview
Verta is an automated lead qualification and CRM integration platform that connects WhatsApp messaging, AI-powered conversation handling, and CRM synchronization (primarily Pipedrive). The system is designed to eliminate manual response delays and maintain accurate pipeline data.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          External Systems                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  WhatsApp    │  │  Pipedrive   │  │   Google     │  │   Discord    │  │
│  │  Cloud API   │  │     CRM      │  │  Workspace   │  │   (Handoff)  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │                 │           │
└─────────┼─────────────────┼─────────────────┼─────────────────┼───────────┘
          │                 │                 │                 │
          │ Webhooks        │ Webhooks        │ Pub/Sub         │ Webhooks   │
          │                 │                 │ Events          │            │
┌─────────┼─────────────────┼─────────────────┼─────────────────┼───────────┐
│         ▼                 ▼                 ▼                 ▼           │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                        Traefik Proxy (v2.11)                        │  │
│  │                   SSL Termination (Let's Encrypt)                    │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                       │
│                    ┌───────────────┴───────────────┐                       │
│                    │      Docker Networks          │                       │
│                    ├───────────────┬───────────────┤                       │
│                    │   proxy       │   internal    │                       │
│                    │  (external)  │  (isolated)   │                       │
│                    └───────────────┴───────────────┘                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                   │
┌──────────────────────────────────┼──────────────────────────────────────────┐
│                                  ▼                                          │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                           n8n Automation Engine                        │  │
│  │  ┌────────────────────────────────────────────────────────────────┐  │  │
│  │  │ Core Workflows:                                                │  │  │
│  │  │ • WEB - WhatsApp - InboundQualificacao (Main motor)           │  │  │
│  │  │ • SUB - Global - TratamentoErro (Error handling)              │  │  │
│  │  │ • CRON - Calendly - LembreteDiagnostico (No-show reduction)   │  │  │
│  │  │ • WEB - Meta - StatusMensagem (Message status updates)        │  │  │
│  │  │ • WEB - Pipedrive - CriarCadencia (Outbound cadence)         │  │  │
│  │  │ • CRON - Pipedrive - AgendaDoDia (Daily agenda)              │  │  │
│  │  │ • WEB - Pipedrive - AvancarCadencia (Cadence progression)     │  │  │
│  │  └────────────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                       │
│                    ┌───────────────┴───────────────┐                       │
│                    │                               │                       │
┌───────────────────┼───────────────────────────────┼───────────────────────┐
│                   ▼                               ▼                       │
│  ┌─────────────────────────┐         ┌─────────────────────────┐         │
│  │   Supabase (Cloud)      │         │  PostgreSQL (Internal)  │         │
│  │  ┌───────────────────┐  │         │  ┌───────────────────┐  │         │
│  │  │ Source of Truth   │  │         │  │ n8n Internal DB   │  │         │
│  │  │                   │  │         │  │                   │  │         │
│  │  │ • organizations   │  │         │  │ • Workflows       │  │         │
│  │  │ • contacts        │  │         │  │ • Credentials     │  │         │
│  │  │ • deals           │  │         │  │ • Execution data  │  │         │
│  │  │ • external_refs   │  │         │  │                   │  │         │
│  │  │ • crm_ref         │  │         │  └───────────────────┘  │         │
│  │  │ • wa_sessions     │  │         │                           │         │
│  │  │ • embeddings      │  │         │                           │         │
│  │  └───────────────────┘  │         │                           │         │
│  └─────────────────────────┘         └─────────────────────────┘         │
│                                                                           │
│  ┌─────────────────────────┐         ┌─────────────────────────┐         │
│  │  Evolution API (WhatsApp)│       │  Embeddings Server      │         │
│  │  ┌───────────────────┐  │         │  ┌───────────────────┐  │         │
│  │  │ WhatsApp Gateway  │  │         │  │ BGE-M3 Model      │  │         │
│  │  │ • Sessions        │  │         │  │ Self-hosted       │  │         │
│  │  │ • Messages        │  │         │  │ Vector generation  │  │         │
│  │  │ • Webhooks        │  │         │  │ • Knowledge base   │  │         │
│  │  └───────────────────┘  │         │  │ • Semantic search  │  │         │
│  └─────────────────────────┘         │  └───────────────────┘  │         │
│                                      └─────────────────────────┘         │
│                                                                           │
│  ┌─────────────────────────┐         ┌─────────────────────────┐         │
│  │       Redis             │         │    Uptime Kuma          │         │
│  │  ┌───────────────────┐  │         │  ┌───────────────────┐  │         │
│  │  │ Caching Layer      │  │         │  │ Monitoring        │  │         │
│  │  │ • Session data     │  │         │  │ • Health checks   │  │         │
│  │  │ • Rate limiting    │  │         │  │ • SLA compliance  │  │         │
│  │  └───────────────────┘  │         │  │ • Alerting        │  │         │
│  └─────────────────────────┘         │  └───────────────────┘  │         │
│                                      └─────────────────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

### 1. Lead Ingestion Flow
```
┌──────────────┐
│  WhatsApp    │
│  Message     │
└──────┬───────┘
       │ Webhook
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ Evolution API → n8n: WEB - WhatsApp - InboundQualificacao      │
├─────────────────────────────────────────────────────────────────┤
│ 1. Receive webhook with message data                            │
│ 2. Check existing session in Supabase (wa_sessions)             │
│ 3. If new session: find_or_create_organization + contact       │
│ 4. Generate embedding via Embeddings Server                     │
│ 5. Search knowledge base for relevant context                   │
│ 6. Call AI (Claude/GPT) for response generation                 │
│ 7. Update wa_sessions with conversation context                 │
│ 8. Send response via Evolution API                              │
│ 9. Mirror data to Pipedrive (async)                             │
└─────────────────────────────────────────────────────────────────┘
       │
       ├──► Supabase (organizations, contacts, wa_sessions)
       ├──► Pipedrive (organizations, persons, deals)
       └──► Discord (if human_takeover = true)
```

### 2. CRM Mirror Flow
```
┌─────────────────────────────────────────────────────────────────┐
│ Supabase (Source of Truth)                                      │
├─────────────────────────────────────────────────────────────────┤
│ • organizations: All business entities                           │
│ • contacts: Individual people linked to organizations           │
│ • deals: Commercial opportunities with stages                    │
│ • external_refs: Mapping to external system IDs                 │
└─────────────────────────────────────────────────────────────────┘
       │
       │ n8n workflows sync changes
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ Pipedrive (Human Interface)                                      │
├─────────────────────────────────────────────────────────────────┤
│ • Organizations mirror: business entity data                   │
│ • Persons mirror: contact information                            │
│ • Deals mirror: pipeline stages and values                       │
│ • Activities: automated cadence tasks                           │
└─────────────────────────────────────────────────────────────────┘
```

### 3. Outbound Cadence Flow
```
┌─────────────────────────────────────────────────────────────────┐
│ Pipedrive: Deal enters "Em Cadencia" stage (stage_id = 16)      │
└─────────────────────────────────────────────────────────────────┘
       │ Webhook: deal.updated
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ n8n: WEB - Pipedrive - CriarCadencia                             │
├─────────────────────────────────────────────────────────────────┤
│ 1. Validate payload (stage change to 16)                         │
│ 2. Check if T1 activity already exists (idempotency)            │
│ 3. Calculate business days for T1-T4                            │
│ 4. Create activities:                                            │
│    • T1 (Today): LinkedIn comment                                │
│    • T2 (+2 days): LinkedIn connection request                   │
│    • T3 (+3 days): Email opening                                 │
│    • T4 (+8 days): Value add content                             │
│ 5. Log to Discord for visibility                                 │
└─────────────────────────────────────────────────────────────────┘
       │
       ├──► Pipedrive (activities created)
       └──► Discord (confirmation log)
```

### 4. Cadence Progression Flow
```
┌─────────────────────────────────────────────────────────────────┐
│ Pipedrive: Activity marked as done                               │
└─────────────────────────────────────────────────────────────────┘
       │ Webhook: activity.updated
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ n8n: WEB - Pipedrive - AvancarCadencia                            │
├─────────────────────────────────────────────────────────────────┤
│ 1. Validate: activity done = true, type = T4 or T6               │
│ 2. If T4 completed:                                               │
│    • Check for "Engajou" label                                   │
│    • If engaged: Create T5 (+2 business days)                    │
│    • Notify Discord of engagement                                 │
│ 3. If T6 completed:                                               │
│    • Check for late engagement                                    │
│    • If CADENCIA_MARCAR_PERDIDO = true: Mark deal as lost        │
│    • Notify Discord of break-up                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 5. Human Handoff Flow
```
┌─────────────────────────────────────────────────────────────────┐
│ AI Decision Conditions:                                           │
│ • Turn limit reached                                              │
│ • User requests human                                            │
│ • Intent uncertain                                                │
└─────────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ n8n: Set human_takeover = true in wa_sessions                     │
└─────────────────────────────────────────────────────────────────┘
       │
       ├──► Discord: Create thread in #transbordo channel
       │    • Lead name and phone
       │    • Qualification summary
       │    • Last message received
       │
       └──► WhatsApp: AI stops responding
```

## Database Schema Architecture

### Supabase (Source of Truth)
```
organizations (ROOT ENTITY)
├── id (UUID, PK)
├── nome (text)
├── status (enum: unidentified, prospect, client, churned)
├── cnpj (text, validated)
├── drive_folder_id (text)
├── drive_file_ids (jsonb)
├── merged_into_id (UUID, self-ref)
├── is_internal (boolean)
└── timestamps

contacts (CHILD ENTITY)
├── id (UUID, PK)
├── organization_id (UUID, FK → organizations)
├── nome (text)
├── lifecycle_stage (enum: lead, qualificado, cliente, perdido)
├── telefone_e164 (text, validated)
├── email (text)
├── cargo (text)
├── is_internal (boolean)
└── timestamps

deals (CHILD ENTITY)
├── id (UUID, PK)
├── organization_id (UUID, FK → organizations)
├── primary_contact_id (UUID, FK → contacts)
├── titulo (text)
├── pipeline (enum: prospeccao, fechamento)
├── stage (text, validated per pipeline)
├── valor (numeric)
├── status (enum: aberto, ganho, perdido)
├── motivo_perda (enum, validated)
└── timestamps

external_refs (MAPPING TABLE)
├── id (UUID, PK)
├── provider (text: pipedrive, hubspot, etc.)
├── entidade (enum: organization, contact, deal)
├── external_id (text)
├── organization_id (UUID, FK, conditional)
├── contact_id (UUID, FK, conditional)
├── deal_id (UUID, FK, conditional)
└── timestamps

crm_ref (CRM DICTIONARY)
├── id (UUID, PK)
├── provider (text)
├── tipo (enum: campo, opcao, pipeline, etapa, tipo_atividade, etiqueta)
├── chave (text, human-readable)
├── external_key (text, CRM hash)
├── valor_id (bigint, numeric ID)
├── valor_texto (text, string key for writes)
├── entidade (enum: deal, organization, person, activity)
├── parent_id (UUID, FK → crm_ref, for options)
└── timestamps
```

## Network Architecture

### Docker Networks
```
proxy (external network)
├── Traefik (exposed: 80, 443)
├── n8n (exposed via Traefik)
└── Evolution API (exposed: 127.0.0.1:8082:8080)

internal (isolated network - no internet access)
├── PostgreSQL (n8n internal DB)
├── Embeddings Server (BGE-M3 model)
└── Redis (caching)
```

### Security Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│ Security Layers                                                   │
├─────────────────────────────────────────────────────────────────┤
│ 1. Traefik: SSL termination, HTTP→HTTPS redirect                │
│ 2. Network isolation: internal network has no internet access   │
│ 3. Webhook validation: Signature verification (Typeform/Cal.com)  │
│ 4. Basic Auth: Pipedrive webhooks                                │
│ 5. Row Level Security: Supabase RLS policies                     │
│ 6. Service role: n8n uses service_role for database access      │
│ 7. Environment variables: All secrets in .env files               │
│ 8. Multi-tenant isolation: Container prefixes per client         │
└─────────────────────────────────────────────────────────────────┘
```

## Business Logic Flow

### Qualification Process
```
Lead Entry (WhatsApp/Typeform/Inbound)
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Initial Assessment                                                │
├─────────────────────────────────────────────────────────────────┤
│ • Ticket médio ≥ R$ 200?                                         │
│ • Volume ≥ 40 conversas/mês?                                     │
│ • Decision maker or direct access?                               │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼ Yes
┌─────────────────────────────────────────────────────────────────┐
│ Índice de Recuperação (IR) Calculation                           │
├─────────────────────────────────────────────────────────────────┤
│ IR = (leads_perdidos × ticket_medio × 20%) ÷ custo_verta         │
│                                                                 │
│ IR ≥ 4: Verde (Strong fit)                                      │
│ IR 2-4: Amarelo (Moderate fit, limited scope)                    │
│ IR < 2: Vermelho (No fit, disqualify)                            │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼ IR ≥ 2
┌─────────────────────────────────────────────────────────────────┐
│ Qualification Form → Calendly → Diagnosis Call → Proposal       │
└─────────────────────────────────────────────────────────────────┘
```

### Sales Funnel Stages
```
1. Lead Mapeado → 2. Em Triagem → 3. Diagnóstico Agendado →
4. Diagnóstico Realizado → 5. Negociação → 6. Onboarding (Ganho)
```

## Monitoring & SLA

### Uptime Monitoring
```
Uptime Kuma
├── Checks n8n webhooks every 60s
├── Checks Supabase API every 60s
├── Alerts Discord #alertas-infra on failure
└── Generates monthly SLA reports
```

### Error Handling
```
SUB - Global - TratamentoErro
├── Catches errors from all workflows
├── Formats error logs with node names
├── Sends detailed alerts to engineering
└── Prevents cascade failures
```

### SLA Commitments
```
• Availability: 99% monthly (Verta layer only)
• Critical incident response: 4 business hours
• Non-critical adjustment: 2 business days
• Support window: Mon-Fri, 9h-18h (BRT)
```

## Key Design Principles

1. **Source of Truth**: Supabase is the single source of truth; Pipedrive is a mirror
2. **Isolation**: Multi-tenant isolation with container prefixes
3. **Portability**: No technical lock-in; full infrastructure handed over on termination
4. **Anti-Hardcoding**: CRM field hashes stored in crm_ref table, not in workflows
5. **Idempotency**: All workflows designed to handle duplicate events safely
6. **Error Isolation**: Error handling prevents cascade failures
7. **Audit Trail**: All changes tracked with timestamps and RLS policies
8. **Human Fallback**: Discord handoff for complex cases

## Technology Stack

- **Orchestration**: n8n (workflow automation)
- **Database**: Supabase (PostgreSQL) + PostgreSQL (internal)
- **WhatsApp**: Evolution API v2.3.7
- **AI/ML**: BGE-M3 (self-hosted embeddings), Claude/GPT (conversation)
- **Proxy**: Traefik v2.11 (SSL, routing)
- **Caching**: Redis 7
- **Monitoring**: Uptime Kuma
- **CRM**: Pipedrive (primary), extensible to HubSpot/RD Station
- **Calendar**: Google Workspace (Calendar, Meet)
- **Handoff**: Discord (threads)
- **Infrastructure**: Docker Compose, VPS hosting