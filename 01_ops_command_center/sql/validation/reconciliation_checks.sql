-- 01_ops_command_center/sql/validation/reconciliation_checks.sql
-- Standardized reconciliation/control output for Project 1.
--
-- Creates:
--   1) validation.reconciliation_checks
--   2) validation.reconciliation_summary
--
-- Purpose:
-- - unify exact int->mart / stg->mart checks
-- - surface detailed mart recon views in one contract
-- - make fails/warnings easy to scan before report-layer work
--
-- Notes:
-- - Some finance recon rows may fail until finance actuals generation is aligned to modeled truth.
-- - This file does not replace QA hard-fail scripts; it gives you a cleaner debugging surface.

-- Step 1: Build this file as a single canonical view
-- Step 2: Reuse existing mart/control views where possible
-- Step 3: Hardcode tolerances in V1

create schema if not exists validation;

create or replace view validation.reconciliation_checks as
with params as (
  select
      0.020::numeric as sales_gl_tolerance_pct
),

-- =========================================================
-- Exact latest-common-date reconciliations
-- =========================================================
sales_dist_latest as (
  select least(
    (select max(sale_date)::date from int.int_sales_distributor_dedup),
    (select max(sale_date)::date from mart.fact_sales_distributor_daily)
  ) as check_date
),
sales_dist_int_vs_mart as (
  select
      current_date::date as run_date
    , 'recon'::text as check_group
    , 'int_vs_mart:sales_distributor_net_sales'::text as check_name
    , 'day'::text as grain
    , d.check_date
    , null::text as entity_key
    , 'int.int_sales_distributor_dedup'::text as source_object
    , 'mart.fact_sales_distributor_daily'::text as modeled_object
    , (
        select sum(coalesce(net_sales,0))::numeric
        from int.int_sales_distributor_dedup
        where sale_date::date = d.check_date
      ) as source_total
    , (
        select sum(coalesce(net_sales,0))::numeric
        from mart.fact_sales_distributor_daily
        where sale_date::date = d.check_date
      ) as modeled_total
    , 0::numeric as tolerance_pct
    , 'Exact same-day distributor sales total should match between int and mart.'::text as notes
  from sales_dist_latest d
),

pos_latest as (
  select least(
    (select max(txn_date)::date from int.int_pos_dedup),
    (select max(sale_date)::date from mart.fact_sales_pos_daily)
  ) as check_date
),
pos_int_vs_mart as (
  select
      current_date::date as run_date
    , 'recon'::text as check_group
    , 'int_vs_mart:pos_net_sales'::text as check_name
    , 'day'::text as grain
    , d.check_date
    , null::text as entity_key
    , 'int.int_pos_dedup'::text as source_object
    , 'mart.fact_sales_pos_daily'::text as modeled_object
    , (
        select sum(coalesce(net_amount,0))::numeric
        from int.int_pos_dedup
        where txn_date::date = d.check_date
      ) as source_total
    , (
        select sum(coalesce(net_sales,0))::numeric
        from mart.fact_sales_pos_daily
        where sale_date::date = d.check_date
      ) as modeled_total
    , 0::numeric as tolerance_pct
    , 'Exact same-day POS net sales total should match between int and mart.'::text as notes
  from pos_latest d
),

labor_latest as (
  select least(
    (select max(work_date)::date from int.int_labor_daily),
    (select max(work_date)::date from mart.fact_labor_daily)
  ) as check_date
),
labor_int_vs_mart as (
  select
      current_date::date as run_date
    , 'recon'::text as check_group
    , 'int_vs_mart:labor_hours'::text as check_name
    , 'day'::text as grain
    , d.check_date
    , null::text as entity_key
    , 'int.int_labor_daily'::text as source_object
    , 'mart.fact_labor_daily'::text as modeled_object
    , (
        select sum(coalesce(hours_worked,0))::numeric
        from int.int_labor_daily
        where work_date::date = d.check_date
      ) as source_total
    , (
        select sum(coalesce(hours_worked,0))::numeric
        from mart.fact_labor_daily
        where work_date::date = d.check_date
      ) as modeled_total
    , 0::numeric as tolerance_pct
    , 'Exact same-day labor hours should match between int and mart.'::text as notes
  from labor_latest d
),

