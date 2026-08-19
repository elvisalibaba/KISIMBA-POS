create table public.sales (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  invoice_number text not null,
  seller_id uuid not null references public.profiles(id),
  customer_phone text,
  payment_method text not null,
  total_amount numeric(14,2) not null check (total_amount >= 0),
  amount_received numeric(14,2) not null check (amount_received >= 0),
  change_amount numeric(14,2) not null default 0 check (change_amount >= 0),
  currency text not null default 'CDF' check (currency in ('CDF', 'USD')),
  sold_at timestamptz not null default now(),
  synced_at timestamptz,
  unique (business_id, invoice_number)
);

create table public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  unit_cost numeric(14,2) not null check (unit_cost >= 0),
  line_total numeric(14,2) generated always as (quantity * unit_price) stored
);

alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
create policy "members create sales" on public.sales for insert with check (
  seller_id = auth.uid() and exists (select 1 from public.business_members m where m.business_id = sales.business_id and m.profile_id = auth.uid())
);
create policy "members read sales" on public.sales for select using (
  exists (select 1 from public.business_members m where m.business_id = sales.business_id and m.profile_id = auth.uid())
);
create policy "members create sale items" on public.sale_items for insert with check (
  exists (select 1 from public.sales s where s.id = sale_items.sale_id and s.seller_id = auth.uid())
);
create policy "members read sale items" on public.sale_items for select using (
  exists (select 1 from public.sales s join public.business_members m on m.business_id = s.business_id where s.id = sale_items.sale_id and m.profile_id = auth.uid())
);
create index sales_business_sold_at_idx on public.sales(business_id, sold_at desc);
create index sale_items_sale_id_idx on public.sale_items(sale_id);
