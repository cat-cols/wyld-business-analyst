-- 01_ops_command_center/sql/mart/hr/dim_employee.sql
-- Conformed employee dimension for BI
-- Grain: 1 row per employee_id
--
-- Built from INT labor + timeclock events (event-based punches).
-- Avoids clock_in_at/clock_out_at (not present in event model).

create schema if not exists mart;

create or replace view mart.dim_employee as
with employee_universe as (
  select distinct employee_id
  from int.int_labor_daily_employee
  where employee_id is not null

  union

  select distinct employee_id
  from int.int_timeclock_punches_latest
  where employee_id is not null
),
labor_profile as (
  select
    employee_id,

    min(work_date) as first_work_date,
    max(work_date) as last_work_date,

    count(distinct work_date)::bigint as n_work_days,

    sum(coalesce(hours_worked,0))::numeric as total_hours_worked,
    sum(coalesce(minutes_worked,0))::numeric as total_minutes_worked,

    sum(coalesce(n_events,0))::bigint as total_punch_events,
    sum(coalesce(n_shift_pairs,0))::bigint as total_shift_pairs,

    sum(coalesce(n_unpaired_in,0))::bigint as total_unpaired_in,

    -- lineage rollups
    min(min_ingested_at) as min_ingested_at,
    max(max_ingested_at) as max_ingested_at,
    min(min_drop_date)   as min_drop_date,
    max(max_drop_date)   as max_drop_date
  from int.int_labor_daily_employee
  group by 1
),
labor_last_store as (
  select distinct
    employee_id,
    first_value(store_code) over (
      partition by employee_id
      order by work_date desc nulls last
    ) as last_store_code
  from int.int_labor_daily_employee
),
punch_profile as (
  select
    employee_id,
    min(punch_ts) as first_punch_ts,
    max(punch_ts) as last_punch_ts,
    min(punch_date) as first_punch_date,
    max(punch_date) as last_punch_date
  from int.int_timeclock_punches_latest
  group by 1
)
select
  e.employee_id,

  -- useful “recency” context
  ls.last_store_code,

  lp.first_work_date,
  lp.last_work_date,
  pp.first_punch_ts,
  pp.last_punch_ts,

  lp.n_work_days,
  lp.total_hours_worked,
  lp.total_minutes_worked,
  lp.total_punch_events,
  lp.total_shift_pairs,
  lp.total_unpaired_in,

  case
    when nullif(lp.n_work_days,0) is null then null
    else (lp.total_hours_worked / nullif(lp.n_work_days,0))::numeric
  end as avg_hours_per_workday,

  -- lineage
  lp.min_ingested_at,
  lp.max_ingested_at,
  lp.min_drop_date,
  lp.max_drop_date

from employee_universe e
left join labor_profile lp on lp.employee_id = e.employee_id
left join labor_last_store ls on ls.employee_id = e.employee_id
left join punch_profile pp on pp.employee_id = e.employee_id;


-- -- mart/hr/dim_employee.sql
-- -- Minimal employee dimension derived from timeclock punches.
-- -- Grain: 1 row per employee_id

-- create schema if not exists mart;

-- create or replace view mart.dim_employee as
-- with base as (
--   select
--     employee_id,
--     store_code,
--     clock_in_at,
--     minutes_worked
--   from int.int_timeclock_punches_latest
--   where employee_id is not null
-- ),
-- profile as (
--   select
--     employee_id,
--     min(clock_in_at)::date as first_punch_date,
--     max(clock_in_at)::date as last_punch_date,
--     sum(coalesce(minutes_worked,0)) / 60.0 as lifetime_hours
--   from base
--   group by 1
-- ),
-- current_store as (
--   select
--     employee_id,
--     store_code as store_code_current
--   from (
--     select
--       employee_id,
--       store_code,
--       row_number() over (partition by employee_id order by clock_in_at desc nulls last) as rn
--     from base
--   ) x
--   where rn = 1
-- )
-- select
--   p.employee_id,
--   c.store_code_current,
--   p.first_punch_date,
--   p.last_punch_date,
--   p.lifetime_hours
-- from profile p
-- left join current_store c
--   on c.employee_id = p.employee_id;
