-- mart/sales/agg_sales_store_daily.sql
-- Store-level daily rollup across SKUs/channels/sources.
-- Grain: 1 row per sale_date + store_code

create schema if not exists mart;

create or replace view mart.agg_sales_store_daily as
with base as (
  select
    sale_date,
    store_code,
    sales_source,
    channel,
    sku,

    qty,
    gross_sales,
    discount_amount,
    net_sales,
    cogs,
    orders,
    customers
  from mart.fact_sales_daily
)
select
  sale_date,
  store_code,

  -- totals
  sum(coalesce(net_sales, 0))::numeric as net_sales,
  sum(coalesce(gross_sales, 0))::numeric as gross_sales,
  sum(coalesce(discount_amount, 0))::numeric as discount_amount,
  sum(coalesce(qty, 0))::numeric as units,
  sum(coalesce(orders, 0))::bigint as orders,

  -- cogs coverage awareness
  sum(coalesce(cogs, 0))::numeric as cogs,
  count(*) filter (where cogs is not null)::bigint as rows_with_cogs,
  count(*)::bigint as rows_total,

  -- source breakdown
  sum(coalesce(net_sales, 0)) filter (where sales_source = 'pos')::numeric as net_sales_pos,
  sum(coalesce(net_sales, 0)) filter (where sales_source = 'distributor')::numeric as net_sales_distributor,

  -- diversity counts
  count(distinct sku) as distinct_skus,
  count(distinct channel) as distinct_channels,

  -- basic margin (only meaningful where cogs exists)
  (sum(coalesce(net_sales, 0)) - sum(coalesce(cogs, 0)))::numeric as gross_profit,
  case
    when nullif(sum(coalesce(net_sales, 0)), 0) is null then null
    else (sum(coalesce(net_sales, 0)) - sum(coalesce(cogs, 0))) / nullif(sum(coalesce(net_sales, 0)), 0)
  end as gross_margin_pct

from base
group by 1,2;