inventory_latest as (
  select least(
    (select max(snapshot_date)::date from int.int_inventory_snapshot_dedup),
    (select max(snapshot_date)::date from mart.fact_inventory_snapshot_daily)
  ) as check_date
),
inventory_int_vs_mart as (
  select
      current_date::date as run_date
    , 'recon'::text as check_group
    , 'int_vs_mart:inventory_on_hand_safe'::text as check_name
    , 'day'::text as grain
    , d.check_date
    , null::text as entity_key
    , 'int.int_inventory_snapshot_dedup'::text as source_object
    , 'mart.fact_inventory_snapshot_daily'::text as modeled_object
    , (
        select sum(coalesce(on_hand_nonnegative,0))::numeric
        from int.int_inventory_snapshot_dedup
        where snapshot_date::date = d.check_date
      ) as source_total
    , (
        select sum(coalesce(on_hand_safe,0))::numeric
        from mart.fact_inventory_snapshot_daily
        where snapshot_date::date = d.check_date
      ) as modeled_total
    , 0::numeric as tolerance_pct
    , 'Exact same-day safe inventory total should match between int and mart.'::text as notes
  from inventory_latest d
),

finance_latest as (
  select least(
    (select max(period_month)::date from stg.stg_finance_actuals),
    (select max(period_month)::date from mart.fact_actuals_monthly)
  ) as check_date
),
finance_stg_vs_mart as (
  select
      current_date::date as run_date
    , 'recon'::text as check_group
    , 'stg_vs_mart:finance_actuals_total'::text as check_name
    , 'month'::text as grain
    , d.check_date
    , null::text as entity_key
    , 'stg.stg_finance_actuals'::text as source_object
    , 'mart.fact_actuals_monthly'::text as modeled_object
    , (
        select sum(coalesce(actual_amount,0))::numeric
        from stg.stg_finance_actuals
        where period_month::date = d.check_date
      ) as source_total
    , (
        select sum(coalesce(actual_amount,0))::numeric
        from mart.fact_actuals_monthly
        where period_month::date = d.check_date
      ) as modeled_total
    , 0::numeric as tolerance_pct
    , 'Exact same-month finance actuals total should match between stg and mart.'::text as notes
  from finance_latest d
),

base_exact as (
  select * from sales_dist_int_vs_mart
  union all
  select * from pos_int_vs_mart
  union all
  select * from labor_int_vs_mart
  union all
  select * from inventory_int_vs_mart
  union all
  select * from finance_stg_vs_mart
),

base_exact_scored as (
  select
      run_date
    , check_group
    , check_name
    , grain
    , check_date
    , entity_key
    , source_object
    , modeled_object
    , source_total
    , modeled_total
    , (coalesce(modeled_total,0) - coalesce(source_total,0))::numeric as delta_amount
    , case
        when greatest(abs(coalesce(source_total,0)), abs(coalesce(modeled_total,0))) = 0 then 0::numeric
        else (
          abs(coalesce(modeled_total,0) - coalesce(source_total,0))
          / nullif(greatest(abs(coalesce(source_total,0)), abs(coalesce(modeled_total,0))), 0)
        )::numeric
      end as delta_pct
    , tolerance_pct
    , case
        when source_total is null then 'Fail'
        when modeled_total is null then 'Fail'
        when coalesce(modeled_total,0) = coalesce(source_total,0) then 'Pass'
        else 'Fail'
      end as status
    , case
        when source_total is null then 'FAIL_missing_source'
        when modeled_total is null then 'FAIL_missing_modeled'
        when coalesce(modeled_total,0) = coalesce(source_total,0) then 'PASS'
        else 'FAIL_mismatch'
      end as status_detail
    , notes
  from base_exact
),

