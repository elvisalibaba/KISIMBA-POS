alter table public.products
  add column image_url text,
  add column image_source text check (image_source in ('camera', 'gallery', 'barcode_catalog'));

create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  supplier_name text,
  supplier_phone text,
  supplier_address text,
  invoice_reference text,
  total_amount numeric(14,2) not null check (total_amount >= 0),
  currency text not null default 'CDF' check (currency in ('CDF', 'USD')),
  purchased_by uuid not null references public.profiles(id),
  purchased_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.market_offers (
  id uuid primary key default gen_random_uuid(),
  product_name text not null,
  unit text not null,
  price numeric(14,2) not null check (price >= 0),
  currency text not null default 'CDF' check (currency in ('CDF', 'USD')),
  supplier_name text not null,
  supplier_phone text,
  supplier_address text,
  source_url text,
  observed_at timestamptz not null,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.purchases enable row level security;
alter table public.market_offers enable row level security;
create policy "members read purchases" on public.purchases for select using (
  exists (select 1 from public.business_members m where m.business_id = purchases.business_id and m.profile_id = auth.uid())
);
create policy "admin records purchases" on public.purchases for insert with check (
  purchased_by = auth.uid() and exists (select 1 from public.businesses b where b.id = purchases.business_id and b.owner_id = auth.uid())
);
create policy "authenticated read market offers" on public.market_offers for select to authenticated using (true);

-- No DELETE policies are intentionally created for sales, sale_items or
-- purchases. Mobile clients can append and read accounting history, not erase it.
comment on table public.sales is 'Append-only sales history for authenticated business members';
comment on table public.purchases is 'Append-only purchase history; corrections use compensating records';
