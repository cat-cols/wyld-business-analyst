-- int/hr/int_labor_daily.sql
-- Daily rollup at store/day (+ lineage from punches)
-- Grain: work_date + store_code

-- add min_ingested_at / min_drop_date too,
-- so you can detect:
-- “this day stitched from multiple loads” vs “all from one load”

-- (optionally extend to employee granularity)

create schema if not exists int;

create or replace view int.int_labor_daily as
with punches as (
  select
    store_code,
    employee_id,
    clock_in_at,
    clock_out_at,
    minutes_worked,
    ingested_at,
    drop_date
  from int.int_timeclock_punches_latest
  where minutes_worked is not null
),
daily as (
  select
    clock_in_at::date as work_date,
    store_code,

    -- labor measures
    sum(minutes_worked) / 60.0 as hours_worked,
    count(*) as n_punches,
    count(distinct employee_id) as n_employees,

    -- lineage range (lets you detect mixed-load days)
    min(ingested_at) as min_ingested_at,
    max(ingested_at) as max_ingested_at,
    min(drop_date)   as min_drop_date,
    max(drop_date)   as max_drop_date
  from punches
  group by 1,2
)
select * from daily;