-- int/int_sales_distributor_dedup.sql
-- Dedup by collapsing duplicates at the natural grain:
--   sale_date + store + sku + channel

create schema if not exists int;

create or replace view int.int_sales_distributor_dedup as
with base as (
  select
    sd.*
  from stg.stg_sales_distributor sd
  where
    sd.sale_date is not null
    and sd.store_id is not null
    and sd.sku is not null
    and sd.channel is not null
    and coalesce(sd.is_missing_key, false) = false
),
agg as (
  select
    sale_date,
    store_id as store_code,
    sku,
    channel,

    -- choose a stable label if present
    max(product_name) as product_name,

    -- additive measures (safe to sum when duplicates exist)
    sum(coalesce(qty, 0)) as qty,
    sum(coalesce(gross_sales, 0)) as gross_sales,
    sum(coalesce(discount_amount, 0)) as discount_amount,
    sum(coalesce(net_sales, 0)) as net_sales,
    sum(coalesce(cogs, 0)) as cogs,
    sum(coalesce(orders, 0)) as orders,
    sum(coalesce(customers, 0)) as customers,

    -- weighted unit prices (only where price+qty present)
    case
      when nullif(sum(qty) filter (where unit_list_price is not null and qty is not null), 0) is null then null
      else
        sum(unit_list_price * qty) filter (where unit_list_price is not null and qty is not null)
        / nullif(sum(qty) filter (where unit_list_price is not null and qty is not null), 0)
    end as unit_list_price_wavg,

    case
      when nullif(sum(qty) filter (where unit_net_price is not null and qty is not null), 0) is null then null
      else
        sum(unit_net_price * qty) filter (where unit_net_price is not null and qty is not null)
        / nullif(sum(qty) filter (where unit_net_price is not null and qty is not null), 0)
    end as unit_net_price_wavg,

    -- implied discount rate (more stable than averaging %s)
    case
      when sum(coalesce(gross_sales, 0)) = 0 then null
      else 1 - (sum(coalesce(net_sales, 0)) / nullif(sum(coalesce(gross_sales, 0)), 0))
    end as discount_rate_implied,

    -- explainability
    count(*) as n_source_rows,
    count(*) filter (where coalesce(is_duplicate_candidate,false)) as n_dup_candidate_rows,
    max(ingested_at) as max_ingested_at,
    max(drop_date) as max_drop_date
  from base
  group by 1,2,3,4
)
select * from agg;