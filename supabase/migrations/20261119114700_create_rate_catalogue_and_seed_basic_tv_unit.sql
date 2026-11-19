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
    "pricing_measurement": "Front elevation area (width x height)",
    "quotation_options": [
      {
        "name": "Crockery Base Unit",
        "rate": 2150.00,
        "rate_unit": "sq.ft.",
        "pricing_basis": "Front elevation area (width x height)"
      },
      {
        "name": "Crockery Loft Unit",
        "rate": 1950.00,
        "rate_unit": "sq.ft.",
        "pricing_basis": "Front elevation area (width x height)"
      }
    ],
    "quotation_selection": "Options can be selected independently; calculate and describe each selected unit separately."
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


-- Item 15: Kitchen Overhead Unit
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
  'Kitchen Overhead Unit',
  'Fabrication, supply and installation of Kitchen Overhead Unit using 19 mm Marine Plywood (710 Grade BWP) / HDHMR, with pricing calculated on the front elevation area (width x height), complete as per approved design.',
  '{
    "material": "19 mm Marine Plywood (710 Grade BWP) / HDHMR",
    "pricing_measurement": "Front elevation area (width x height)"
  }'::jsonb,
  1950.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;

-- Item 16: Kitchen Loft Unit
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
  'Kitchen Loft Unit',
  'Fabrication, supply and installation of Kitchen Loft Unit using 19 mm Marine Plywood (710 Grade BWP) / HDHMR, with pricing calculated on the front elevation area (width x height), complete as per approved design.',
  '{
    "material": "19 mm Marine Plywood (710 Grade BWP) / HDHMR",
    "pricing_measurement": "Front elevation area (width x height)"
  }'::jsonb,
  1550.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;

-- Item 17 is not a separate catalogue product.
-- Crockery Loft Unit is an independently selectable option within Item 12: Crockery Unit.


-- Item 18: Queen Size Cot
-- Headboard is a selectable quotation option; the base catalogue rate is without headboard.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Beds / Cots', 'beds-cots')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Queen Size Cot',
  'Fabrication, supply and installation of Queen Size Cot (158 cm x 200 cm) using laminated Marine Plywood (710 Grade - BWP), with 16 mm and 9 mm laminated plywood box work.',
  '{
    "design": "Standard design",
    "dimensions": "158 cm x 200 cm",
    "material": "Laminated Marine Plywood (710 Grade - BWP)",
    "box_work": "16 mm and 9 mm laminated plywood",
    "pricing_measurement": "Per piece",
    "quotation_options": [
      {
        "name": "Without Headboard",
        "rate": 36750.00,
        "rate_unit": "piece",
        "description": "Fabrication, supply and installation of Queen Size Cot (158 cm x 200 cm) using laminated Marine Plywood (710 Grade - BWP), with 16 mm and 9 mm laminated plywood box work."
      },
      {
        "name": "With Headboard Cushion",
        "rate": 48000.00,
        "rate_unit": "piece",
        "description": "Fabrication, supply and installation of Queen Size Cot (158 cm x 200 cm) using laminated Marine Plywood (710 Grade - BWP), with 16 mm and 9 mm laminated plywood box work, including upholstered headboard with cushion."
      }
    ],
    "quotation_selection": "Select either Without Headboard or With Headboard Cushion. Apply the selected option rate and generate its corresponding description."
  }'::jsonb,
  36750.00,
  'piece',
  'Per piece; headboard selection determines the applicable rate and generated description'
from category
on conflict (category_id, name) do nothing;


-- Item 20: Wardrobe
-- Standard dimensions are prefilled in the quotation; dimensions remain editable.
-- If dimensions are changed, calculate the wardrobe price using the custom front-elevation rate.
-- Loft is an optional add-on with its own dimensions and rate.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Wardrobes', 'wardrobes')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Wardrobe',
  'Fabrication, supply and installation of Wardrobe using laminated Marine Ply (710 Grade - BWP) with 16 mm and 9 mm laminated plywood box work and 19 mm square-edge shutters in Marine Ply (710 Grade BWP) / HDHMR, including Hettich hinges, standard handles and all necessary hardware and fittings.',
  '{
    "material": "Laminated Marine Ply (710 Grade - BWP)",
    "box_work": "16 mm and 9 mm laminated plywood",
    "shutters": "19 mm square-edge shutters in Marine Ply (710 Grade BWP) / HDHMR",
    "hardware": ["Hettich hinges", "Standard handles", "All necessary hardware and fittings"],
    "standard_dimensions": {
      "width_cm": 124,
      "height_cm": 210
    },
    "standard_rate": 56550.00,
    "standard_rate_unit": "piece",
    "custom_rate": 1950.00,
    "custom_rate_unit": "sq.ft.",
    "custom_pricing_basis": "Front elevation area (width x height)",
    "quotation_behavior": "Prefill the standard dimensions (124 cm x 210 cm) and standard price. Allow dimensions to be edited in the quotation. If dimensions are changed, calculate the wardrobe price using the custom rate per sq.ft. of front elevation area.",
    "optional_add_ons": [
      {
        "name": "Wardrobe Loft",
        "default_dimensions_cm": {
          "width": 124,
          "height": 60
        },
        "rate": 1550.00,
        "rate_unit": "sq.ft.",
        "pricing_basis": "Front elevation area (width x height)",
        "optional": true,
        "quotation_behavior": "Allow the loft to be selected independently; when selected, allow its dimensions to be edited and calculate its price separately."
      }
    ]
  }'::jsonb,
  56550.00,
  'piece',
  'Standard wardrobe: 124 cm x 210 cm at ₹56,550 per piece; editable dimensions use ₹1,950 per sq.ft. of front elevation area. Optional loft: ₹1,550 per sq.ft. of front elevation area.'
