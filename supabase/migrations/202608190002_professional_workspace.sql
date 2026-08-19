-- Professional workspace: products and an admin-managed team of at most five sellers.
create table public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null check (length(trim(name)) >= 1),
  sale_price numeric(14,2) not null check (sale_price >= 0),
  purchase_price numeric(14,2) check (purchase_price >= 0),
  quantity numeric(14,3) not null default 0 check (quantity >= 0),
  currency text not null default 'CDF' check (currency in ('CDF', 'USD')),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.business_invitations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  phone_number text not null check (phone_number ~ '^\+[1-9][0-9]{7,14}$'),
  full_name text not null,
  role text not null default 'cashier' check (role = 'cashier'),
  invited_by uuid not null references public.profiles(id),
  accepted_at timestamptz,
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now(),
  unique (business_id, phone_number)
);

create or replace function public.enforce_five_sellers_limit()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role = 'cashier' and (
    select count(*) from public.business_members
    where business_id = new.business_id and role = 'cashier'
  ) >= 5 then
    raise exception 'Une boutique ne peut pas avoir plus de 5 vendeurs';
  end if;
  return new;
end;
$$;

create trigger business_members_five_sellers
before insert or update of role on public.business_members
for each row execute function public.enforce_five_sellers_limit();

alter table public.products enable row level security;
alter table public.business_invitations enable row level security;

create policy "owner creates business" on public.businesses for insert with check (owner_id = auth.uid());
create policy "owner creates memberships" on public.business_members for insert with check (
  exists (select 1 from public.businesses b where b.id = business_id and b.owner_id = auth.uid())
);
create policy "owner manages memberships" on public.business_members for delete using (
  exists (select 1 from public.businesses b where b.id = business_id and b.owner_id = auth.uid())
);
create policy "members read products" on public.products for select using (
  exists (select 1 from public.business_members m where m.business_id = products.business_id and m.profile_id = auth.uid())
);
create policy "admin manages products" on public.products for all using (
  exists (select 1 from public.businesses b where b.id = products.business_id and b.owner_id = auth.uid())
) with check (
  exists (select 1 from public.businesses b where b.id = products.business_id and b.owner_id = auth.uid())
);
create policy "owner manages invitations" on public.business_invitations for all using (
  exists (select 1 from public.businesses b where b.id = business_invitations.business_id and b.owner_id = auth.uid())
) with check (
  invited_by = auth.uid() and exists (select 1 from public.businesses b where b.id = business_invitations.business_id and b.owner_id = auth.uid())
);

create index products_business_id_idx on public.products(business_id);
create index members_profile_id_idx on public.business_members(profile_id);
create index invitations_phone_idx on public.business_invitations(phone_number);
