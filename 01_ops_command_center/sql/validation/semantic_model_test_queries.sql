-- sql/validation/semantic_model_test_queries.sql
-- 01_ops_command_center/sql/validation/semantic_model_test_queries.sql
--
-- Purpose:
-- SQL source-of-truth pack for validating future semantic-model outputs
-- and business-facing report objects.
--
-- Design rules:
-- - query mart facts / KPI marts directly
-- - keep one clear grain per query
-- - keep outputs readable and sortable
-- - use safe denominator logic
-- - include executive totals, KPI references, recon references, and grain sanity

-- SQL totals used to validate Power BI visuals
-- check things like:
-- distributor sales vs POS sales tolerance
-- sales vs GL / actuals alignment
-- row-count sanity across core facts
-- missing dimension joins
-- freshnes failures
-- duplicate grain checks
-- null key checks
-- negative value checks where not expected

-- 2. semantic_model_test_queries.sql
-- This should become your SQL source-of-truth pack for future dashboard validation.

-- It should answer:
-- what total net sales should equal
-- what total gross margin should equal
-- what labor hours should equal
-- what in-stock rate should equal
-- what sales per labor hour should equal
-- what days of supply should equal

-----------------------------------------------------------

-- What the file should cover
-- For V1, your queries should validate the most important outputs of the flagship project.

-- Minimum coverage

-- You want at least one query for each of these:
-- Sales totals
-- Margin totals
-- Labor totals
-- Productivity KPI
-- Inventory health KPI
-- Reconciliation-facing totals
-- Grain sanity

--------------------------------------------------------------------------
----- -- Common mistakes to avoid ---------- ----- ----- ----- -----------
------- --  DO NOT:----- -- ----- -- ----- ------- ----- ----- ----- -----
--------------------------------------------------------------------------

-- dump dozens of random exploratory queries
-- recompute every KPI from scratch without reason
-- use raw/staging tables for everything
-- leave query intent undocumented
-- mix five different grains in one output
-- write one giant mega-query that nobody can read
-- include placeholder comments with no real SQL

-- You got it right if:
-- DO:
-- The file contains 8–12 clear reference queries
-- Each query has purpose + grain comments
-- Each query maps to a likely report object or KPI
-- Outputs are readable and sorted
-- Derived metrics use safe denominator logic
-- Core facts/KPI marts are queried directly
-- At least one cross-functional KPI is included
-- At least one grain sanity query is included
-- At least one reconciliation-facing query is included
-- A future Power BI report could be compared directly to these outputs

--------------------------------------------------------------------------
----- Best V1 query set: These are the queries I would include first -----
--------------------------------------------------------------------------

-- 1. Net sales by month
-- Business question: What should total monthly net sales equal?
-- Why it matters: This is the most basic executive card/chart validation.
-- Suggested source: mart.fact_sales_distributor_daily
-- Output grain: month

-- 2. Gross sales by month
-- Business question: What should total monthly gross sales equal?
-- Why it matters: Lets you validate discounts and sales logic separately from net sales.
-- Suggested source: mart.fact_sales_distributor_daily
-- Output grain: month

-- 3. Gross margin dollars and gross margin percent by month
-- Business question: What should gross margin look like by month?
-- Why it matters: This is a core finance KPI and good semantic-model test.
-- Suggested source: Your gross margin mart/KPI view
-- Output grain: month

-- 4. Labor hours and labor cost by month
-- Business question: What should labor totals equal?
-- Why it matters: Validates the labor fact and later lets you test joined KPI models.
-- Suggested source: mart.fact_labor_daily
-- Output grain: month

-- 5. Net sales per labor hour by month
-- Business question: What should the productivity KPI equal?
-- Why it matters: This is one of your strongest cross-functional KPIs.
-- Suggested source: mart.kpi_sales_per_labor_hour_daily
-- Output grain: month

