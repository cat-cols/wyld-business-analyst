-- mart/hr/fact_timeclock_punches.sql
-- Grain: 1 row per punch (truth-selected)
-- Source of truth: int.int_timeclock_punches_latest
--
-- Notes:
-- - This is a thin MART wrapper so Power BI can browse punches directly.
-- - Labor rollups should come from mart.fact_labor_daily / mart.fact_labor_daily_employee.

create schema if not exists mart;

create or replace view mart.fact_timeclock_punches as
select
  -- keys / grain
  p.punch_id,
  p.employee_id,
  p.store_code,

  -- timestamps
  p.clock_in_at,
  p.clock_out_at,
  p.clock_in_at::date as work_date,

  -- measures
  p.minutes_worked,
  (p.minutes_worked / 60.0)::numeric as hours_worked,

  -- optional descriptors (keep if present in INT)
  p.job_code,
  p.role_name,

  -- lineage
  p.load_id,
  p.source_system,
  p.cadence,
  p.drop_date,
  p.ingested_at,

  -- QA / truth-selection flags (keep if present in INT)
  p.is_missing_key,
  p.is_duplicate_candidate,
  p.selected_rank,
  p.dup_group_size

from int.int_timeclock_punches_latest p
where p.punch_id is not null;