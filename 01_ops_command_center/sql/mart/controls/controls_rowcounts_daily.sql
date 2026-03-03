-- 01_ops_command_center/sql/mart/controls/controls_rowcounts_daily.sql
-- Daily rowcounts by model + grain_date (last ~90 days).
-- Add/remove UNION blocks as your mart grows.

create schema if not exists mart;

create or replace view mart.controls_rowcounts_daily as
with params as (
  select (current_date - 90)::date as start_date
)
, rc as (

  -- Sales (Distributor) daily
  select
      current_date                     as run_date
    , 'mart.fact_sales_distributor_daily'::text as model_name
    , f.sales_date::date               as grain_date
    , count(*)::bigint                 as row_count
  from mart.fact_sales_distributor_daily f
  join params p on f.sales_date::date >= p.start_date
  group by 1,2,3

  union all

  -- Labor daily
  select
      current_date                     as run_date
    , 'mart.fact_labor_daily'::text    as model_name
    , f.work_date::date                as grain_date   -- <-- rename if your date column differs
    , count(*)::bigint                 as row_count
  from mart.fact_labor_daily f
  join params p on f.work_date::date >= p.start_date
  group by 1,2,3

  union all

  -- KPI views (if they’re materialized tables) — otherwise remove.
  select
      current_date                     as run_date
    , 'mart.kpi_sales_per_labor_hour_daily'::text as model_name
    , k.as_of_date::date               as grain_date  -- <-- rename if needed
    , count(*)::bigint                 as row_count
  from mart.kpi_sales_per_labor_hour_daily k
  join params p on k.as_of_date::date >= p.start_date
  group by 1,2,3
)
select *
from rc
order by model_name, grain_date;