-- 6. In-stock rate by snapshot date
-- Business question:What should inventory availability equal?
-- Why it matters:Tests ops KPIs and non-sales semantic logic.
-- Suggested source:mart.kpi_instock_rate_daily
-- Output grain:snapshot date

-- 7. Days of supply by SKU/date or summary bucket
-- Business question:What should days of supply equal?
-- Why it matters:Tests calculation logic and dimensional behavior.
-- Suggested source:mart.kpi_days_of_supply
-- Output grain:start with summary output, not huge SKU dumps

-- 8. Sales vs GL monthly reference output
-- Business question:What should the monthly reconciliation totals equal?
-- Why it matters:Lets you compare what a finance-facing dashboard would show against recon logic.
-- Suggested source:mart.recon_sales_to_gl_monthly
-- Output grain: month

-- 9. Grain uniqueness sanity checks
-- Business question: Are the main fact tables unique at the intended reporting grain?
-- Why it matters: A semantic model can look fine while silently double counting.
-- Suggested source: core fact tables
-- Output: one row per fact table

---

-- Suggested V1 sections
-- organize the file like this:

-- Section A — Core executive totals
-- monthly gross sales
-- monthly net sales
-- monthly gross margin
-- monthly labor hours
-- monthly labor cost

-- Section B — KPI references
-- monthly sales per labor hour
-- in-stock rate by day
-- days of supply summary
-- labor cost % of sales if available

-- Section C — Reconciliation references
-- sales to GL monthly
-- distributor vs POS daily/monthly summary

-- Section D — Grain sanity
-- uniqueness checks for main facts
-- rowcount summaries if useful

create schema if not exists validation;

-- =========================================================
-- TEST 01: Monthly Net Sales Reference
-- Purpose: Validate semantic-model monthly sales cards/trends
-- Grain: 1 row per month
-- =========================================================

-- select
--     date_trunc('month', sale_date)::date as month_start,
--     sum(net_sales_amount)::numeric(18,2) as net_sales_amount
-- from mart.fact_sales_distributor_daily
-- group by 1
-- order by 1;

-- =========================================================
-- TEST 02: Monthly Net Sales Per Labor Hour
-- Purpose: Validate cross-functional productivity KPI
-- Grain: 1 row per month
-- =========================================================

-- select
--     date_trunc('month', business_date)::date as month_start,
--     sum(net_sales_amount)::numeric(18,2) as net_sales_amount,
--     sum(labor_hours)::numeric(18,2) as labor_hours,
--     case
--         when nullif(sum(labor_hours), 0) is null then null
--         else (sum(net_sales_amount) / nullif(sum(labor_hours), 0))::numeric(18,2)
--     end as net_sales_per_labor_hour
-- from mart.kpi_sales_per_labor_hour_daily
-- group by 1
-- order by 1;

-- =========================================================
-- TEST 03: Fact Grain Uniqueness - Sales
-- Purpose: Ensure semantic model will not double count sales
-- Grain: 1 row
-- =========================================================

-- select
--     'mart.fact_sales_distributor_daily'::text as fact_name,
--     count(*) as total_rows,
--     count(distinct (sale_date, distributor_id, sku)) as distinct_grain_rows,
--     count(*) - count(distinct (sale_date, distributor_id, sku)) as duplicate_rows;







-- =========================================================
-- SECTION A — CORE EXECUTIVE TOTALS
-- =========================================================

-- =========================================================
-- TEST 01: Monthly Sales Reference
-- Purpose: Validate executive sales cards / trend visuals
-- Grain: 1 row per month
-- Source: mart.fact_sales_distributor_daily
-- =========================================================
select
    date_trunc('month', sale_date)::date as month_start,
    sum(net_sales)::numeric(18,2) as net_sales,
    sum(gross_sales)::numeric(18,2) as gross_sales,
    sum(discount_amount)::numeric(18,2) as discount_amount,
    sum(qty)::numeric(18,2) as units,
    sum(orders)::bigint as orders,
    sum(customers)::bigint as customers
