-- int/int_labor_daily.sql
-- Daily rollup at store/day (optionally extend to employee granularity)

create schema if not exists int;

create or replace view int.int_labor_daily as
with punches as (
  select
    store_code,
    employee_id,
    clock_in_at,
    clock_out_at,
    minutes_worked
  from int.int_timeclock_punches_latest
  where minutes_worked is not null
),
daily as (
  select
    (clock_in_at::date) as work_date,
    store_code,

    sum(minutes_worked) / 60.0 as hours_worked,
    count(*) as n_punches,
    count(distinct employee_id) as n_employees
  from punches
  group by 1,2
)
select * from daily;
```