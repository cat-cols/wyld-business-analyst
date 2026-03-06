-- mart/core/dim_sku.sql
-- Conformed SKU dimension built from int truth sources.
-- Grain: 1 row per sku

create schema if not exists mart;

create or replace view mart.dim_sku as
with sku_universe as (
  select distinct sku
  from int.int_sales_distributor_dedup
  where sku is not null

  union

  select distinct sku
  from int.int_sku_distribution_status_dedup
  where sku is not null
),
sales_profile as (
  select
    sku,
    -- choose a stable label if present
    max(product_name) filter (where product_name is not null) as product_name,

    min(sale_date) as first_sale_date,
    max(sale_date) as last_sale_date,

    -- lineage from sales dedup (computed here)
    max(ingested_at) as sales_max_ingested_at, -- ✅🙂 OK: ingested_at exists
    max(drop_date)   as sales_max_drop_date    -- ✅🙂 OK: drop_date exists
  from int.int_sales_distributor_dedup
  group by 1
),
dist_ranked as (
  select
    d.*,
    row_number() over (
      partition by d.sku
      order by
        d.as_of_date desc nulls last,
        d.ingested_at desc nulls last, -- ✅ FIX: use real lineage columns
        d.drop_date desc nulls last,   -- ✅ FIX: use real lineage columns
        d.load_id desc nulls last      -- ✅💡 optional tie-breaker for determinism
    ) as rn
  from int.int_sku_distribution_status_dedup d
),
dist_current as (
  select
    sku,
    as_of_date as distribution_as_of_date,
    distribution_status as distribution_status_current,
    status_reason as distribution_status_reason,

    ingested_at as dist_max_ingested_at, -- ✅ FIX: selected row’s ingested_at
    drop_date   as dist_max_drop_date    -- ✅ FIX: selected row’s drop_date
  from dist_ranked
  where rn = 1
)
select
  u.sku,

  -- descriptive attributes
  sp.product_name,

  -- lifecycle
  sp.first_sale_date,
  sp.last_sale_date,

  -- current distribution context
  dc.distribution_status_current,
  dc.distribution_status_reason,
  dc.distribution_as_of_date,

  -- lineage breadcrumbs
  sp.sales_max_ingested_at,
  sp.sales_max_drop_date,
  dc.dist_max_ingested_at,
  dc.dist_max_drop_date

from sku_universe u
left join sales_profile sp on sp.sku = u.sku
left join dist_current  dc on dc.sku = u.sku;