from mart.fact_sales_distributor_daily
group by 1
order by 1;

-- =========================================================
-- TEST 02: Monthly Gross Margin Reference
-- Purpose: Validate finance KPI cards / trend visuals
-- Grain: 1 row per month
-- Source: mart.kpi_gross_margin_daily
-- =========================================================
select
    date_trunc('month', sale_date)::date as month_start,
    sum(net_sales)::numeric(18,2) as net_sales,
    sum(cogs)::numeric(18,2) as cogs,
    sum(gross_margin)::numeric(18,2) as gross_margin,
    case
        when nullif(sum(net_sales), 0) is null then null
        else (sum(gross_margin) / nullif(sum(net_sales), 0))::numeric(18,4)
    end as gross_margin_pct
from mart.kpi_gross_margin_daily
group by 1
order by 1;

-- =========================================================
-- TEST 03: Monthly Labor Reference
-- Purpose: Validate labor totals and supporting KPI joins
-- Grain: 1 row per month
-- Source: mart.fact_labor_daily
-- =========================================================
select
    date_trunc('month', work_date)::date as month_start,
    sum(hours_worked)::numeric(18,2) as hours_worked,
    sum(minutes_worked)::numeric(18,2) as minutes_worked,
    sum(n_employees)::bigint as employee_count_sum,
    sum(n_punches)::bigint as punches,
    sum(n_shift_pairs)::bigint as shift_pairs
from mart.fact_labor_daily
group by 1
order by 1;

-- =========================================================
-- SECTION B — KPI REFERENCES
-- =========================================================

-- =========================================================
-- TEST 04: Monthly Sales per Labor Hour Reference
-- Purpose: Validate cross-functional productivity KPI
-- Grain: 1 row per month
-- Source: mart.kpi_sales_per_labor_hour_daily
-- =========================================================
select
    date_trunc('month', kpi_date)::date as month_start,
    sum(net_sales)::numeric(18,2) as net_sales,
    sum(gross_sales)::numeric(18,2) as gross_sales,
    sum(hours_worked)::numeric(18,2) as hours_worked,
    case
        when nullif(sum(hours_worked), 0) is null then null
        else (sum(net_sales) / nullif(sum(hours_worked), 0))::numeric(18,2)
    end as net_sales_per_labor_hour,
    case
        when nullif(sum(hours_worked), 0) is null then null
        else (sum(gross_sales) / nullif(sum(hours_worked), 0))::numeric(18,2)
    end as gross_sales_per_labor_hour
from mart.kpi_sales_per_labor_hour_daily
group by 1
order by 1;

-- =========================================================
-- TEST 05: Daily In-Stock Rate Reference
-- Purpose: Validate ops inventory-health KPI visuals
-- Grain: 1 row per snapshot_date
-- Source: mart.kpi_instock_rate_daily
-- =========================================================
select
    snapshot_date,
    sum(n_skus_in_inventory)::bigint as n_skus_in_inventory,
    sum(n_skus_in_stock)::bigint as n_skus_in_stock,
    case
        when nullif(sum(n_skus_in_inventory), 0) is null then null
        else (
            sum(n_skus_in_stock)::numeric
            / nullif(sum(n_skus_in_inventory), 0)
        )::numeric(18,4)
    end as instock_rate_inventory_universe,
    sum(n_skus_carried)::bigint as n_skus_carried,
    sum(n_carried_skus_in_stock)::bigint as n_carried_skus_in_stock,
    case
        when nullif(sum(n_skus_carried), 0) is null then null
        else (
            sum(n_carried_skus_in_stock)::numeric
            / nullif(sum(n_skus_carried), 0)
        )::numeric(18,4)
    end as instock_rate_carried_universe
from mart.kpi_instock_rate_daily
group by 1
order by 1;

