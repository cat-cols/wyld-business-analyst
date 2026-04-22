-- ./sql/dq/04_run_reconciliation_checks.sql
-- Quarterly Data Collection + QA/QC System
-- Purpose: run first-pass reconciliation checks and persist recon results

-- 1. identify the latest run
-- 2. calculate sales vs finance values and variance
-- 3. insert one row into `dq.recon_results`

with latest_run as (
    select run_id, quarter_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
recon_rule as (
    select threshold_pct
    from dq.dq_rules
    where rule_name = 'Sales vs Finance reconciliation within tolerance'
      and active_flag = true
),
operational_sales as (
    select
        '2026Q1'::text as quarter_id,
        coalesce(sum(net_sales), 0)::numeric(18,2) as operational_net_sales
    from (
        select net_sales
        from stg.stg_retail_account_sales_quarterly

        union all

        select net_sales
        from stg.stg_wholesale_account_sales_quarterly
    ) s
),
finance_sales as (
    select
        quarter_id,
        coalesce(sum(actual_amount), 0)::numeric(18,2) as finance_net_revenue
    from stg.stg_finance_quarterly_actuals
    where reporting_category = 'net_revenue'
    group by quarter_id
)
insert into dq.recon_results (
    run_id,
    quarter_id,
    recon_name,
    left_source,
    right_source,
    metric_name,
    left_value,
    right_value,
    variance_value,
    variance_pct,
    tolerance_pct,
    status
)
select
    lr.run_id,
    lr.quarter_id,
    'Sales vs Finance reconciliation within tolerance',
    'operational_sales',
    'finance_actuals',
    'net_sales_vs_finance_net_revenue',
    os.operational_net_sales,
    fs.finance_net_revenue,
    os.operational_net_sales - fs.finance_net_revenue as variance_value,
    case
        when fs.finance_net_revenue = 0 then null
        else abs(os.operational_net_sales - fs.finance_net_revenue) / fs.finance_net_revenue
    end as variance_pct,
    rr.threshold_pct,
    case
        when fs.finance_net_revenue = 0 then 'fail'
        when abs(os.operational_net_sales - fs.finance_net_revenue) / fs.finance_net_revenue <= rr.threshold_pct then 'pass'
        else 'fail'
    end as status
from latest_run lr
cross join recon_rule rr
cross join operational_sales os
join finance_sales fs
  on fs.quarter_id = lr.quarter_id;