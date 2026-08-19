alter table public.businesses add column logo_url text;
alter table public.products add column product_type text not null default 'Autre';

comment on column public.businesses.logo_url is 'Logo displayed on the professional checkout and receipts';
comment on column public.products.product_type is 'Local retail category such as Alimentation, Boisson, Hygiène or Quincaillerie';
