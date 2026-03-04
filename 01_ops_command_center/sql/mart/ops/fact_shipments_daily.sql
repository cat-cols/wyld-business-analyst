-- mart/ops/fact_shipments_daily.sql
-- Grain: ship_date + store_code + sku
-- Source: stg.stg_wms_shipments (deduped per shipment_id inside this view)

create schema if not exists mart;

create or replace view mart.fact_shipments_daily as
with ranked as (
  select
    s.*,
    row_number() over (
      partition by
        s.ship_date,
        s.site_code,
        s.sku,
        coalesce(s.shipment_id, s.load_id::text)
      order by
        (s.is_missing_key = false) desc,
        (coalesce(s.is_negative_units,false) = false) desc,
        s.ingested_at desc nulls last,
        s.drop_date desc nulls last,
        s.load_id desc nulls last
    ) as rn
  from stg.stg_wms_shipments s
  where s.ship_date is not null
    and s.site_code is not null
    and s.sku is not null
),
dedup as (
  select *
  from ranked
  where rn = 1
)
select
  ship_date,
  site_code as store_code,
  sku,

  count(*)::bigint as n_source_rows,
  count(distinct shipment_id)::bigint as n_shipments,

  sum(coalesce(units_shipped,0))::numeric as units_shipped,

  -- optional descriptor
  max(carrier) filter (where carrier is not null) as carrier_any,

  max(ingested_at) as max_ingested_at,
  max(drop_date)   as max_drop_date
from dedup
group by 1,2,3;