-- =========================================================
-- TEST 06: Daily Days-of-Supply Summary Reference
-- Purpose: Validate inventory coverage KPI behavior without dumping every SKU row
-- Grain: 1 row per snapshot_date
-- Source: mart.kpi_days_of_supply
-- =========================================================
select
    snapshot_date,
    count(*)::bigint as sku_store_rows,
    avg(days_of_supply_28d)::numeric(18,2) as avg_days_of_supply_28d,
    percentile_cont(0.5) within group (order by days_of_supply_28d)::numeric(18,2) as median_days_of_supply_28d,
    min(days_of_supply_28d)::numeric(18,2) as min_days_of_supply_28d,
    max(days_of_supply_28d)::numeric(18,2) as max_days_of_supply_28d
from mart.kpi_days_of_supply
where days_of_supply_28d is not null
group by 1
order by 1;

-- =========================================================
-- SECTION C — RECONCILIATION REFERENCES
-- =========================================================

-- =========================================================
-- TEST 07: Monthly Sales vs GL Reference
-- Purpose: Validate finance-facing monthly reconciliation totals
-- Grain: 1 row per period_month + metric
-- Source: mart.recon_sales_to_gl_monthly
-- =========================================================
select
    period_month,
    metric,
    mart_amount::numeric(18,2) as mart_amount,
    gl_amount::numeric(18,2) as gl_amount,
    diff_amount::numeric(18,2) as diff_amount,
    pct_diff::numeric(18,4) as pct_diff,
    status
from mart.recon_sales_to_gl_monthly
order by period_month, metric;

-- =========================================================
-- TEST 08: Distributor vs POS Daily Reference
-- Purpose: Validate operational sales alignment across source systems
-- Grain: 1 row per sale_date + store_code
-- Source: mart.recon_sales_distributor_vs_pos
-- =========================================================
select
    sale_date,
    store_code,
    dist_net_sales::numeric(18,2) as dist_net_sales,
    pos_net_sales::numeric(18,2) as pos_net_sales,
    delta_net_sales::numeric(18,2) as delta_net_sales,
    delta_pct_net_sales::numeric(18,4) as delta_pct_net_sales,
    tolerance_pct::numeric(18,4) as tolerance_pct,
    status
from mart.recon_sales_distributor_vs_pos
order by sale_date, store_code;

-- =========================================================
-- SECTION D — GRAIN SANITY
-- =========================================================

-- =========================================================
-- TEST 09: Fact Grain Uniqueness Sanity
-- Purpose: Ensure main facts are unique at intended reporting grain
-- Grain: 1 row per fact table
-- =========================================================
with sales_dist as (
    select
        'mart.fact_sales_distributor_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (sale_date, store_code, sku, channel))::bigint as distinct_grain_rows
    from mart.fact_sales_distributor_daily
),
sales_pos as (
    select
        'mart.fact_sales_pos_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (sale_date, store_code, sku))::bigint as distinct_grain_rows
    from mart.fact_sales_pos_daily
),
labor as (
    select
        'mart.fact_labor_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (work_date, store_code))::bigint as distinct_grain_rows
    from mart.fact_labor_daily
),
inventory as (
    select
        'mart.fact_inventory_snapshot_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (snapshot_date, store_code, sku))::bigint as distinct_grain_rows
    from mart.fact_inventory_snapshot_daily
)
select
    fact_name,
    total_rows,
    distinct_grain_rows,
    (total_rows - distinct_grain_rows) as duplicate_rows
from (
    select * from sales_dist
    union all
    select * from sales_pos
    union all
    select * from labor
    union all
    select * from inventory
) x
order by fact_name;

-- =========================================================
-- TEST 10: Missing Dimension Join Reference
-- Purpose: Validate dimensional coverage for report-safe facts
-- Grain: 1 row per model + dim + date
-- Source: mart.controls_missing_dim_joins
-- =========================================================
select
    run_date,
    model_name,
    dim_name,
    grain_date,
    fact_rows,
    missing_dim_rows,
    missing_pct,
    status
