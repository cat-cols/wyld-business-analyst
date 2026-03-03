-- int/hr/int_labor_daily_employee.sql
-- Daily rollup at store/day/employee (+ lineage from punches)
-- Grain: 1 row per work_date + store_code + employee_id

create schema if not exists int;

create or replace view int.int_labor_daily_employee as
with punches as (
  select
    store_code,
    employee_id,
    clock_in_at,
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
    employee_id,

    sum(minutes_worked) / 60.0 as hours_worked,
    count(*) as n_punches,

    min(ingested_at) as min_ingested_at,
    max(ingested_at) as max_ingested_at,
    min(drop_date)   as min_drop_date,
    max(drop_date)   as max_drop_date
  from punches
  group by 1,2,3
)
select * from daily;