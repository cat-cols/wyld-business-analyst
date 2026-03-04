-- mart/core/controls_freshness.sql
-- Freshness control: how recently key upstream/mart datasets were ingested.
--
-- Output: 1 row per model with max_ingested_at/max_drop_date + age + status.
-- Status rules (default):
--   - daily-ish domains (sales/ops/hr): PASS <= 2 days, WARN <= 5 days, else FAIL
--   - finance monthly: PASS <= 40 days, WARN <= 60 days, else FAIL
--
-- If you add/remove marts, update the UNION list in "sources".

create schema if not exists mart;

create or replace view mart.controls_freshness as
with sources as (

  -- SALES
  select
      'mart.fact_sales_distributor_daily'::text as model_name
    , 'sales'::text as domain
    , max(max_ingested_at) as max_ingested_at
    , max(max_drop_date)::date as max_drop_date
  from mart.fact_sales_distributor_daily

  union all

  select
      'mart.fact_sales_pos_daily'
    , 'sales'
    , max(max_ingested_at)
    , max(max_drop_date)::date
  from mart.fact_sales_pos_daily

  -- OPS
  union all

  select
      'mart.fact_inventory_snapshot_daily'
    , 'ops'
    , max(ingested_at)
    , max(drop_date)::date
  from mart.fact_inventory_snapshot_daily

  union all

  select
      'mart.fact_shipments_daily'
    , 'ops'
    , max(max_ingested_at)
    , max(max_drop_date)::date
  from mart.fact_shipments_daily

  union all

  select
      'mart.fact_sku_distribution_status_daily'
    , 'ops'
    , max(ingested_at)
    , max(drop_date)::date
  from mart.fact_sku_distribution_status_daily

  -- HR (labor fact doesn’t carry lineage columns; use INT as the freshness source)
  union all

  select
      'int.int_labor_daily'
    , 'hr'
    , max(max_ingested_at)
    , max(max_drop_date)::date
  from int.int_labor_daily

  union all

  select
      'int.int_timeclock_punches_latest'
    , 'hr'
    , max(ingested_at)
    , max(drop_date)::date
  from int.int_timeclock_punches_latest

  -- FINANCE
  union all

  select
      'mart.fact_actuals_monthly'
    , 'finance'
    , max(max_ingested_at)
    , max(max_drop_date)::date
  from mart.fact_actuals_monthly
),
scored as (
  select
      current_date as run_date
    , s.model_name
    , s.domain
    , s.max_ingested_at
    , s.max_drop_date
    , greatest(
        coalesce(s.max_ingested_at, timestamp '1900-01-01'),
        coalesce(s.max_drop_date::timestamp, timestamp '1900-01-01')
      ) as freshness_ts
  from sources s
),
final as (
  select
      run_date
    , model_name
    , domain
    , max_ingested_at
    , max_drop_date
    , freshness_ts
    , extract(epoch from (current_timestamp - freshness_ts)) / 3600.0 as age_hours
    , (current_date - freshness_ts::date) as age_days
    , case
        when freshness_ts = timestamp '1900-01-01' then 'FAIL'
        when domain = 'finance' and freshness_ts >= (current_timestamp - interval '40 days') then 'PASS'
        when domain = 'finance' and freshness_ts >= (current_timestamp - interval '60 days') then 'WARNING'
        when domain <> 'finance' and freshness_ts >= (current_timestamp - interval '2 days') then 'PASS'
        when domain <> 'finance' and freshness_ts >= (current_timestamp - interval '5 days') then 'WARNING'
        else 'FAIL'
      end as status
  from scored
)
select *
from final
order by
  case status when 'FAIL' then 1 when 'WARNING' then 2 else 3 end,
  domain,
  model_name;