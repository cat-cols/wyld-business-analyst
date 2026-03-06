-- int/int_sales_distributor_dedup.sql
-- Dedup at grain: sale_date + store_code + sku + channel

create schema if not exists int;

create or replace view int.int_sales_distributor_dedup as

with base as (
  select
    s.*
  from stg.stg_sales_distributor s
  where
    s.sale_date is not null
    and s.store_code is not null
    and s.sku is not null
    and s.channel is not null
),

ranked as (
    select
        b.*,
        count(*) over (
            partition by b.sale_date, b.store_code, b.sku, b.channel
        ) as dup_group_size,
        row_number() over (
            partition by b.sale_date, b.store_code, b.sku, b.channel
            order by
                -- prefer “cleaner” rows first (false < true)
                b.is_missing_key asc,
                b.is_bad_amount asc,
                b.ingested_at desc nulls last,
                b.drop_date desc nulls last,
                b.load_id desc nulls last
        ) as rn
    from base b
)
select
    -- grain
    sale_date,
    store_code,
    sku,
    channel,

    -- measures / attributes
    qty,
    unit_list_price,
    discount_rate,
    unit_net_price,
    gross_sales,
    discount_amount,
    net_sales,
    cogs,
    orders,
    customers,

    -- keep some raw context if you like
    sale_date_raw,

    -- keep raw store_id for lineage/debugging
    store_id_raw,
    channel_raw,
    qty_raw,

    -- flags
    is_missing_key,
    is_bad_amount,

    -- lineage
    load_id,
    source_system,
    cadence,
    drop_date,
    ingested_at,

    -- debugging helper
    dup_group_size,
    product_name,
    product_name_raw
from ranked
where rn = 1
;