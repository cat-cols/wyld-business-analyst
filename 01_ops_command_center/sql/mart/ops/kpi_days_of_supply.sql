-- mart/ops/kpi_days_of_supply.sql
-- Grain: snapshot_date + store_code + sku
-- Definition: on_hand_safe / avg_daily_units_sold over trailing 28 days (incl. snapshot_date)

create schema if not exists mart;

create or replace view mart.kpi_days_of_supply as
with inv as (
  select
    snapshot_date,
    store_code,
    sku,
    on_hand_safe
  from mart.fact_inventory_snapshot_daily
),
sales_daily as (
  select
    sale_date,
    store_code,
    sku,
    sum(coalesce(qty,0))::numeric as units_sold
  from mart.fact_sales_daily
  group by 1,2,3
)
select
  i.snapshot_date,
  i.store_code,
  i.sku,
  i.on_hand_safe,

  s.units_28d,
  (s.units_28d / 28.0)::numeric as avg_daily_units_28d,

  case
    when nullif(s.units_28d,0) is null then null
    else i.on_hand_safe / nullif(s.units_28d / 28.0, 0)
  end as days_of_supply_28d

from inv i
left join lateral (
  select
    sum(sd.units_sold)::numeric as units_28d
  from sales_daily sd
  where sd.store_code = i.store_code
    and sd.sku = i.sku
    and sd.sale_date between (i.snapshot_date - interval '27 day')::date and i.snapshot_date
) s on true;
