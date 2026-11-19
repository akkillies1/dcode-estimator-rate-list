-- Update TV Unit Ledge catalogue construction and pricing basis.
-- The rate remains 1050, but is now expressed per running foot.

UPDATE public.rate_catalogue_items AS item
SET
  description = 'Fabrication, supply and installation of TV Unit Ledge using 4 cm thick Marine Plywood, complete as per approved design.',
  specifications = jsonb_build_object(
    'material', 'Marine Plywood only',
    'thickness', '4 cm'
  ),
  rate = 1050,
  rate_unit = 'running foot',
  pricing_basis = 'Length of ledge'
FROM public.rate_catalogue_categories AS category
WHERE item.category_id = category.id
  AND category.slug = 'tv-units'
  AND item.name = 'TV Unit Ledge';
