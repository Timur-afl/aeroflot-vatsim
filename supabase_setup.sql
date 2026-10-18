-- AEROFLOT VATSIM: shared flights database and document storage
-- Run this whole script in Supabase Dashboard → SQL Editor → New query.
create extension if not exists pgcrypto;

create table if not exists public.flights (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  number text not null,
  aircraft text not null,
  "from" text not null,
  "to" text not null,
  date date not null,
  time text,
  crew text,
  notes text,
  files jsonb not null default '[]'::jsonb
);

alter table public.flights enable row level security;

-- Anyone can read published flight cards. Only authenticated admins can write.
-- Create admin account in Authentication → Users, then add its UUID below.
create table if not exists public.site_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.site_admins enable row level security;

drop policy if exists "Public can read admin list" on public.site_admins;
create policy "Public can read admin list" on public.site_admins
for select to anon, authenticated using (true);

drop policy if exists "Public can read flights" on public.flights;
create policy "Public can read flights" on public.flights
for select to anon, authenticated using (true);

drop policy if exists "Admins insert flights" on public.flights;
create policy "Admins insert flights" on public.flights
for insert to authenticated with check (
  exists (select 1 from public.site_admins a where a.user_id = auth.uid())
);

drop policy if exists "Admins update flights" on public.flights;
create policy "Admins update flights" on public.flights
for update to authenticated using (
  exists (select 1 from public.site_admins a where a.user_id = auth.uid())
) with check (
  exists (select 1 from public.site_admins a where a.user_id = auth.uid())
);

drop policy if exists "Admins delete flights" on public.flights;
create policy "Admins delete flights" on public.flights
for delete to authenticated using (
  exists (select 1 from public.site_admins a where a.user_id = auth.uid())
);

-- Public bucket means anyone with the URL can download the flight documents.
-- Upload/delete remain restricted to admins by storage object policies.
insert into storage.buckets (id, name, public)
values ('flight-docs', 'flight-docs', true)
on conflict (id) do update set public = true;

drop policy if exists "Public read flight documents" on storage.objects;
create policy "Public read flight documents" on storage.objects
for select to anon, authenticated using (bucket_id = 'flight-docs');

drop policy if exists "Admins upload flight documents" on storage.objects;
create policy "Admins upload flight documents" on storage.objects
for insert to authenticated with check (
  bucket_id = 'flight-docs'
  and exists (select 1 from public.site_admins a where a.user_id = auth.uid())
);

drop policy if exists "Admins delete flight documents" on storage.objects;
create policy "Admins delete flight documents" on storage.objects
for delete to authenticated using (
  bucket_id = 'flight-docs'
  and exists (select 1 from public.site_admins a where a.user_id = auth.uid())
);

-- After creating your own admin user in Authentication → Users,
-- copy its UUID and run this separately:
-- insert into public.site_admins (user_id) values ('PASTE-ADMIN-USER-UUID-HERE');
