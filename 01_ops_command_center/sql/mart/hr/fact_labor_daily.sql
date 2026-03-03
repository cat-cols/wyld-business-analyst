-- mart/hr/fact_labor_daily.sql
-- Grain: 1 row per work_date + store_code
-- Source of truth: int.int_labor_daily

-- Build fact_labor (grain: date x location x employee_group)

-- Grain: 1 row per work_date + store_code


create schema if not exists mart;

create or replace view mart.fact_labor_daily as
select
  work_date,
  store_code,

  hours_worked,
  n_punches,
  n_employees
from int.int_labor_daily;