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
      current_date                          as run_date
    , 'mart.fact_sales_distributor_daily'::text as model_name
    , f.sale_date::date                     as grain_date
    , count(*)::bigint                      as row_count
  from mart.fact_sales_distributor_daily f
  join params p on f.sale_date::date >= p.start_date   -- ✅ FIX: sale_date (not sales_date)
  group by 1,2,3

  union all

  -- Labor daily
  select
      current_date                     as run_date
    , 'mart.fact_labor_daily'::text    as model_name
    , f.work_date::date                as grain_date
    , count(*)::bigint                 as row_count
  from mart.fact_labor_daily f
  join params p on f.work_date::date >= p.start_date   -- ✅🙂 OK
  group by 1,2,3

  union all

  -- KPI: Sales per Labor Hour (daily)
  select
      current_date                             as run_date
    , 'mart.kpi_sales_per_labor_hour_daily'::text as model_name
    , k.kpi_date::date                          as grain_date  -- ✅ FIX: use kpi_date (matches your QA grain)
    , count(*)::bigint                          as row_count
  from mart.kpi_sales_per_labor_hour_daily k
  join params p on k.kpi_date::date >= p.start_date     -- ✅ FIX
  group by 1,2,3
)
select *
from rc
order by model_name, grain_date;


-- -- OLD VERSION: with comments
-- -- 01_ops_command_center/sql/mart/controls/controls_rowcounts_daily.sql
-- -- Daily rowcounts by model + grain_date (last ~90 days).
-- -- Add/remove UNION blocks as your mart grows.

-- create schema if not exists mart;

-- create or replace view mart.controls_rowcounts_daily as
-- with params as (
--   select (current_date - 90)::date as start_date
-- )
-- , rc as (

--   -- Sales (Distributor) daily
--   select
--       current_date                     as run_date
--     , 'mart.fact_sales_distributor_daily'::text as model_name
--     , f.sale_date::date               as grain_date
--     , count(*)::bigint                 as row_count
--   from mart.fact_sales_distributor_daily f
--   join params p on f.sales_date::date >= p.start_date  -- ❌ sales_date doesn't exist; should be sale_date
--   group by 1,2,3

--   union all

--   -- Labor daily
--   select
--       current_date                     as run_date
--     , 'mart.fact_labor_daily'::text    as model_name
--     , f.work_date::date                as grain_date
--     , count(*)::bigint                 as row_count
--   from mart.fact_labor_daily f
--   join params p on f.work_date::date >= p.start_date   -- ✅🙂 good
--   group by 1,2,3

--   union all

--   -- KPI views (if they’re materialized tables) — otherwise remove.
--   select
--       current_date                     as run_date
--     , 'mart.kpi_sales_per_labor_hour_daily'::text as model_name
--     , k.as_of_date::date               as grain_date  -- ⚠️🤔 likely wrong column name (often kpi_date or sale_date)
--     , count(*)::bigint                 as row_count
--   from mart.kpi_sales_per_labor_hour_daily k
--   join params p on k.as_of_date::date >= p.start_date  -- ⚠️🤔 same likely issue
--   group by 1,2,3
-- )
-- select *
-- from rc
-- order by model_name, grain_date;