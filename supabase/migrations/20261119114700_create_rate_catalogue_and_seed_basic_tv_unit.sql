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
  rate numeric(12, 2) null check (rate is null or rate >= 0),
  pricing_type text not null default 'fixed'
    check (pricing_type in ('fixed', 'market_rate')),
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

-- Item 02: Generic Ledge
-- Reusable ledge catalogue entry; no room-specific or project-specific dimensions are stored.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Ledges', 'ledges')
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
  'Ledge',
  'Fabrication, supply and installation of 4 cm thick Marine Plywood Ledge, complete as per approved design.',
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

-- Item 04: Centre Table
-- Standard design; dimensions and material options are part of the catalogue specification.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Centre Tables', 'centre-tables')
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
  'Centre Table',
  'Supply of standard design Centre Table measuring 45 cm x 45 cm, made using Plywood or HDHMR.',
  '{
    "dimensions": "45 cm x 45 cm",
    "material": "Plywood or HDHMR",
    "design": "Standard design"
  }'::jsonb,
  18500.00,
  'piece',
  'Per piece'
from category
on conflict (category_id, name) do nothing;


-- Items 05–07: Living area paneling and ceiling works
-- Market-rate items have a null numeric rate and are identified by pricing_type.

-- Item 05: Fluted Paneling
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Wall Paneling', 'wall-paneling')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id,
  name,
  description,
  specifications,
  rate,
  pricing_type,
  rate_unit,
  pricing_basis
)
select
  category.id,
  'Fluted Paneling',
  'Supply and installation of fluted paneling. Rate is based on current market pricing and varies according to size, material, make and pattern.',
  '{
    "rate_determination": "Current market rate",
    "rate_factors": ["Size", "Material", "Make", "Pattern"]
  }'::jsonb,
  null,
  'market_rate',
  'As applicable',
  'To be determined based on measured size and selected panel specification'
from category
on conflict (category_id, name) do nothing;

-- Item 06: Wooden Ceiling
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Ceiling Works', 'ceiling-works')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id,
  name,
  description,
  specifications,
  rate,
  pricing_type,
  rate_unit,
  pricing_basis
)
select
  category.id,
  'Wooden Ceiling',
  'Supply and installation of wooden ceiling. Rate subject to material, design and site conditions.',
  '{}'::jsonb,
  1050.00,
  'fixed',
  'sq.ft.',
  'Measured ceiling area; rate subject to material, design and site conditions'
from category
on conflict (category_id, name) do nothing;

-- Item 07: Window Panelling
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Window Panelling', 'window-panelling')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id,
  name,
  description,
  specifications,
  rate,
  pricing_type,
  rate_unit,
  pricing_basis
)
select
  category.id,
  'Window Panelling',
  'Supply and installation of window panelling at an approximate rate of ₹650 per sq.ft. Rate subject to material, design and site conditions.',
  '{}'::jsonb,
  650.00,
  'fixed',
  'sq.ft.',
  'Measured area; approximate rate subject to material, design and site conditions'
from category
on conflict (category_id, name) do nothing;


-- Item 08: Dining Wash
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Dining Units', 'dining-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Dining Wash',
  'Fabrication, supply and installation of Dining Wash Unit using 710 Grade BWP Plywood or WPC, with pricing calculated on the front elevation area (width x height), complete as per approved design.',
  '{
    "material": "Plywood (710 Grade BWP) or WPC",
    "pricing_measurement": "Front elevation area (width x height)"
  }'::jsonb,
  2150.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;

-- Item 10: 4 Seater Dining Table
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Dining Tables', 'dining-tables')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  '4 Seater Dining Table',
  'Supply of standard design 4 Seater Dining Table, complete as a finished piece.',
  '{
    "design": "Standard design"
  }'::jsonb,
  40000.00,
  'piece',
  'Per piece'
from category
on conflict (category_id, name) do nothing;

-- Item 11: Dining Chair
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Dining Chairs', 'dining-chairs')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Dining Chair',
  'Supply of standard design Dining Chair, complete as a finished piece.',
  '{
    "design": "Standard design"
  }'::jsonb,
  12500.00,
  'piece',
  'Per piece'
from category
on conflict (category_id, name) do nothing;

-- Item 12: Crockery Unit
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Crockery Units', 'crockery-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Crockery Unit',
  'Fabrication, supply and installation of Crockery Unit using 19 mm Marine Plywood (710 Grade BWP) / HDHMR, with pricing calculated on the front elevation area (width x height), complete as per approved design.',
  '{
    "material": "19 mm Marine Plywood (710 Grade BWP) / HDHMR",
    "pricing_measurement": "Front elevation area (width x height)"
  }'::jsonb,
  2150.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;

-- Item 13: Breakfast Counter Modesty Panel
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Kitchen Units', 'kitchen-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Breakfast Counter - Modesty Panel',
  'Fabrication, supply and installation of Breakfast Counter Modesty Panel using 19 mm Marine Plywood (710 Grade BWP) / HDHMR, with pricing calculated on the front elevation area (width x height), complete as per approved design.',
  '{
    "material": "19 mm Marine Plywood (710 Grade BWP) / HDHMR",
    "work_type": "Modesty panel",
    "pricing_measurement": "Front elevation area (width x height)"
  }'::jsonb,
  1550.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;

-- Item 14: Kitchen Bottom Unit
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Kitchen Units', 'kitchen-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Kitchen Bottom Unit',
  'Fabrication, supply and installation of Kitchen Bottom Unit using 19 mm Marine Plywood (710 Grade BWP) / HDHMR, with pricing calculated on the front elevation area (width x height), complete as per approved design.',
  '{
    "material": "19 mm Marine Plywood (710 Grade BWP) / HDHMR",
    "pricing_measurement": "Front elevation area (width x height)"
  }'::jsonb,
  1950.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;
