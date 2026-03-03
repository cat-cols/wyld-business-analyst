-- mart/kpi_sales_per_labor_hour_daily.sql
-- Grain: 1 row per date + store_code
-- Purpose: first end-to-end KPI proving mart facts + shared dim work together
-- Logic: aggregate sales to store/day, join labor store/day.

create schema if not exists mart;

create or replace view mart.kpi_sales_per_labor_hour_daily as
with sales_store_day as (
  select
    sale_date as kpi_date,
    store_code,
    sum(net_sales) as net_sales,
    sum(gross_sales) as gross_sales,
    sum(discount_amount) as discount_amount,
    sum(cogs) as cogs,
    sum(qty) as units,
    sum(orders) as orders,
    sum(customers) as customers
  from mart.fact_sales_distributor_daily
  group by 1,2
),
labor as (
  select
    work_date as kpi_date,
    store_code,
    hours_worked,
    n_punches,
    n_employees
  from mart.fact_labor_daily
)
select
  s.kpi_date,
  s.store_code,

  -- core metrics
  s.net_sales,
  s.gross_sales,
  s.discount_amount,
  s.cogs,
  s.units,
  s.orders,
  s.customers,

  l.hours_worked,
  l.n_punches,
  l.n_employees,

  -- KPI calculations (safe divide)
  case when nullif(l.hours_worked, 0) is null then null
       else s.net_sales / nullif(l.hours_worked, 0)
  end as net_sales_per_labor_hour,

  case when nullif(l.hours_worked, 0) is null then null
       else s.gross_sales / nullif(l.hours_worked, 0)
  end as gross_sales_per_labor_hour

from sales_store_day s
left join labor l
  on l.kpi_date = s.kpi_date
 and l.store_code = s.store_code;