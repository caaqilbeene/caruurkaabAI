-- Profile avatar sync (Supabase)
-- Run once in Supabase SQL Editor

create table if not exists public.user_profiles (
  user_id text primary key,
  avatar_url text,
  updated_at timestamp with time zone default now()
);

alter table public.user_profiles enable row level security;

drop policy if exists "user_profiles_read_all" on public.user_profiles;
drop policy if exists "user_profiles_insert_all" on public.user_profiles;
drop policy if exists "user_profiles_update_all" on public.user_profiles;

create policy "user_profiles_read_all"
  on public.user_profiles for select using (true);

create policy "user_profiles_insert_all"
  on public.user_profiles for insert with check (true);

create policy "user_profiles_update_all"
  on public.user_profiles for update using (true);

insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', true)
on conflict (id) do update set public = excluded.public;

alter table storage.objects enable row level security;

drop policy if exists "profile_images_read" on storage.objects;
drop policy if exists "profile_images_insert" on storage.objects;
drop policy if exists "profile_images_update" on storage.objects;
drop policy if exists "profile_images_delete" on storage.objects;

create policy "profile_images_read"
  on storage.objects for select
  using (bucket_id = 'profile-images');

create policy "profile_images_insert"
  on storage.objects for insert
  with check (bucket_id = 'profile-images');

create policy "profile_images_update"
  on storage.objects for update
  using (bucket_id = 'profile-images')
  with check (bucket_id = 'profile-images');

create policy "profile_images_delete"
  on storage.objects for delete
  using (bucket_id = 'profile-images');
