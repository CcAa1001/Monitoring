-- =====================================================================
-- reset_library_test.sql
-- Puts the 20 library test books (LIB-BK-001 .. LIB-BK-020) back to their
-- starting state between usability-test sessions.
--
-- For those 20 books only:
--   * deletes their rows in movements
--   * deletes their rows in audit_logs (entity_type = 'item')
--   * sets status 'available', moves them back to their home rack,
--     clears the borrower and the due date
--
-- Does NOT touch any other item, movement, audit row, location, category
-- or user. Books that do not exist are simply skipped. Safe to run
-- repeatedly.
--
-- Run in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- =====================================================================

begin;

-- Home rack per test book. Must match the list in seed_library_test.sql.
create temporary table _lib_test_books (qr_code text primary key, rack text not null)
on commit drop;

insert into _lib_test_books (qr_code, rack) values
  ('LIB-BK-001', 'RAK A1'),
  ('LIB-BK-002', 'RAK A1'),
  ('LIB-BK-003', 'RAK A2'),
  ('LIB-BK-004', 'RAK A2'),
  ('LIB-BK-005', 'RAK A3'),
  ('LIB-BK-006', 'RAK A3'),
  ('LIB-BK-007', 'RAK B1'),
  ('LIB-BK-008', 'RAK B1'),
  ('LIB-BK-009', 'RAK B2'),
  ('LIB-BK-010', 'RAK B2'),
  ('LIB-BK-011', 'RAK B3'),
  ('LIB-BK-012', 'RAK B3'),
  ('LIB-BK-013', 'RAK C1'),
  ('LIB-BK-014', 'RAK C1'),
  ('LIB-BK-015', 'RAK C2'),
  ('LIB-BK-016', 'RAK C2'),
  ('LIB-BK-017', 'RAK C3'),
  ('LIB-BK-018', 'RAK C3'),
  ('LIB-BK-019', 'RAK A1'),
  ('LIB-BK-020', 'RAK B2');

-- 1. Movements of the test books only.
delete from public.movements m
using public.items i, _lib_test_books t
where m.item_id = i.id
  and upper(i.qr_code) = t.qr_code;

-- 2. Audit rows of the test books only (skipped if audit_logs does not exist yet).
do $$
begin
  if to_regclass('public.audit_logs') is not null then
    delete from public.audit_logs a
    using public.items i, _lib_test_books t
    where a.entity_type = 'item'
      and a.entity_id = i.id::text
      and upper(i.qr_code) = t.qr_code;
  end if;
end
$$;

-- 3. Back to available, on the home rack, no borrower, no due date.
update public.items i
set current_status     = 'available',
    current_location   = t.rack,
    last_borrower_name = null,
    expected_return_at = null,
    updated_at         = now()
from _lib_test_books t
where upper(i.qr_code) = t.qr_code;

commit;

-- Check the result (read-only). Expected: 20 rows, all 'available', borrower empty.
select qr_code, name, current_status, current_location, last_borrower_name, expected_return_at
from public.items
where qr_code like 'LIB-BK-%'
order by qr_code;
