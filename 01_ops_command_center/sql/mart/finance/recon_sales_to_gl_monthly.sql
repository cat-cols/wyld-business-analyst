-- mart/finance/recon_sales_to_gl_monthly.sql
-- Recon: Mart sales (monthly) vs Finance actuals summary (monthly)
-- Output: one row per period_month + metric

create schema if not exists mart;

create or replace view mart.recon_sales_to_gl_monthly as
with params as (
  select
    0.02::numeric as pct_tolerance,   -- 2%
    500::numeric  as abs_tolerance    -- $500
),
mart_monthly as (
  select
    date_trunc('month', sale_date)::date as period_month,
    sum(coalesce(net_sales,0))::numeric as mart_net_sales,
    sum(coalesce(gross_sales,0))::numeric as mart_gross_sales,
    sum(coalesce(cogs,0))::numeric as mart_cogs,
    sum(coalesce(net_sales,0) - coalesce(cogs,0))::numeric as mart_gross_margin
  from mart.fact_sales_distributor_daily
  group by 1
),
gl as (
  select
    period_month,
    sum(actual_amount) filter (where kpi_category = 'net_sales')::numeric as gl_net_sales,
    sum(actual_amount) filter (where kpi_category = 'gross_sales')::numeric as gl_gross_sales,
    sum(actual_amount) filter (where kpi_category = 'cogs')::numeric as gl_cogs,
    sum(actual_amount) filter (where kpi_category = 'gross_margin')::numeric as gl_gross_margin
  from mart.fact_actuals_monthly
  group by 1
),
rows as (
  select
    coalesce(m.period_month, g.period_month) as period_month,

    m.mart_net_sales, g.gl_net_sales,
    m.mart_gross_sales, g.gl_gross_sales,
    m.mart_cogs, g.gl_cogs,
    m.mart_gross_margin, g.gl_gross_margin
  from mart_monthly m
  full outer join gl g
    on g.period_month = m.period_month
),
melt as (
  select period_month, 'net_sales'::text as metric, mart_net_sales as mart_amount, gl_net_sales as gl_amount from rows
  union all
  select period_month, 'gross_sales', mart_gross_sales, gl_gross_sales from rows
  union all
  select period_month, 'cogs', mart_cogs, gl_cogs from rows
  union all
  select period_month, 'gross_margin', mart_gross_margin, gl_gross_margin from rows
)
select
  period_month,
  metric,
  mart_amount,
  gl_amount,
  (coalesce(mart_amount,0) - coalesce(gl_amount,0))::numeric as diff_amount,
  case
    when greatest(abs(coalesce(mart_amount,0)), abs(coalesce(gl_amount,0))) = 0 then 0
    else (abs(coalesce(mart_amount,0) - coalesce(gl_amount,0))
          / nullif(greatest(abs(coalesce(mart_amount,0)), abs(coalesce(gl_amount,0))), 0)
    )::numeric
  end as pct_diff,
  case
    when mart_amount is null then 'FAIL_missing_mart'
    when gl_amount is null then 'FAIL_missing_gl'
    when abs(coalesce(mart_amount,0) - coalesce(gl_amount,0)) <= (select abs_tolerance from params) then 'PASS'
    when (
      greatest(abs(coalesce(mart_amount,0)), abs(coalesce(gl_amount,0))) > 0
      and
      (abs(coalesce(mart_amount,0) - coalesce(gl_amount,0))
        / greatest(abs(coalesce(mart_amount,0)), abs(coalesce(gl_amount,0)))
      ) <= (select pct_tolerance from params)
    ) then 'PASS'
    else 'FAIL_mismatch'
  end as status
from melt
order by period_month desc, metric;