-- =========================================================
-- Existing mart recon / controls, standardized
-- =========================================================
dist_vs_pos_detail as (
  select
      current_date::date as run_date
    , 'recon'::text as check_group
    , 'mart:distributor_vs_pos:net_sales'::text as check_name
    , 'store_day'::text as grain
    , sale_date as check_date
    , store_code::text as entity_key
    , 'mart.fact_sales_distributor_daily'::text as source_object
    , 'mart.fact_sales_pos_daily'::text as modeled_object
    , dist_net_sales::numeric as source_total
    , pos_net_sales::numeric as modeled_total
    , delta_net_sales::numeric as delta_amount
    , delta_pct_net_sales::numeric as delta_pct
    , tolerance_pct::numeric as tolerance_pct
    , case
        when lower(status) like 'pass%' then 'Pass'
        when lower(status) like 'warn%' then 'Warning'
        else 'Fail'
      end as status
    , status::text as status_detail
    , 'Distributor vs POS same-store same-day net sales reconciliation.'::text as notes
  from mart.recon_sales_distributor_vs_pos
),

sales_to_gl_detail as (
  select
      current_date::date as run_date
    , 'recon'::text as check_group
    , ('mart:sales_to_gl:' || metric)::text as check_name
    , 'month_metric'::text as grain
    , period_month as check_date
    , metric::text as entity_key
    , 'mart.fact_sales_distributor_daily'::text as source_object
    , 'mart.fact_actuals_monthly'::text as modeled_object
    , mart_amount::numeric as source_total
    , gl_amount::numeric as modeled_total
    , diff_amount::numeric as delta_amount
    , pct_diff::numeric as delta_pct
    , (select sales_gl_tolerance_pct from params) as tolerance_pct
    , case
        when lower(status) like 'pass%' then 'Pass'
        when lower(status) like 'warn%' then 'Warning'
        else 'Fail'
      end as status
    , status::text as status_detail
    , 'Monthly sales-vs-GL reconciliation by metric.'::text as notes
  from mart.recon_sales_to_gl_monthly
),

missing_dim_detail as (
  select
      run_date::date as run_date
    , 'control'::text as check_group
    , ('control:missing_dim_join:' || model_name || ':' || dim_name)::text as check_name
    , 'model_day_dim'::text as grain
    , grain_date::date as check_date
    , dim_name::text as entity_key
    , model_name::text as source_object
    , dim_name::text as modeled_object
    , fact_rows::numeric as source_total
    , (fact_rows - missing_dim_rows)::numeric as modeled_total
    , missing_dim_rows::numeric as delta_amount
    , missing_pct::numeric as delta_pct
    , 0.001::numeric as tolerance_pct
    , case
        when lower(status) like 'pass%' then 'Pass'
        when lower(status) like 'warn%' then 'Warning'
        else 'Fail'
      end as status
    , status::text as status_detail
    , 'Fact rows that do not join cleanly to required dimensions.'::text as notes
  from mart.controls_missing_dim_joins
),

freshness_detail as (
  select
      run_date::date as run_date
    , 'control'::text as check_group
    , ('control:freshness:' || model_name)::text as check_name
    , 'model'::text as grain
    , latest_date::date as check_date
    , model_name::text as entity_key
    , model_name::text as source_object
    , null::text as modeled_object
    , null::numeric as source_total
    , null::numeric as modeled_total
    , days_lag::numeric as delta_amount
    , null::numeric as delta_pct
    , null::numeric as tolerance_pct
    , case
        when lower(status) like 'pass%' then 'Pass'
        when lower(status) like 'warn%' then 'Warning'
        else 'Fail'
      end as status
    , status::text as status_detail
    , 'Freshness check on latest available date in each mart model.'::text as notes
  from mart.controls_freshness
)

select * from base_exact_scored
union all
select * from dist_vs_pos_detail
union all
select * from sales_to_gl_detail
union all
select * from missing_dim_detail
union all
select * from freshness_detail
;

create or replace view validation.reconciliation_summary as
select
    check_group
  , check_name
  , status
  , count(*)::bigint as row_count
  , min(check_date) as min_check_date
  , max(check_date) as max_check_date
  , sum(abs(coalesce(delta_amount,0)))::numeric as total_abs_delta
  , max(delta_pct) as max_delta_pct
from validation.reconciliation_checks
group by 1,2,3
order by check_group, check_name, status;


