-- 01_ops_command_center/sql/int/hr/int_labor_daily_employee.sql
-- Grain: work_date + store_code + employee_id
-- Compute worked time by pairing IN -> next OUT using ordered events.

create schema if not exists int;

create or replace view int.int_labor_daily_employee as
with events as (
  select
    p.store_code,
    p.employee_id,
    p.punch_date::date as work_date,
    p.punch_ts,
    upper(p.action) as action,

    -- lineage (keep if present)
    p.load_id,
    p.drop_date,
    p.ingested_at
  from int.int_timeclock_punches_latest p
  where p.store_code is not null
    and p.employee_id is not null
    and p.punch_date is not null
    and p.punch_ts is not null
    and p.action is not null
),
ordered as (
  select
    e.*,
    lead(e.action)   over (partition by e.store_code, e.employee_id order by e.punch_ts) as next_action,
    lead(e.punch_ts) over (partition by e.store_code, e.employee_id order by e.punch_ts) as next_ts
  from events e
),
pairs as (
  -- // Count minutes ONLY when we have an IN immediately followed by an OUT
  select
    store_code,
    employee_id,
    work_date,
    punch_ts as clock_in_at,
    next_ts  as clock_out_at,
    greatest(extract(epoch from (next_ts - punch_ts)) / 60.0, 0)::numeric as minutes_worked,

    load_id,
    drop_date,
    ingested_at
  from ordered
  where action = 'IN'
    and next_action = 'OUT'
    and next_ts is not null
    and next_ts >= punch_ts
),
agg as (
  select
    work_date,
    store_code,
    employee_id,

    sum(minutes_worked)::numeric as minutes_worked,
    (sum(minutes_worked) / 60.0)::numeric as hours_worked,

    count(*)::bigint as n_shift_pairs,

    -- event counts + anomaly hints
    (select count(*) from events e
      where e.work_date = p.work_date
        and e.store_code = p.store_code
        and e.employee_id = p.employee_id
    )::bigint as n_events,

    (select count(*) from ordered o
      where o.work_date = p.work_date
        and o.store_code = p.store_code
        and o.employee_id = p.employee_id
        and o.action = 'IN'
        and (o.next_action is distinct from 'OUT' or o.next_ts is null)
    )::bigint as n_unpaired_in,

    (select count(*) from events e
      where e.work_date = p.work_date
        and e.store_code = p.store_code
        and e.employee_id = p.employee_id
        and e.action = 'OUT'
    )::bigint as n_out_events,

    -- lineage rollups
    min(ingested_at) as min_ingested_at,
    max(ingested_at) as max_ingested_at,
    min(drop_date)   as min_drop_date,
    max(drop_date)   as max_drop_date
  from pairs p
  group by 1,2,3
)
select *
from agg;


-- -- int/hr/int_labor_daily_employee.sql
-- -- Daily rollup at store/day/employee (+ lineage from punches)
-- -- Grain: 1 row per work_date + store_code + employee_id

-- create schema if not exists int;

-- create or replace view int.int_labor_daily_employee as
-- with punches as (
--   select
--     store_code,
--     employee_id,
--     clock_in_at,
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
--     employee_id,

--     sum(minutes_worked) / 60.0 as hours_worked,
--     count(*) as n_punches,

--     min(ingested_at) as min_ingested_at,
--     max(ingested_at) as max_ingested_at,
--     min(drop_date)   as min_drop_date,
--     max(drop_date)   as max_drop_date
--   from punches
--   group by 1,2,3
-- )
-- select * from daily;