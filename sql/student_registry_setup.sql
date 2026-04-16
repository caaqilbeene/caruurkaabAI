-- Student Registry Setup
-- Run in Supabase SQL Editor (one time)

-- 1) Table + sequence for unique, non-reusable Student IDs
create sequence if not exists public.student_registry_no_seq start 1;

create table if not exists public.student_registry (
  user_id text primary key,
  email text,
  full_name text,
  student_no bigint unique not null default nextval('public.student_registry_no_seq'),
  joined_at timestamp with time zone not null default now(),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- 2) Safe upgrades if table already existed
alter table public.student_registry add column if not exists email text;
alter table public.student_registry add column if not exists full_name text;
alter table public.student_registry add column if not exists student_no bigint;
alter table public.student_registry add column if not exists joined_at timestamp with time zone default now();
alter table public.student_registry add column if not exists created_at timestamp with time zone default now();
alter table public.student_registry add column if not exists updated_at timestamp with time zone default now();

alter table public.student_registry
  alter column student_no set default nextval('public.student_registry_no_seq');

update public.student_registry
set student_no = nextval('public.student_registry_no_seq')
where student_no is null;

alter table public.student_registry
  alter column student_no set not null;

create unique index if not exists student_registry_student_no_uq
  on public.student_registry(student_no);

create unique index if not exists student_registry_email_uq
  on public.student_registry(lower(email))
  where email is not null;

select setval(
  'public.student_registry_no_seq',
  coalesce((select max(student_no) from public.student_registry), 0),
  true
);

-- 3) Auto update updated_at
create or replace function public.student_registry_set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists student_registry_set_updated_at on public.student_registry;
create trigger student_registry_set_updated_at
before update on public.student_registry
for each row
execute function public.student_registry_set_updated_at();

-- 4) RLS policies
alter table public.student_registry enable row level security;

drop policy if exists "student_registry_read_all" on public.student_registry;
drop policy if exists "student_registry_insert_all" on public.student_registry;
drop policy if exists "student_registry_update_all" on public.student_registry;
drop policy if exists "student_registry_delete_all" on public.student_registry;

create policy "student_registry_read_all"
  on public.student_registry for select using (true);

create policy "student_registry_insert_all"
  on public.student_registry for insert with check (true);

create policy "student_registry_update_all"
  on public.student_registry for update using (true);

create policy "student_registry_delete_all"
  on public.student_registry for delete using (true);

-- 5) Optional seed for existing users (edit emails first, then run once)
-- IMPORTANT:
-- - user_id should match app key (email lowercase).
-- - Geeddi114 intentionally excluded as requested.
-- - If rows already exist, this block updates them.
insert into public.student_registry (user_id, email, full_name, student_no, joined_at)
values
  ('caaqilbeene@hotmail.com', 'caaqilbeene@hotmail.com', 'Mohamed Ali', 1, '2026-03-27T00:00:00Z'),
  ('maxkayare2060@gmail.com', 'maxkayare2060@gmail.com', null, 2, '2026-04-02T00:00:00Z'),
  ('mohamedaqadira@gmail.com', 'mohamedaqadira@gmail.com', null, 3, '2026-04-02T00:00:00Z'),
  ('abdirahmanaliabdulle8@gmail.com', 'abdirahmanaliabdulle8@gmail.com', null, 4, '2026-03-30T00:00:00Z'),
  ('dacad6217@gmail.com', 'dacad6217@gmail.com', null, 5, '2026-03-30T00:00:00Z')
on conflict (user_id)
do update set
  email = excluded.email,
  full_name = coalesce(excluded.full_name, public.student_registry.full_name),
  student_no = excluded.student_no,
  joined_at = excluded.joined_at;

select setval(
  'public.student_registry_no_seq',
  coalesce((select max(student_no) from public.student_registry), 0),
  true
);
