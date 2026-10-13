-- NITAMUN 4.0 schema. Run in Supabase SQL Editor.
-- IMPORTANT: review policies and test with separate anon/authenticated accounts before launch.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'delegate' check (role in ('delegate','organizer','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.committees (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  acronym text,
  agenda text,
  description text,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.countries (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  region text,
  created_at timestamptz not null default now()
);

create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(full_name) between 2 and 120),
  email text not null check (char_length(email) <= 254),
  phone text check (phone is null or char_length(phone) <= 30),
  institution text not null check (char_length(institution) between 2 and 180),
  year_of_study text,
  status text not null default 'submitted' check (status in ('submitted','under_review','accepted','waitlisted','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.country_allotments (
  id uuid primary key default gen_random_uuid(),
  committee_id uuid not null references public.committees(id) on delete cascade,
  country_id uuid not null references public.countries(id) on delete restrict,
  status text not null default 'vacant' check (status in ('vacant','allotted','reserved')),
  registration_id uuid references public.registrations(id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (committee_id, country_id),
);

create table if not exists public.registration_preferences (
  id uuid primary key default gen_random_uuid(),
  registration_id uuid not null references public.registrations(id) on delete cascade,
  preference_type text not null check (preference_type in ('committee','country')),
  committee_id uuid references public.committees(id) on delete cascade,
  country_id uuid references public.countries(id) on delete cascade,
  preference_order integer not null check (preference_order between 1 and 5),
  created_at timestamptz not null default now(),
  constraint preference_target_matches_type check (
    (preference_type = 'committee' and committee_id is not null and country_id is null)
    or (preference_type = 'country' and country_id is not null and committee_id is null)
  ),
  unique (registration_id, preference_type, preference_order)
);

create table if not exists public.blogs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  excerpt text,
  body text not null default '',
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text,
  file_url text not null,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists country_allotments_status_idx on public.country_allotments(status);
create index if not exists registrations_created_at_idx on public.registrations(created_at desc);
create index if not exists registrations_email_idx on public.registrations(email);
create index if not exists registration_preferences_registration_idx on public.registration_preferences(registration_id);

-- RLS everywhere. Never expose registration records or preference records publicly.
alter table public.profiles enable row level security;
alter table public.committees enable row level security;
alter table public.countries enable row level security;
alter table public.registrations enable row level security;
alter table public.country_allotments enable row level security;
alter table public.registration_preferences enable row level security;
alter table public.blogs enable row level security;
alter table public.resources enable row level security;

-- Helper function checks role without exposing profile rows to other users.
create or replace function public.has_admin_role()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid())
      and p.role in ('admin','organizer')
  );
$$;
revoke all on function public.has_admin_role() from public;
grant execute on function public.has_admin_role() to authenticated;

-- Public read-only content.
drop policy if exists "Published committees are public" on public.committees;
create policy "Published committees are public" on public.committees for select to anon, authenticated using (is_published or public.has_admin_role());
drop policy if exists "Countries are public" on public.countries;
create policy "Countries are public" on public.countries for select to anon, authenticated using (true);
drop policy if exists "Public allotment status only" on public.country_allotments;
-- This table has no delegate name/email fields. Public status is visible.
create policy "Public allotment status only" on public.country_allotments for select to anon, authenticated using (true);
drop policy if exists "Published blogs are public" on public.blogs;
create policy "Published blogs are public" on public.blogs for select to anon, authenticated using (is_published or public.has_admin_role());
drop policy if exists "Published resources are public" on public.resources;
create policy "Published resources are public" on public.resources for select to anon, authenticated using (is_published or public.has_admin_role());

-- Registration data is submitted through a transaction-safe RPC below.
-- No direct anonymous table INSERT policy is granted, so clients cannot bypass preference validation.
drop policy if exists "Public can submit registration" on public.registrations;
drop policy if exists "Organizers can read registrations" on public.registrations;
create policy "Organizers can read registrations" on public.registrations for select to authenticated using (public.has_admin_role());
drop policy if exists "Organizers can update registrations" on public.registrations;
create policy "Organizers can update registrations" on public.registrations for update to authenticated using (public.has_admin_role()) with check (public.has_admin_role());

-- Preferences are inserted only inside submit_registration(), in the same transaction as the registration.
drop policy if exists "Public can submit preferences" on public.registration_preferences;
drop policy if exists "Organizers can read preferences" on public.registration_preferences;
create policy "Organizers can read preferences" on public.registration_preferences for select to authenticated using (public.has_admin_role());

-- Only organizers can mutate allotments or editorial content.
drop policy if exists "Organizers manage allotments" on public.country_allotments;
create policy "Organizers manage allotments" on public.country_allotments for all to authenticated using (public.has_admin_role()) with check (public.has_admin_role());
drop policy if exists "Organizers manage committees" on public.committees;
create policy "Organizers manage committees" on public.committees for all to authenticated using (public.has_admin_role()) with check (public.has_admin_role());
drop policy if exists "Organizers manage blogs" on public.blogs;
create policy "Organizers manage blogs" on public.blogs for all to authenticated using (public.has_admin_role()) with check (public.has_admin_role());
drop policy if exists "Organizers manage resources" on public.resources;
create policy "Organizers manage resources" on public.resources for all to authenticated using (public.has_admin_role()) with check (public.has_admin_role());

-- Profiles: users can see their own role; no self-service role changes.
drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile" on public.profiles for select to authenticated using (id = (select auth.uid()) or public.has_admin_role());
drop policy if exists "Admins manage profiles" on public.profiles;
create policy "Admins manage profiles" on public.profiles for all to authenticated using (public.has_admin_role()) with check (public.has_admin_role());

-- Starter sample data: uncomment to test, then replace with official committee/country list.
-- insert into public.committees (name, acronym, agenda, description, is_published)
-- values ('United Nations Security Council', 'UNSC', 'International peace and security', 'A crisis-focused committee.', true);
-- insert into public.countries (name, region) values ('India', 'Asia'), ('Brazil', 'South America'), ('France', 'Europe');
-- insert into public.country_allotments (committee_id, country_id, status)
-- select cm.id, co.id, 'vacant' from public.committees cm cross join public.countries co;


-- Atomic public registration submission. Validates selected IDs and caps preferences.
-- Add CAPTCHA / edge-level rate limiting before public launch.
create or replace function public.submit_registration(
  p_full_name text,
  p_email text,
  p_phone text,
  p_institution text,
  p_year_of_study text,
  p_committee_ids uuid[],
  p_country_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_registration_id uuid;
  committee_count integer;
  country_count integer;
begin
  if p_full_name is null or char_length(trim(p_full_name)) not between 2 and 120 then
    raise exception 'Invalid full name';
  end if;
  if p_email is null or char_length(trim(p_email)) > 254 or trim(p_email) !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'Invalid email';
  end if;
  if p_institution is null or char_length(trim(p_institution)) not between 2 and 180 then
    raise exception 'Invalid institution';
  end if;
  if coalesce(array_length(p_committee_ids, 1), 0) < 1 or array_length(p_committee_ids, 1) > 3 then
    raise exception 'Choose between one and three committee preferences';
  end if;
  if coalesce(array_length(p_country_ids, 1), 0) > 5 then
    raise exception 'Choose no more than five country preferences';
  end if;

  select count(distinct x) into committee_count from unnest(p_committee_ids) as x;
  if committee_count <> coalesce(array_length(p_committee_ids, 1), 0) then
    raise exception 'Duplicate committee preferences';
  end if;
  select count(distinct x) into country_count from unnest(coalesce(p_country_ids, array[]::uuid[])) as x;
  if country_count <> coalesce(array_length(p_country_ids, 1), 0) then
    raise exception 'Duplicate country preferences';
  end if;
  if exists (
    select 1 from unnest(p_committee_ids) selected(id)
    left join public.committees c on c.id = selected.id and c.is_published = true
    where c.id is null
  ) then raise exception 'Invalid committee preference'; end if;
  if exists (
    select 1 from unnest(coalesce(p_country_ids, array[]::uuid[])) selected(id)
    left join public.countries c on c.id = selected.id
    where c.id is null
  ) then raise exception 'Invalid country preference'; end if;

  insert into public.registrations(full_name, email, phone, institution, year_of_study, status)
  values (trim(p_full_name), lower(trim(p_email)), nullif(trim(coalesce(p_phone, '')), ''),
          trim(p_institution), nullif(trim(coalesce(p_year_of_study, '')), ''), 'submitted')
  returning id into new_registration_id;

  insert into public.registration_preferences(registration_id, preference_type, committee_id, preference_order)
  select new_registration_id, 'committee', selected.id, selected.ordinality::integer
  from unnest(p_committee_ids) with ordinality as selected(id, ordinality);

  insert into public.registration_preferences(registration_id, preference_type, country_id, preference_order)
  select new_registration_id, 'country', selected.id, selected.ordinality::integer
  from unnest(coalesce(p_country_ids, array[]::uuid[])) with ordinality as selected(id, ordinality);

  return new_registration_id;
end;
$$;

revoke all on function public.submit_registration(text,text,text,text,text,uuid[],uuid[]) from public;
grant execute on function public.submit_registration(text,text,text,text,text,uuid[],uuid[]) to anon, authenticated;
