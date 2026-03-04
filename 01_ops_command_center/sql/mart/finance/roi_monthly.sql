-- mart/finance/roi_.sql
-- Simple, data-available ROI approximations from finance actuals.
-- Grain: period_month

create schema if not exists mart;

create or replace view mart.kpi_roi_monthly as
with a as (
  select
    period_month,
    sum(actual_amount) filter (where kpi_category = 'net_sales')::numeric as net_sales,
    sum(actual_amount) filter (where kpi_category = 'cogs')::numeric as cogs,
    sum(actual_amount) filter (where kpi_category = 'gross_margin')::numeric as gross_margin,
    sum(actual_amount) filter (where kpi_category = 'labor_cost')::numeric as labor_cost
  from mart.fact_actuals_monthly
  group by 1
),
derived as (
  select
    period_month,
    net_sales,
    cogs,
    -- fallback: compute gross_margin if finance didn’t provide it
    coalesce(gross_margin, net_sales - cogs) as gross_margin,
    labor_cost
  from a
)
select
  period_month,
  net_sales,
  cogs,
  gross_margin,
  labor_cost,

  (gross_margin - labor_cost)::numeric as contribution_margin,

  case when nullif(labor_cost,0) is null then null
       else gross_margin / nullif(labor_cost,0)
  end as roi_gross_margin_over_labor,

  case when nullif(labor_cost,0) is null then null
       else (gross_margin - labor_cost) / nullif(labor_cost,0)
  end as roi_contribution_over_labor
from derived
order by period_month desc;
