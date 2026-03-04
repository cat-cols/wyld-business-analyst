-- mart/sales/_fact_distribution_coverage.sql
-- Point-in-time “coverage” spine: store_code x sku over time.
-- Grain: 1 row per as_of_date + store_code + sku (with effective date range helpers)

create schema if not exists mart;

create or replace view mart.fact_distribution_coverage as
with base as (
  select
    as_of_date,
    store_code,
    sku,
    distribution_status,
    status_reason,
    max(ingested_at) over (partition by as_of_date, store_code, sku) as max_ingested_at,
    max(drop_date)   over (partition by as_of_date, store_code, sku) as max_drop_date
  from int.int_sku_distribution_status_dedup
),
typed as (
  select
    b.*,

    -- normalize to a small set of booleans for downstream joins
    (b.distribution_status in ('carried','listed','active','in_distribution','available')) as is_carried,
    (b.distribution_status in ('pending','pending_launch','onboarding')) as is_pending,
    (b.distribution_status in ('not_carried','not_listed','inactive')) as is_not_carried,
    (b.distribution_status in ('discontinued','retired')) as is_discontinued
  from base b
),
ranged as (
  select
    t.*,
    lead(t.as_of_date) over (partition by t.store_code, t.sku order by t.as_of_date) as next_as_of_date
  from typed t
)
select
  as_of_date,
  store_code,
  sku,
  distribution_status,
  status_reason,

  is_carried,
  is_pending,
  is_not_carried,
  is_discontinued,

  -- effective range: [as_of_date, next_as_of_date)
  as_of_date as effective_start_date,
  (next_as_of_date - interval '1 day')::date as effective_end_date,

  max_ingested_at,
  max_drop_date
from ranged;
