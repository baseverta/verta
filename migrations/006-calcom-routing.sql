begin;

-- ---------------------------------------------------------------------
-- ROTEAMENTO CAL.COM POR LEAD
-- ---------------------------------------------------------------------
-- Liga um token único a um negócio Pipedrive/Supabase para rastrear
-- qual link de qualificação e agendamento pertence a qual lead.
-- ---------------------------------------------------------------------

create table if not exists public.calcom_routing (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  deal_id         uuid not null references public.deals (id) on delete cascade,
  external_id     bigint not null,  -- Pipedrive deal id, cacheado para evitar join no webhook
  token           uuid not null unique default gen_random_uuid(),
  contact_email   text,
  contact_phone   text,
  contact_name    text,
  org_name        text,
  icp_approved    boolean,
  calcom_link     text,
  booking_id      text,
  booking_start   timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  expires_at      timestamptz not null default (now() + interval '7 days')
);

create index if not exists idx_calcom_routing_organization_id on public.calcom_routing (organization_id);
create index if not exists idx_calcom_routing_deal_id         on public.calcom_routing (deal_id);
create index if not exists idx_calcom_routing_external_id     on public.calcom_routing (external_id);
create index if not exists idx_calcom_routing_token           on public.calcom_routing (token);
create index if not exists idx_calcom_routing_contact_email   on public.calcom_routing (contact_email);

create trigger calcom_routing_touch
  before update on public.calcom_routing
  for each row execute function public.tocar_updated_at ();

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------

alter table public.calcom_routing enable row level security;

revoke all on public.calcom_routing from anon;

grant select, insert, update, delete on public.calcom_routing to service_role;

commit;
