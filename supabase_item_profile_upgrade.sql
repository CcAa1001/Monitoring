-- Run this in Supabase SQL Editor before deploying the item profile upgrade.
-- It is safe to run repeatedly because every column addition is guarded.

alter table public.items
  add column if not exists serial_number text,
  add column if not exists brand text,
  add column if not exists model text,
  add column if not exists condition text,
  add column if not exists image_url text,
  add column if not exists manual_url text,
  add column if not exists notes text,
  add column if not exists expected_return_at timestamptz;

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_name text,
  action text not null,
  entity_type text not null,
  entity_id text,
  summary text,
  created_at timestamptz not null default now()
);

alter table public.audit_logs enable row level security;

-- Current app login is still app-level, not Supabase Auth.
-- This policy lets the deployed client append audit events, but does not allow
-- public users to update or delete audit rows.
drop policy if exists "App clients can append audit logs" on public.audit_logs;
create policy "App clients can append audit logs"
on public.audit_logs
for insert
to anon, authenticated
with check (true);

drop policy if exists "Authenticated users can read audit logs" on public.audit_logs;
create policy "Authenticated users can read audit logs"
on public.audit_logs
for select
to authenticated
using (true);
