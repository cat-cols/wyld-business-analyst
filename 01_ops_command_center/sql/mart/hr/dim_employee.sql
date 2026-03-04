-- mart/hr/dim_employee.sql
-- Minimal employee dimension derived from timeclock punches.
-- Grain: 1 row per employee_id

create schema if not exists mart;

create or replace view mart.dim_employee as
with base as (
  select
    employee_id,
    store_code,
    clock_in_at,
    minutes_worked
  from int.int_timeclock_punches_latest
  where employee_id is not null
),
profile as (
  select
    employee_id,
    min(clock_in_at)::date as first_punch_date,
    max(clock_in_at)::date as last_punch_date,
    sum(coalesce(minutes_worked,0)) / 60.0 as lifetime_hours
  from base
  group by 1
),
current_store as (
  select
    employee_id,
    store_code as store_code_current
  from (
    select
      employee_id,
      store_code,
      row_number() over (partition by employee_id order by clock_in_at desc nulls last) as rn
    from base
  ) x
  where rn = 1
)
select
  p.employee_id,
  c.store_code_current,
  p.first_punch_date,
  p.last_punch_date,
  p.lifetime_hours
from profile p
left join current_store c
  on c.employee_id = p.employee_id;
