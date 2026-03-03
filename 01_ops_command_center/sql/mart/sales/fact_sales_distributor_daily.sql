-- 01_ops_command_center/sql/mart/sales/fact_sales_distributor_daily.sql
-- grain: 1 row per sale_date + store_code + sku + channel
-- Source of truth: int.int_sales_distributor_dedup (duplicates already collapsed)

create schema if not exists mart;

create or replace view mart.fact_sales_distributor_daily as
select
  sale_date,
  store_code,
  sku,
  channel,

  -- optional descriptive label (don’t rely on it as a key)
  product_name,

  -- measures
  qty,
  gross_sales,
  discount_amount,
  net_sales,
  cogs,
  orders,
  customers,

  -- derived / pricing
  unit_list_price_wavg,
  unit_net_price_wavg,
  discount_rate_implied,

  -- explainability / lineage
  n_source_rows,
  n_dup_candidate_rows,
  max_ingested_at,
  max_drop_date
from int.int_sales_distributor_dedup;