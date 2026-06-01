-- Security baseline notes for the next production pass.
-- Do not run blindly on a live project without checking policies in Supabase first.
-- This file documents the intended direction while the app still uses custom app_users login.

-- 1. Check public tables that still need RLS.
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by tablename;

-- 2. After Supabase Auth migration, every exposed table should have RLS enabled.
-- alter table public.items enable row level security;
-- alter table public.movements enable row level security;
-- alter table public.allowed_locations enable row level security;
-- alter table public.item_categories enable row level security;
-- alter table public.app_users enable row level security;
-- alter table public.pairing_sessions enable row level security;

-- 3. The app should move sensitive writes to Supabase Auth + RLS or Edge Functions.
-- Current custom badge/password login is still an app-level compatibility layer.
