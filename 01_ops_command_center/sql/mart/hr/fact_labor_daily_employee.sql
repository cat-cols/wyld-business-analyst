-- mart/hr/fact_labor_daily_employee.sql
-- Grain: work_date + store_code + employee_id
-- Source of truth: int.int_labor_daily_employee

create schema if not exists mart;

create or replace view mart.fact_labor_daily_employee as
select
  work_date,
  store_code,
  employee_id,

  -- measures
  hours_worked,
  minutes_worked,

  -- activity / explainability
  n_events as n_punches,
  n_shift_pairs,
  n_unpaired_in,
  n_out_events,

  -- lineage rollups
  min_ingested_at,
  max_ingested_at,
  min_drop_date,
  max_drop_date

from int.int_labor_daily_employee;
