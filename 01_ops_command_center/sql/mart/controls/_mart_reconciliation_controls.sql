-- mart/controls/_mart_reconciliation_controls.sql
-- Build control table: source_total vs modeled_total with delta and pass/warn/fail
--
-- Output columns:
-- * check_name
-- * check_date
-- * domain
-- * source_total
-- * modeled_total
-- * delta_amount
-- * delta_pct
-- * tolerance_pct
-- * status (Pass/Warning/Fail)
--
-- Notes:
-- - Each check compares totals for the latest common date (or month) between source and modeled.
-- - Add/remove checks by editing the "checks" CTE.

create schema if not exists mart;

create or replace view mart.mart_reconciliation_controls as
with params as (
  select
    0.005::numeric as tol_sales,    -- 0.5%
    0.005::numeric as tol_pos,      -- 0.5%
    0.005::numeric as tol_labor,    -- 0.5%
    0.010::numeric as tol_inventory,-- 1.0%
    0.010::numeric as tol_finance   -- 1.0%
),

-- ----------------------------
-- SALES: distributor (INT vs MART)
-- ----------------------------
dist_dates as (
  select
    (select max(sale_date)::date from int.int_sales_distributor_dedup) as src_max_date,
    (select max(sale_date)::date from mart.fact_sales_distributor_daily) as mdl_max_date
),
dist_pick as (
  select least(src_max_date, mdl_max_date) as check_date
  from dist_dates
),
dist_totals as (
  select
    'sales_distributor_net_sales'::text as check_name,
    (select check_date from dist_pick) as check_date,
    'sales'::text as domain,
    (select sum(coalesce(net_sales,0))::numeric
       from int.int_sales_distributor_dedup
      where sale_date::date = (select check_date from dist_pick)
    ) as source_total,
    (select sum(coalesce(net_sales,0))::numeric
       from mart.fact_sales_distributor_daily
      where sale_date::date = (select check_date from dist_pick)
    ) as modeled_total,
    (select tol_sales from params) as tolerance_pct
),

-- ----------------------------
-- SALES: POS (INT vs MART)
-- ----------------------------
pos_dates as (
  select
    (select max(txn_date)::date from int.int_pos_dedup) as src_max_date,
    (select max(sale_date)::date from mart.fact_sales_pos_daily) as mdl_max_date
),
pos_pick as (
  select least(src_max_date, mdl_max_date) as check_date
  from pos_dates
),
pos_totals as (
  select
    'sales_pos_net_sales'::text as check_name,
    (select check_date from pos_pick) as check_date,
    'sales'::text as domain,
    (select sum(coalesce(net_amount,0))::numeric
       from int.int_pos_dedup
      where txn_date::date = (select check_date from pos_pick)
    ) as source_total,
    (select sum(coalesce(net_sales,0))::numeric
       from mart.fact_sales_pos_daily
      where sale_date::date = (select check_date from pos_pick)
    ) as modeled_total,
    (select tol_pos from params) as tolerance_pct
),

-- ----------------------------
-- HR: labor hours (INT vs MART)
-- ----------------------------
labor_dates as (
  select
    (select max(work_date)::date from int.int_labor_daily) as src_max_date,
    (select max(work_date)::date from mart.fact_labor_daily) as mdl_max_date
),
labor_pick as (
  select least(src_max_date, mdl_max_date) as check_date
  from labor_dates
),
labor_totals as (
  select
    'labor_hours'::text as check_name,
    (select check_date from labor_pick) as check_date,
    'hr'::text as domain,
    (select sum(coalesce(hours_worked,0))::numeric
       from int.int_labor_daily
      where work_date::date = (select check_date from labor_pick)
    ) as source_total,
    (select sum(coalesce(hours_worked,0))::numeric
       from mart.fact_labor_daily
      where work_date::date = (select check_date from labor_pick)
    ) as modeled_total,
    (select tol_labor from params) as tolerance_pct
),

-- ----------------------------
-- OPS: inventory on-hand (INT vs MART)
-- ----------------------------
inv_dates as (
  select
    (select max(snapshot_date)::date from int.int_inventory_snapshot_dedup) as src_max_date,
    (select max(snapshot_date)::date from mart.fact_inventory_snapshot_daily) as mdl_max_date
),
inv_pick as (
  select least(src_max_date, mdl_max_date) as check_date
  from inv_dates
),
inv_totals as (
  select
    'inventory_on_hand_safe'::text as check_name,
    (select check_date from inv_pick) as check_date,
    'ops'::text as domain,
    (select sum(coalesce(on_hand_nonnegative,0))::numeric
       from int.int_inventory_snapshot_dedup
      where snapshot_date::date = (select check_date from inv_pick)
    ) as source_total,
    (select sum(coalesce(on_hand_safe,0))::numeric
       from mart.fact_inventory_snapshot_daily
      where snapshot_date::date = (select check_date from inv_pick)
    ) as modeled_total,
    (select tol_inventory from params) as tolerance_pct
),

-- ----------------------------
-- FINANCE: actuals monthly total (STG vs MART)
-- ----------------------------
fin_dates as (
  select
    (select max(period_month)::date from stg.stg_finance_actuals) as src_max_month,
    (select max(period_month)::date from mart.fact_actuals_monthly) as mdl_max_month
),
fin_pick as (
  select least(src_max_month, mdl_max_month) as check_date
  from fin_dates
),
fin_totals as (
  select
    'finance_actuals_total'::text as check_name,
    (select check_date from fin_pick) as check_date,
    'finance'::text as domain,
    (select sum(coalesce(actual_amount,0))::numeric
       from stg.stg_finance_actuals
      where period_month::date = (select check_date from fin_pick)
    ) as source_total,
    (select sum(coalesce(actual_amount,0))::numeric
       from mart.fact_actuals_monthly
      where period_month::date = (select check_date from fin_pick)
    ) as modeled_total,
    (select tol_finance from params) as tolerance_pct
),

checks as (
  select * from dist_totals
  union all select * from pos_totals
  union all select * from labor_totals
  union all select * from inv_totals
  union all select * from fin_totals
),

scored as (
  select
    check_name,
    check_date,
    domain,
    source_total,
    modeled_total,
    (coalesce(modeled_total,0) - coalesce(source_total,0))::numeric as delta_amount,
    case
      when source_total is null or modeled_total is null then null
      when greatest(abs(coalesce(source_total,0)), abs(coalesce(modeled_total,0))) = 0 then 0
      else
        (abs(coalesce(modeled_total,0) - coalesce(source_total,0))
          / nullif(greatest(abs(coalesce(source_total,0)), abs(coalesce(modeled_total,0))), 0)
        )::numeric
    end as delta_pct,
    tolerance_pct
  from checks
)

select
  check_name,
  check_date,
  domain,
  source_total,
  modeled_total,
  delta_amount,
  delta_pct,
  tolerance_pct,
  case
    when source_total is null or modeled_total is null then 'Fail'
    when delta_pct is null then 'Fail'
    when delta_pct <= tolerance_pct then 'Pass'
    when delta_pct <= (tolerance_pct * 2) then 'Warning'
    else 'Fail'
  end as status
from scored
order by
  case status when 'Fail' then 1 when 'Warning' then 2 else 3 end,
  domain,
  check_name;