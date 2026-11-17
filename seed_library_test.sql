-- =====================================================================
-- seed_library_test.sql
-- Test data for the library usability test.
--
-- Adds (only if missing):
--   * category  'Buku'
--   * 2 line locations (borrow destinations): RUANG BACA, DIBAWA PULANG
--   * 9 rack locations (return locations):    RAK A1 .. RAK C3
--   * 20 books LIB-BK-001 .. LIB-BK-020, status 'available', each on a rack
--   * 2 test users: UJI001 (operator), UJI002 (viewer)
--
-- Safe to run more than once: every insert skips rows that already exist
-- (matched by category name, location code, QR code, or badge ID).
-- Existing rows are never updated or deleted. Use reset_library_test.sql
-- to put the 20 test books back to their starting state.
--
-- Run in: Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Category
-- ---------------------------------------------------------------------
insert into public.item_categories (name, is_active)
select 'Buku', true
where not exists (
  select 1 from public.item_categories where lower(name) = lower('Buku')
);

-- ---------------------------------------------------------------------
-- 2. Locations
--    line = borrow destination, rack = return location
-- ---------------------------------------------------------------------
insert into public.allowed_locations (code, location_type, is_active)
select v.code, v.location_type, true
from (
  values
    ('RUANG BACA',    'line'),
    ('DIBAWA PULANG', 'line'),
    ('RAK A1', 'rack'),
    ('RAK A2', 'rack'),
    ('RAK A3', 'rack'),
    ('RAK B1', 'rack'),
    ('RAK B2', 'rack'),
    ('RAK B3', 'rack'),
    ('RAK C1', 'rack'),
    ('RAK C2', 'rack'),
    ('RAK C3', 'rack')
) as v(code, location_type)
where not exists (
  select 1 from public.allowed_locations l where upper(l.code) = upper(v.code)
);

-- ---------------------------------------------------------------------
-- 3. Books
--    The rack listed here is each book's "home" rack. reset_library_test.sql
--    uses the same list, so keep the two scripts in sync if you edit it.
-- ---------------------------------------------------------------------
insert into public.items (
  qr_code, name, category, current_status, current_location,
  last_borrower_name, expected_return_at, condition, notes,
  created_at, updated_at
)
select
  v.qr_code, v.title, 'Buku', 'available', v.rack,
  null, null, 'Baik', 'Penulis: ' || v.author,
  now(), now()
from (
  values
    ('LIB-BK-001', 'Laskar Pelangi',                    'Andrea Hirata',            'RAK A1'),
    ('LIB-BK-002', 'Sang Pemimpi',                      'Andrea Hirata',            'RAK A1'),
    ('LIB-BK-003', 'Bumi Manusia',                      'Pramoedya Ananta Toer',    'RAK A2'),
    ('LIB-BK-004', 'Anak Semua Bangsa',                 'Pramoedya Ananta Toer',    'RAK A2'),
    ('LIB-BK-005', 'Ronggeng Dukuh Paruk',              'Ahmad Tohari',             'RAK A3'),
    ('LIB-BK-006', 'Cantik Itu Luka',                   'Eka Kurniawan',            'RAK A3'),
    ('LIB-BK-007', 'Laut Bercerita',                    'Leila S. Chudori',         'RAK B1'),
    ('LIB-BK-008', 'Pulang',                            'Leila S. Chudori',         'RAK B1'),
    ('LIB-BK-009', 'Negeri 5 Menara',                   'Ahmad Fuadi',              'RAK B2'),
    ('LIB-BK-010', 'Perahu Kertas',                     'Dee Lestari',              'RAK B2'),
    ('LIB-BK-011', 'Gadis Kretek',                      'Ratih Kumala',             'RAK B3'),
    ('LIB-BK-012', 'Saman',                             'Ayu Utami',                'RAK B3'),
    ('LIB-BK-013', 'Siti Nurbaya',                      'Marah Rusli',              'RAK C1'),
    ('LIB-BK-014', 'Layar Terkembang',                  'Sutan Takdir Alisjahbana', 'RAK C1'),
    ('LIB-BK-015', 'Tenggelamnya Kapal Van der Wijck',  'Hamka',                    'RAK C2'),
    ('LIB-BK-016', 'Atheis',                            'Achdiat K. Mihardja',      'RAK C2'),
    ('LIB-BK-017', 'Burung-Burung Manyar',              'Y.B. Mangunwijaya',        'RAK C3'),
    ('LIB-BK-018', 'Hujan',                             'Tere Liye',                'RAK C3'),
    ('LIB-BK-019', 'Ayat-Ayat Cinta',                   'Habiburrahman El Shirazy', 'RAK A1'),
    ('LIB-BK-020', 'Filosofi Teras',                    'Henry Manampiring',        'RAK B2')
) as v(qr_code, title, author, rack)
where not exists (
  select 1 from public.items i where upper(i.qr_code) = upper(v.qr_code)
);

-- ---------------------------------------------------------------------
-- 4. Test users
--    Passwords are plain text because the app currently uses its own
--    badge/password login (see supabase_security_baseline.sql).
--    Change them later in the app (Pengguna page) or in Table Editor.
-- ---------------------------------------------------------------------
insert into public.app_users (name, badge_id, password, role, is_active)
select v.name, v.badge_id, v.password, v.role, true
from (
  values
    ('Petugas Uji',  'UJI001', 'uji12345', 'operator'),
    ('Pengawas Uji', 'UJI002', 'uji12345', 'viewer')
) as v(name, badge_id, password, role)
where not exists (
  select 1 from public.app_users u where upper(u.badge_id) = upper(v.badge_id)
);

commit;

-- ---------------------------------------------------------------------
-- Check the result (read-only).
-- ---------------------------------------------------------------------
select 'items' as table_name, count(*) as rows
  from public.items where qr_code like 'LIB-BK-%'
union all
select 'allowed_locations', count(*)
  from public.allowed_locations
  where code in ('RUANG BACA', 'DIBAWA PULANG', 'RAK A1', 'RAK A2', 'RAK A3',
                 'RAK B1', 'RAK B2', 'RAK B3', 'RAK C1', 'RAK C2', 'RAK C3')
union all
select 'item_categories', count(*)
  from public.item_categories where name = 'Buku'
union all
select 'app_users', count(*)
  from public.app_users where badge_id in ('UJI001', 'UJI002');
-- Expected: items 20, allowed_locations 11, item_categories 1, app_users 2
