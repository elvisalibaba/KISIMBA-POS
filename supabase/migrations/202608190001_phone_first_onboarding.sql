create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone_number text not null unique check (phone_number ~ '^\+[1-9][0-9]{7,14}$'),
  full_name text not null check (length(trim(full_name)) >= 2),
  email text,
  preferred_language text not null default 'fr' check (preferred_language in ('fr', 'ln')),
  phone_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.businesses (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id) on delete cascade,
  business_name text not null check (length(trim(business_name)) >= 2), business_type text not null,
  city text, commune text, neighborhood text,
  primary_currency text not null default 'CDF' check (primary_currency in ('CDF', 'USD')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.business_members (
  business_id uuid not null references public.businesses(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner', 'manager', 'cashier')),
  created_at timestamptz not null default now(), primary key (business_id, profile_id)
);

create table public.device_sessions (
  id uuid primary key default gen_random_uuid(), profile_id uuid not null references public.profiles(id) on delete cascade,
  device_public_id text not null, device_name text, last_seen_at timestamptz not null default now(),
  revoked_at timestamptz, unique (profile_id, device_public_id)
);

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.device_sessions enable row level security;
create policy "profile reads self" on public.profiles for select using (id = auth.uid());
create policy "profile updates self" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy "members read their businesses" on public.businesses for select using (exists (select 1 from public.business_members m where m.business_id = id and m.profile_id = auth.uid()));
create policy "owners update their businesses" on public.businesses for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "memberships visible to member" on public.business_members for select using (profile_id = auth.uid());
create policy "sessions visible to owner" on public.device_sessions for select using (profile_id = auth.uid());
create policy "sessions revocable by owner" on public.device_sessions for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

comment on column public.profiles.phone_number is 'E.164 phone; changed only after OTP verification';
comment on table public.device_sessions is 'Revocation logs a lost phone out on its next synchronization';