-- Suggested usage:
-- select *
-- from validation.reconciliation_checks
-- where status <> 'Pass'
-- order by check_group, check_date desc, check_name, entity_key;
--
-- select *
-- from validation.reconciliation_summary
-- where status <> 'Pass'
-- order by check_group, check_name, status;


-- NOTES:

-- Null keys, duplicates, negative values, source-vs-modeled checks
    -- check things like:
    -- distributor sales vs POS sales tolerance
    -- sales vs GL / actuals alignment
    -- row-count sanity across core facts
    -- missing dimension joins
    -- freshness failures
    -- duplicate grain checks
    -- null key checks
    -- negative value checks where not expected
----

-- # Goal of `reconciliation_checks.sql`

-- Create **one canonical validation output** that answers:

-- **“Do the modeled numbers reconcile to the sources closely enough to trust reporting?”**

-- This file should not be a junk drawer of random tests.
-- Its job is to standardize the **highest-value reconciliation and control checks** into one clean result set.

-- For V1, keep it focused.

-- ---

-- # V1 scope: exact 5 check families

-- Use these five:

-- 1. **sales_distributor_vs_pos_daily**
-- 2. **sales_to_gl_monthly**
-- 3. **missing_dim_joins**
-- 4. **fact_freshness**
-- 5. **fact_grain_uniqueness**

-- That is enough to make the project feel real and trustworthy.

-- ---

-- # Clean result schema

-- Use one shared schema for every check row:

-- ```sql
-- run_date        date
-- check_name      text
-- domain          text
-- check_date      date
-- source_total    numeric
-- modeled_total   numeric
-- delta_amount    numeric
-- delta_pct       numeric
-- tolerance_pct   numeric
-- status          text
-- ```

-- ## What each field means

-- * `run_date`: the date the validation ran
-- * `check_name`: unique check identifier
-- * `domain`: sales / finance / controls
-- * `check_date`: business date or month being checked
-- * `source_total`: source-side total or benchmark
-- * `modeled_total`: mart / modeled-side total
-- * `delta_amount`: `modeled_total - source_total`
-- * `delta_pct`: `(modeled_total - source_total) / source_total`
-- * `tolerance_pct`: allowed variance
-- * `status`: `PASS` or `FAIL`

-- For V1, I’d keep **only PASS/FAIL**.
-- You can add `WARN` later once the foundations stop wobbling.

-- ---

-- # Core design rule

-- Each check should output rows in the **same column order and data types** so you can `UNION ALL` them into one final view.

-- That means each individual check CTE should end with the same shaped `SELECT`.

-- No special snowflake columns. No one-off formats. No “I’ll fix it later” goblins.

-- ---

-- # Best approach

-- ## Step 1: Build this file as a single canonical view

-- I’d have `sql/validation/reconciliation_checks.sql` create:

-- ```sql
-- create or replace view mart.mart_reconciliation_controls as
-- ...
-- ```

-- Why?

-- Because you already think of this as a business-facing controls object, and that name is strong for:

-- * QA
-- * debugging
-- * resume language
-- * stakeholder walkthroughs

-- ---

-- # Step 2: Reuse existing mart/control views where possible

-- Do **not** rebuild every calculation from raw tables inside this file.

-- Use your existing upstream assets whenever possible:

-- * `mart.recon_sales_distributor_vs_pos`
-- * `mart.recon_sales_to_gl_monthly`
-- * `mart.controls_missing_dim_joins`
-- * `mart.controls_freshness` if it exists
-- * existing mart facts for uniqueness checks

-- This file should be a **validation unifier**, not a second modeling layer.

-- ---

-- # Step 3: Hardcode tolerances in V1

-- Do not overengineer tolerance config yet.

-- Use simple hardcoded tolerances first:

-- * `sales_distributor_vs_pos_daily` → `0.02`
-- * `sales_to_gl_monthly` → `0.01`
-- * `missing_dim_joins` → `0.00`
-- * `fact_freshness` → `0.00`
-- * `fact_grain_uniqueness` → `0.00`

-- Later, you can externalize tolerances into a reference table if you want.

-- ---

