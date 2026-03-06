-- 01_ops_command_center/sql/mart/sales/fact_sales_distributor_daily.sql
-- Grain: 1 row per sale_date + store_code + sku + channel
-- Source of truth: int.int_sales_distributor_dedup (deduped)

create schema if not exists mart;

create or replace view mart.fact_sales_distributor_daily as
with base as (
  select
    sale_date,
    store_code,
    sku,
    channel,

    -- descriptive label (non-key)
    product_name,

    -- measures
    qty,
    gross_sales,
    discount_amount,
    net_sales,
    cogs,
    orders,
    customers,

    -- pricing inputs
    unit_list_price,
    unit_net_price,
    discount_rate,

    -- explainability inputs from INT
    coalesce(dup_group_size, 1) as dup_group_size,

    -- lineage inputs
    ingested_at,
    drop_date
  from int.int_sales_distributor_dedup
  where sale_date is not null
    and store_code is not null
    and sku is not null
    and channel is not null
),
agg as (
  select
    sale_date,
    store_code,
    sku,
    channel,

    max(product_name) filter (where product_name is not null) as product_name,

    -- totals
    sum(coalesce(qty,0))::numeric as qty,
    sum(coalesce(gross_sales,0))::numeric as gross_sales,
    sum(coalesce(discount_amount,0))::numeric as discount_amount,
    sum(coalesce(net_sales,0))::numeric as net_sales,
    sum(coalesce(cogs,0))::numeric as cogs,
    sum(coalesce(orders,0))::bigint as orders,
    sum(coalesce(customers,0))::bigint as customers,

    -- weighted averages (robust even if upstream ever stops being 1 row per grain)
    case when nullif(sum(coalesce(qty,0))::numeric, 0) is null then null
         else (sum(coalesce(unit_list_price,0) * coalesce(qty,0))::numeric
               / nullif(sum(coalesce(qty,0))::numeric, 0))
    end as unit_list_price_wavg,

    case when nullif(sum(coalesce(qty,0))::numeric, 0) is null then null
         else (sum(coalesce(unit_net_price,0) * coalesce(qty,0))::numeric
               / nullif(sum(coalesce(qty,0))::numeric, 0))
    end as unit_net_price_wavg,

    -- implied discount rate (amount-based)
    case when nullif(sum(coalesce(gross_sales,0))::numeric, 0) is null then null
         else (sum(coalesce(discount_amount,0))::numeric
               / nullif(sum(coalesce(gross_sales,0))::numeric, 0))
    end as discount_rate_implied,

    -- explainability
    max(dup_group_size)::int as n_source_rows,
    greatest(max(dup_group_size)::int - 1, 0) as n_dup_candidate_rows,

    -- lineage
    max(ingested_at) as max_ingested_at,
    max(drop_date)   as max_drop_date

  from base
  group by 1,2,3,4
)
select *
from agg;

-- OLD VERSION BELOW - COMMENTED OUT
-- 01_ops_command_center/sql/mart/sales/fact_sales_distributor_daily.sql
-- grain: 1 row per sale_date + store_code + sku + channel
-- Source of truth: int.int_sales_distributor_dedup (duplicates already collapsed)

-- create schema if not exists mart;

-- create or replace view mart.fact_sales_distributor_daily as
-- select
--   sale_date,
--   store_code,
--   sku,
--   channel,

--   -- optional descriptive label (don’t rely on it as a key)
--   product_name,

--   -- measures
--   qty,
--   gross_sales,
--   discount_amount,
--   net_sales,
--   cogs,
--   orders,
--   customers,

--   -- derived / pricing
--   unit_list_price_wavg,
--   unit_net_price_wavg,
--   discount_rate_implied,

--   -- explainability / lineage
--   n_source_rows,
--   n_dup_candidate_rows,
--   max_ingested_at,
--   max_drop_date
-- from int.int_sales_distributor_dedup;