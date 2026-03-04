-- mart/finance/breakeven_monthly.sql
-- Break-even approximations using available actuals + sales.
-- Grain: period_month
--
-- Interpretation:
-- - Uses gross_margin_pct (from actuals) and labor_cost as the “cost to cover”.
-- - Break-even net sales = labor_cost / gross_margin_pct.
-- - Adds “days to break even” using avg daily net sales (mart).

create schema if not exists mart;

create or replace view mart.kpi_breakeven_monthly as
with actuals as (
  select
    period_month,
    sum(actual_amount) filter (where kpi_category = 'net_sales')::numeric as net_sales,
    sum(actual_amount) filter (where kpi_category = 'cogs')::numeric as cogs,
    sum(actual_amount) filter (where kpi_category = 'labor_cost')::numeric as labor_cost
  from mart.fact_actuals_monthly
  group by 1
),
sales_mart as (
  select
    date_trunc('month', sale_date)::date as period_month,
    sum(coalesce(net_sales,0))::numeric as mart_net_sales
  from mart.fact_sales_distributor_daily
  group by 1
),
joined as (
  select
    a.period_month,
    a.net_sales,
    a.cogs,
    (a.net_sales - a.cogs)::numeric as gross_margin,
    case when nullif(a.net_sales,0) is null then null
         else (a.net_sales - a.cogs) / nullif(a.net_sales,0)
    end as gross_margin_pct,
    a.labor_cost,
    s.mart_net_sales
  from actuals a
  left join sales_mart s
    on s.period_month = a.period_month
),
days as (
  select
    j.*,
    -- avg daily net sales from mart (fallback to actuals net_sales)
    case
      when j.mart_net_sales is not null and j.mart_net_sales <> 0
        then j.mart_net_sales / extract(day from (date_trunc('month', j.period_month) + interval '1 month - 1 day'))
      when j.net_sales is not null and j.net_sales <> 0
        then j.net_sales / extract(day from (date_trunc('month', j.period_month) + interval '1 month - 1 day'))
      else null
    end as avg_daily_net_sales_in_month
  from joined j
)
select
  period_month,
  net_sales as actual_net_sales,
  cogs,
  gross_margin,
  gross_margin_pct,
  labor_cost,

  case
    when nullif(gross_margin_pct,0) is null or labor_cost is null then null
    else labor_cost / nullif(gross_margin_pct,0)
  end as breakeven_net_sales_for_labor,

  avg_daily_net_sales_in_month,

  case
    when nullif(avg_daily_net_sales_in_month,0) is null then null
    else (case
            when nullif(gross_margin_pct,0) is null or labor_cost is null then null
            else (labor_cost / nullif(gross_margin_pct,0)) / nullif(avg_daily_net_sales_in_month,0)
          end)
  end as breakeven_days_estimate
from days
order by period_month desc;