-- # The exact 5 checks

-- ## 1. `recon:sales_distributor_vs_pos_daily`

-- ### Purpose

-- Validate that distributor-modeled sales reconcile reasonably to POS sales at a daily level.

-- ### Grain

-- One row per `sale_date`

-- ### Inputs

-- Prefer an existing reconciliation view if you have one:

-- * `mart.recon_sales_distributor_vs_pos`

-- ### Recommended fields

-- * `source_total` = POS net sales
-- * `modeled_total` = distributor-modeled net sales

-- ### Status rule

-- * `PASS` if `abs(delta_pct) <= 0.02`
-- * else `FAIL`

-- ### Notes

-- Use daily grain for V1.
-- Do not overcomplicate with store/SKU splits yet unless your recon view already supports it cleanly.

-- ---

-- ## 2. `recon:sales_to_gl_monthly`

-- ### Purpose

-- Validate that modeled sales align to GL / finance-level monthly totals.

-- ### Grain

-- One row per month

-- ### Inputs

-- * `mart.recon_sales_to_gl_monthly`

-- ### Recommended fields

-- * `source_total` = GL / actuals total
-- * `modeled_total` = modeled sales total

-- ### Status rule

-- * `PASS` if `abs(delta_pct) <= 0.01`
-- * else `FAIL`

-- ### Notes

-- Monthly is the right grain here because finance reconciliation usually lives better at month level than day level.

-- ---

-- ## 3. `control:missing_dim_joins`

-- ### Purpose

-- Catch facts that fail to join to required dimensions.

-- ### Grain

-- One row per fact table checked

-- ### Inputs

-- * `mart.controls_missing_dim_joins`

-- ### Recommended interpretation

-- Because this is not a “source vs modeled dollars” check, use the schema like this:

-- * `source_total` = rows checked
-- * `modeled_total` = rows successfully joined
-- * `delta_amount` = missing join rows
-- * `delta_pct` = missing join rows / rows checked

-- ### Status rule

-- * `PASS` if missing join rows = 0
-- * else `FAIL`

-- ### Notes

-- This is one of the most valuable controls in the whole repo. It screams “I understand semantic/reporting risk.”

-- ---

-- ## 4. `control:freshness`

-- ### Purpose

-- Ensure key facts are recent enough to support trusted reporting.

-- ### Grain

-- One row per fact table

-- ### Inputs

-- If you already have a freshness view, use it.
-- If not, build a tiny inline CTE over your core facts.

-- ### Recommended interpretation

-- Use numeric lag values so the schema still makes sense:

-- * `check_date` = latest business date in the fact
-- * `source_total` = allowed lag days
-- * `modeled_total` = actual lag days
-- * `delta_amount` = actual lag days - allowed lag days
-- * `delta_pct` = optional; can be null if you want
-- * `tolerance_pct` = 0

-- ### Status rule

-- * `PASS` if actual lag days <= allowed lag days
-- * else `FAIL`

-- ### Suggested facts for V1

-- * `mart.fact_sales_distributor_daily`
-- * `mart.fact_labor_daily`
-- * `mart.fact_actuals_monthly`

-- ### Notes

-- This is much better than leaving freshness as a vague doc idea.

-- ---

-- ## 5. `control:grain_uniqueness`

-- ### Purpose

-- Ensure facts are unique at their declared grain.

-- ### Grain

-- One row per fact table

-- ### Inputs

-- Build inline from your fact tables using the grain documented in each file header.

-- ### Recommended interpretation

-- * `source_total` = total rows checked
-- * `modeled_total` = distinct grain rows
-- * `delta_amount` = duplicate rows
-- * `delta_pct` = duplicate rows / total rows checked

-- ### Status rule

-- * `PASS` if duplicate rows = 0
-- * else `FAIL`

-- ### Suggested facts for V1

-- Start with 2–3 core facts only:

-- * `mart.fact_sales_distributor_daily`
-- * `mart.fact_labor_daily`
-- * `mart.kpi_sales_per_labor_hour_daily`

-- ### Notes

-- Do not check every table in the repo on day one.
-- Pick the core reporting facts first.
