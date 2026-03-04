-- mart/sales/fact_sales_daily.sql
-- Unified sales fact for Power BI consumption.
-- Grain: 1 row per sale_date + store_code + sku + channel + sales_source
--
-- This view does NOT attempt to “pick the winner” between distributor vs POS.
-- Keep both sources, and let recon/controls (and downstream modeling) decide precedence.

create schema if not exists mart;

create or replace view mart.fact_sales_daily as
select
  sale_date,
  store_code,
  sku,
  channel,
  'distributor'::text as sales_source,

  product_name,
  qty,
  gross_sales,
  discount_amount,
  net_sales,
  cogs,
  orders,
  customers,
  unit_list_price_wavg,
  unit_net_price_wavg,
  discount_rate_implied,
  n_source_rows,
  n_dup_candidate_rows,
  max_ingested_at,
  max_drop_date
from mart.fact_sales_distributor_daily

union all

select
  sale_date,
  store_code,
  sku,
  channel,
  'pos'::text as sales_source,

  product_name,
  qty,
  gross_sales,
  discount_amount,
  net_sales,
  cogs,
  orders,
  customers,
  unit_list_price_wavg,
  unit_net_price_wavg,
  discount_rate_implied,
  n_source_rows,
  n_dup_candidate_rows,
  max_ingested_at,
  max_drop_date
from mart.fact_sales_pos_daily
;
