-- 01_ops_command_center/sql/mart/hr/fact_labor_daily.sql
-- Grain: 1 row per work_date + store_code
-- Source of truth: int.int_labor_daily (derived from timeclock IN/OUT event pairing)

create schema if not exists mart;

create or replace view mart.fact_labor_daily as
select
  work_date,
  store_code,

  -- measures
  hours_worked,
  minutes_worked,

  -- headcount / activity
  n_employees,
  n_events      as n_punches,      -- ✅ map event count to expected mart column name
  n_shift_pairs as n_shift_pairs,  -- keep the more specific metric too

  -- anomaly/debug helpers (useful for QA)
  n_unpaired_in,
  n_out_events,

  -- derived
  avg_hours_per_employee,

  -- lineage
  max_ingested_at,
  max_drop_date
from int.int_labor_daily;

-- OLD VERSION
-- -- mart/hr/fact_labor_daily.sql
-- -- Grain: 1 row per work_date + store_code
-- -- Source of truth: int.int_labor_daily

-- -- Build fact_labor (grain: date x location x employee_group)

-- -- Grain: 1 row per work_date + store_code


-- create schema if not exists mart;

-- create or replace view mart.fact_labor_daily as
-- select
--   work_date,
--   store_code,

--   hours_worked,
--   n_punches,
--   n_employees
-- from int.int_labor_daily;