from mart.controls_missing_dim_joins
order by run_date, model_name, dim_name, grain_date;


-- =========================================================
-- TEST 06: Daily Days-of-Supply Summary Reference
-- Purpose: Validate inventory coverage KPI behavior without dumping every SKU row
-- Grain: 1 row per snapshot_date
-- =========================================================
select
    snapshot_date,
    count(*)::bigint as sku_store_rows,
    avg(days_of_supply_28d)::numeric(18,2) as avg_days_of_supply_28d,
    percentile_cont(0.5) within group (order by days_of_supply_28d)::numeric(18,2) as median_days_of_supply_28d,
    min(days_of_supply_28d)::numeric(18,2) as min_days_of_supply_28d,
    max(days_of_supply_28d)::numeric(18,2) as max_days_of_supply_28d
from mart.kpi_days_of_supply
where days_of_supply_28d is not null
group by 1
order by 1;

-- =========================================================
-- TEST 07: Monthly Sales vs GL Reference
-- Purpose: Validate finance-facing monthly reconciliation totals
-- Grain: 1 row per period_month + metric
-- =========================================================
select
    period_month,
    metric,
    mart_amount::numeric(18,2) as mart_amount,
    gl_amount::numeric(18,2) as gl_amount,
    diff_amount::numeric(18,2) as diff_amount,
    pct_diff::numeric(18,4) as pct_diff,
    status
from mart.recon_sales_to_gl_monthly
order by period_month, metric;

-- =========================================================
-- TEST 08: Distributor vs POS Daily Reference
-- Purpose: Validate operational sales alignment across source systems
-- Grain: 1 row per sale_date + store_code
-- =========================================================
select
    sale_date,
    store_code,
    dist_net_sales::numeric(18,2) as dist_net_sales,
    pos_net_sales::numeric(18,2) as pos_net_sales,
    delta_net_sales::numeric(18,2) as delta_net_sales,
    delta_pct_net_sales::numeric(18,4) as delta_pct_net_sales,
    tolerance_pct::numeric(18,4) as tolerance_pct,
    status
from mart.recon_sales_distributor_vs_pos
order by sale_date, store_code;

-- =========================================================
-- TEST 09: Fact Grain Uniqueness Sanity
-- Purpose: Ensure main facts are unique at intended reporting grain
-- Grain: 1 row per fact table
-- =========================================================
with sales_dist as (
    select
        'mart.fact_sales_distributor_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (sale_date, store_code, sku, channel))::bigint as distinct_grain_rows
    from mart.fact_sales_distributor_daily
),
sales_pos as (
    select
        'mart.fact_sales_pos_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (sale_date, store_code, sku))::bigint as distinct_grain_rows
    from mart.fact_sales_pos_daily
),
labor as (
    select
        'mart.fact_labor_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (work_date, store_code))::bigint as distinct_grain_rows
    from mart.fact_labor_daily
),
inventory as (
    select
        'mart.fact_inventory_snapshot_daily'::text as fact_name,
        count(*)::bigint as total_rows,
        count(distinct (snapshot_date, store_code, sku))::bigint as distinct_grain_rows
    from mart.fact_inventory_snapshot_daily
)
select
    fact_name,
    total_rows,
    distinct_grain_rows,
    (total_rows - distinct_grain_rows) as duplicate_rows
from (
    select * from sales_dist
    union all
    select * from sales_pos
    union all
    select * from labor
    union all
    select * from inventory
) x
order by fact_name;

-- =========================================================
-- TEST 10: Missing Dimension Join Reference
-- Purpose: Validate dimensional coverage for report-safe facts
-- Grain: 1 row per model + dim + date
-- =========================================================
select
    run_date,
    model_name,
    dim_name,
    grain_date,
    fact_rows,
    missing_dim_rows,
    missing_pct,
    status
from mart.controls_missing_dim_joins
order by run_date, model_name, dim_name, grain_date;