-- mart/finance/kpi_gross_margin_daily.sql
-- Grain: sale_date + store_code
-- Source: mart.fact_sales_distributor_daily (has COGS)

create schema if not exists mart;

create or replace view mart.kpi_gross_margin_daily as
with sales as (
  select
    sale_date,
    store_code,
    sum(coalesce(net_sales,0))::numeric as net_sales,
    sum(coalesce(gross_sales,0))::numeric as gross_sales,
    sum(coalesce(cogs,0))::numeric as cogs
  from mart.fact_sales_distributor_daily
  group by 1,2
)
select
  sale_date,
  store_code,
  net_sales,
  gross_sales,
  cogs,
  (net_sales - cogs)::numeric as gross_margin,
  case when nullif(net_sales,0) is null then null
       else (net_sales - cogs) / nullif(net_sales,0)
  end as gross_margin_pct
from sales;
