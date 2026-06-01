# Production readiness roadmap

This app is moving from a demo-capable equipment tracker into an operations system. The code now supports richer item profiles, reporting exports, overdue visibility, and stronger transaction feedback. The remaining security work needs database and policy changes in Supabase.

## Supabase security checklist

1. Enable RLS on every public table exposed through PostgREST.
2. Move login to Supabase Auth or a server-side Edge Function.
3. Stop comparing plain-text passwords from the Flutter client.
4. Separate read policies from write policies.
5. Restrict write policies by role after the app has a trusted auth identity.
6. Keep `anon` policies read-only unless the table is intentionally public.
7. Add audit logging for item, category, location, user, and role changes.

## Suggested table policy direction

Use this as the target shape after migrating authentication:

- `items`: authenticated users can read; admins can create/update/delete; operators can update status through transaction functions.
- `movements`: authenticated users can read; inserts should happen through trusted transaction functions.
- `app_users`: admins can manage; users can read only their own profile.
- `item_categories`: authenticated users can read; admins can manage.
- `allowed_locations`: authenticated users can read; admins can manage.
- `pairing_sessions`: authenticated users can create/read/update only active sessions they own.
- `audit_logs`: authenticated users can read; inserts should happen through trusted functions.

## Architecture direction

- Keep `InventoryRepository` as the UI-facing contract.
- Split implementation behind it into smaller services over time: auth, items, movements, pairing, admin, and reporting.
- Prefer server-side functions for sensitive write operations once Supabase Auth is active.
- Add widget tests around borrow/return queue behavior before further transaction refactors.
