-- Product purchasing and selling units used by small shops in Kinshasa.
alter table public.products
  add column barcode text,
  add column purchase_package_type text not null default 'Pièce',
  add column purchased_packages numeric(14,3) not null default 1 check (purchased_packages > 0),
  add column units_per_package numeric(14,3) not null default 1 check (units_per_package > 0),
  add column sale_unit text not null default 'Pièce',
  add column extra_costs numeric(14,2) not null default 0 check (extra_costs >= 0),
  add column expiry_date date,
  add column lot_number text,
  add column alert_days_before_expiry integer not null default 30 check (alert_days_before_expiry >= 0),
  add column low_stock_threshold numeric(14,3) not null default 5 check (low_stock_threshold >= 0);

create unique index products_business_barcode_unique
  on public.products(business_id, barcode)
  where barcode is not null;

comment on column public.products.purchase_package_type is 'Carton, casier, paquet, sac, bidon, régime, plateau or pièce';
comment on column public.products.units_per_package is 'Number of sale units contained in one purchase package';
comment on column public.products.extra_costs is 'Transport, manutention, taxes and other landed costs';
