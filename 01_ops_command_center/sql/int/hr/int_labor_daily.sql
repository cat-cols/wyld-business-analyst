-- 01_ops_command_center/sql/int/hr/int_labor_daily.sql
-- Grain: work_date + store_code
-- Roll up employee labor to the store/day level.

create schema if not exists int;

create or replace view int.int_labor_daily as
with e as (
  select
    work_date,
    store_code,
    employee_id,
    hours_worked,
    minutes_worked,
    n_shift_pairs,
    n_events,
    n_unpaired_in,
    n_out_events,
    min_ingested_at,
    max_ingested_at,
    min_drop_date,
    max_drop_date
  from int.int_labor_daily_employee
)
select
  work_date,
  store_code,

  sum(coalesce(hours_worked,0))::numeric as hours_worked,
  sum(coalesce(minutes_worked,0))::numeric as minutes_worked,

  count(distinct employee_id)::bigint as n_employees,
  sum(coalesce(n_shift_pairs,0))::bigint as n_shift_pairs,
  sum(coalesce(n_events,0))::bigint as n_events,

  sum(coalesce(n_unpaired_in,0))::bigint as n_unpaired_in,
  sum(coalesce(n_out_events,0))::bigint as n_out_events,

  case when nullif(count(distinct employee_id),0) is null then null
       else (sum(coalesce(hours_worked,0)) / nullif(count(distinct employee_id),0))::numeric
  end as avg_hours_per_employee,

  min(min_ingested_at) as min_ingested_at,
  max(max_ingested_at) as max_ingested_at,
  min(min_drop_date)   as min_drop_date,
  max(max_drop_date)   as max_drop_date

from e
group by 1,2;


-- -- int/hr/int_labor_daily.sql
-- -- Daily rollup at store/day (+ lineage from punches)
-- -- Grain: work_date + store_code

-- -- add min_ingested_at / min_drop_date too,
-- -- so you can detect:
-- -- “this day stitched from multiple loads” vs “all from one load”

-- -- (optionally extend to employee granularity)

-- create schema if not exists int;

-- create or replace view int.int_labor_daily as
-- with punches as (
--   select
--     store_code,
--     employee_id,
--     clock_in_at,
--     clock_out_at,
--     minutes_worked,
--     ingested_at,
--     drop_date
--   from int.int_timeclock_punches_latest
--   where minutes_worked is not null
-- ),
-- daily as (
--   select
--     clock_in_at::date as work_date,
--     store_code,

--     -- labor measures
--     sum(minutes_worked) / 60.0 as hours_worked,
--     count(*) as n_punches,
--     count(distinct employee_id) as n_employees,

--     -- lineage range (lets you detect mixed-load days)
--     min(ingested_at) as min_ingested_at,
--     max(ingested_at) as max_ingested_at,
--     min(drop_date)   as min_drop_date,
--     max(drop_date)   as max_drop_date
--   from punches
--   group by 1,2
-- )
-- select * from daily;