-- mart/ops/kpi_instock_rate_daily.sql
-- Grain: snapshot_date + store_code
-- Purpose: operational KPI for inventory health.

create schema if not exists mart;

create or replace view mart.kpi_instock_rate_daily as
with inv as (
  select
    snapshot_date,
    store_code,
    sku,
    on_hand_safe,
    in_stock_flag
  from mart.fact_inventory_snapshot_daily
),
cov as (
  select
    as_of_date,
    store_code,
    sku,
    is_carried
  from mart.fact_distribution_coverage
),
joined as (
  select
    i.snapshot_date,
    i.store_code,
    i.sku,
    i.in_stock_flag,
    coalesce(c.is_carried, false) as is_carried
  from inv i
  left join cov c
    on c.as_of_date = i.snapshot_date
   and c.store_code = i.store_code
   and c.sku = i.sku
),
agg as (
  select
    snapshot_date,
    store_code,

    count(*)::bigint as n_skus_in_inventory,
    count(*) filter (where in_stock_flag)::bigint as n_skus_in_stock,

    count(*) filter (where is_carried)::bigint as n_skus_carried,
    count(*) filter (where is_carried and in_stock_flag)::bigint as n_carried_skus_in_stock
  from joined
  group by 1,2
)
select
  snapshot_date,
  store_code,

  n_skus_in_inventory,
  n_skus_in_stock,

  case when nullif(n_skus_in_inventory,0) is null then null
       else n_skus_in_stock::numeric / nullif(n_skus_in_inventory,0)
  end as instock_rate_inventory_universe,

  n_skus_carried,
  n_carried_skus_in_stock,

  case when nullif(n_skus_carried,0) is null then null
       else n_carried_skus_in_stock::numeric / nullif(n_skus_carried,0)
  end as instock_rate_carried_universe
from agg;
