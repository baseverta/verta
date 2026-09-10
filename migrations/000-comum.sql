-- =====================================================================
-- Verta — 000 — Objetos comuns
--
-- Roda antes de tudo. A função de toque vive aqui porque é usada por
-- gatilhos de 001 e 002: deixá-la em 002, como estava, significava que
-- rodar 001 sozinho — ou 002 falhar e voltar atrás — deixava crm_ref
-- sem updated_at e sem RLS, silenciosamente.
-- =====================================================================

create or replace function public.tocar_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

comment on function public.tocar_updated_at() is
  'Mantém updated_at. Cada tabela liga o próprio gatilho no mesmo arquivo em que é criada.';
