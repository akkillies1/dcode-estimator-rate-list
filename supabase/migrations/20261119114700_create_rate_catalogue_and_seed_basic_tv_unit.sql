-- DCODE Rate Catalogue: initial schema and Item 01 seed
-- Item 01: Basic TV Unit
-- Reference dimensions are intentionally not stored in the reusable catalogue.

create table if not exists public.rate_catalogue_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.rate_catalogue_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.rate_catalogue_categories(id) on delete restrict,
  name text not null,
  description text not null,
  specifications jsonb not null default '{}'::jsonb
    check (jsonb_typeof(specifications) = 'object'),
  rate numeric(12, 2) not null check (rate >= 0),
  rate_unit text not null,
  pricing_basis text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (category_id, name)
);

create index if not exists rate_catalogue_items_category_id_idx
  on public.rate_catalogue_items(category_id);

-- Keep the catalogue protected by default. Authenticated users can read;
-- write access can be granted later according to the app's admin model.
alter table public.rate_catalogue_categories enable row level security;
alter table public.rate_catalogue_items enable row level security;

drop policy if exists "Authenticated users can read rate catalogue categories"
  on public.rate_catalogue_categories;
create policy "Authenticated users can read rate catalogue categories"
  on public.rate_catalogue_categories
  for select to authenticated
  using (true);

drop policy if exists "Authenticated users can read rate catalogue items"
  on public.rate_catalogue_items;
create policy "Authenticated users can read rate catalogue items"
  on public.rate_catalogue_items
  for select to authenticated
  using (true);

with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('TV Units', 'tv-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id,
  name,
  description,
  specifications,
  rate,
  rate_unit,
  pricing_basis
)
select
  category.id,
  'Basic TV Unit',
  'Fabrication, supply and installation of LCD TV Unit using laminated Marine Plywood (710 Grade - BWP), including box work, square-edge shutters and all necessary hardware and fittings, complete as per approved design.',
  '{
    "cabinet_carcass": "16 mm and 9 mm laminated Marine Plywood, 710 Grade - BWP",
    "shutters": "19 mm Marine Plywood (710 Grade - BWP) / HDHMR",
    "shutter_finish": "Laminated, square-edge finish",
    "hinges": "Hettich hinges",
    "handles": "Standard handles",
    "hardware_and_fittings": "All necessary hardware and fittings required for installation"
  }'::jsonb,
  1950.00,
  'sq.ft.',
  'Front face elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;

-- Item 02: TV Unit Ledge
-- Priced by running length; no project-specific dimensions or quantities are stored.
with category as (
  select id
  from public.rate_catalogue_categories
  where slug = 'tv-units'
)
insert into public.rate_catalogue_items (
  category_id,
  name,
  description,
  specifications,
  rate,
  rate_unit,
  pricing_basis
)
select
  category.id,
  'TV Unit Ledge',
  'Fabrication, supply and installation of TV Unit Ledge using 4 cm thick Marine Plywood, complete as per approved design.',
  '{
    "material": "Marine Plywood only",
    "thickness": "4 cm"
  }'::jsonb,
  1050.00,
  'running foot',
  'Length of ledge'
from category
on conflict (category_id, name) do nothing;

-- Item 03: Sofa
-- Pricing is per piece; project-specific dimensions and quantities are not stored.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Sofas', 'sofas')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id,
  name,
  description,
  specifications,
  rate,
  rate_unit,
  pricing_basis
)
select
  category.id,
  'Sofa',
  'Supply of sofa as per approved design, size, material, finish and upholstery selection.',
  '{}'::jsonb,
  62500.00,
  'piece',
  'Per piece'
from category
on conflict (category_id, name) do nothing;