from category
on conflict (category_id, name) do nothing;

-- Item 21: Dressing Unit
-- Mirror is an optional, independently priced quotation add-on.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Bedroom Units', 'bedroom-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Dressing Unit',
  'Fabrication, supply and installation of Dressing Unit using 16 mm Marine Plywood (710 Grade - BWP) / HDHMR, with pricing calculated on the front elevation area (width x height), complete as per approved design.',
  '{
    "material": "16 mm Marine Plywood (710 Grade - BWP) / HDHMR",
    "standard_dimensions": {
      "width_cm": 60,
      "height_cm": 60
    },
    "rate": 1950.00,
    "rate_unit": "sq.ft.",
    "pricing_basis": "Front elevation area (width x height)",
    "optional_add_ons": [
      {
        "name": "Mirror",
        "default_dimensions_cm": {
          "width": 60,
          "height": 210
        },
        "rate": 950.00,
        "rate_unit": "sq.ft.",
        "pricing_basis": "Front elevation area (width x height)",
        "optional": true,
        "description": "Supply and installation of Mirror, with pricing calculated on the front elevation area (width x height), complete as per approved design.",
        "quotation_behavior": "Allow the mirror to be selected independently; allow its dimensions to be edited and calculate its price separately."
      }
    ],
    "quotation_behavior": "Prefill dressing unit dimensions as 60 cm x 60 cm; allow dimensions to be edited in the quotation. Mirror is optional and independently dimensioned and priced."
  }'::jsonb,
  1950.00,
  'sq.ft.',
  'Front elevation area (width x height); optional mirror separately at ₹950 per sq.ft.'
from category
on conflict (category_id, name) do nothing;


-- Item 22: King Size Cot
-- Standard dimensions and headboard options are quotation defaults; the without-headboard rate is intentionally unset.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Beds / Cots', 'beds-cots')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'King Size Cot',
  'Fabrication, supply and installation of King Size Cot (180 cm x 200 cm) using laminated Marine Plywood (710 Grade - BWP), with 16 mm and 9 mm laminated plywood box work.',
  '{
    "design": "Standard design",
    "dimensions": "180 cm x 200 cm",
    "material": "Laminated Marine Plywood (710 Grade - BWP)",
    "box_work": "16 mm and 9 mm laminated plywood",
    "pricing_measurement": "Per piece",
    "quotation_options": [
      {
        "name": "Without Headboard",
        "rate": null,
        "rate_unit": "piece",
        "description": "Fabrication, supply and installation of King Size Cot (180 cm x 200 cm) using laminated Marine Plywood (710 Grade - BWP), with 16 mm and 9 mm laminated plywood box work."
      },
      {
        "name": "With Upholstered Cushion Headboard",
        "rate": 50500.00,
        "rate_unit": "piece",
        "description": "Fabrication, supply and installation of King Size Cot (180 cm x 200 cm) using laminated Marine Plywood (710 Grade - BWP), with 16 mm and 9 mm laminated plywood box work, including upholstered headboard with cushion."
      }
    ],
    "quotation_selection": "Select either Without Headboard or With Upholstered Cushion Headboard. Apply the selected option rate and generate its corresponding description. Keep the Without Headboard rate unset until supplied.",
    "standard_dimensions_editable": true
  }'::jsonb,
  null,
  'piece',
  'Per piece; selectable headboard option determines applicable rate and generated description'
from category
on conflict (category_id, name) do nothing;

-- Item 23: Study Table
-- Reference dimensions are quotation defaults and remain editable.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Bedroom Units', 'bedroom-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Study Table',
  'Fabrication, supply and installation of Study Table using 19 mm Marine Plywood (710 Grade - BWP) / HDHMR for the main worktop and visible panels, with 16 mm internal box work and supports, complete as per approved design.',
  '{
    "standard_dimensions": {
      "width_cm": 127,
      "depth_cm": 60
    },
    "dimensions_editable": true,
    "material": "Marine Plywood (710 Grade - BWP) / HDHMR",
    "main_worktop_and_visible_panels": "19 mm",
    "internal_box_work_and_supports": "16 mm",
    "rate": 1550.00,
    "rate_unit": "sq.ft.",
    "pricing_basis": "Front elevation area (width x height)",
    "quotation_behavior": "Prefill the reference dimensions of 127 cm x 60 cm and allow dimensions to be edited in the quotation."
  }'::jsonb,
  1550.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;


-- Item 24: Standard Bookshelf
-- Standard design; dimensions are not fixed and are entered in the quotation.
with category as (
  insert into public.rate_catalogue_categories (name, slug)
  values ('Bedroom Units', 'bedroom-units')
  on conflict (name) do update set name = excluded.name
  returning id
)
insert into public.rate_catalogue_items (
  category_id, name, description, specifications, rate, rate_unit, pricing_basis
)
select
  category.id,
  'Standard Bookshelf',
  'Fabrication, supply and installation of standard design Bookshelf using 19 mm Marine Plywood (710 Grade - BWP) / HDHMR for visible shelves and panels, with 16 mm internal box work, complete as per approved design.',
  '{
    "design": "Standard design",
    "dimensions": "To be entered and editable in the quotation",
    "material": "Marine Plywood (710 Grade - BWP) / HDHMR",
    "visible_shelves_and_panels": "19 mm",
    "internal_box_work": "16 mm",
    "rate": 1950.00,
    "rate_unit": "sq.ft.",
    "pricing_basis": "Front elevation area (width x height)",
    "quotation_behavior": "Allow project-specific bookshelf dimensions to be entered and edited in the quotation."
  }'::jsonb,
  1950.00,
  'sq.ft.',
  'Front elevation area (width x height)'
from category
on conflict (category_id, name) do nothing;
