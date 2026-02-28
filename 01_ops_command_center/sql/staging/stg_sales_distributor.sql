-- stg_sales_distributor.sql
-- Standardize distributor daily sales extracts into a boring, typed, joinable staging view.

-- dbt:
-- create schema if not exists stg;

-- debug view: SELECT * FROM sales_distributor_extract;


--
create or replace view stg.stg_sales_distributor as
with base as (
    select
        -- lineage
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- raw/parsed fields from raw landing
        sale_date,
        sale_date_raw,

        store_id_norm,
        store_id_raw,

        sku,
        product_name_norm,
        product_name_raw,

        channel_norm,
        channel_raw,

        qty,
        qty_raw,

        unit_list_price,
        unit_list_price_raw,
        discount_rate,
        discount_rate_raw,
        unit_net_price,
        unit_net_price_raw,

        gross_sales,
        gross_sales_raw,
        discount_amount,
        discount_amount_raw,
        net_sales,
        net_sales_raw,
        cogs,
        cogs_raw,

        orders,
        orders_raw,
        customers,
        customers_raw
    from raw.sales_distributor_extract
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        /* date: safe parse from raw text if parsed date is null */
        coalesce(
            sale_date,
            case
                when sale_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then sale_date_raw::date
                when sale_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(sale_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as sale_date,
        sale_date_raw,

        /* keys */
        nullif(trim(store_id_norm), '') as store_code,
        store_id_raw,

        nullif(trim(sku), '') as sku,
        product_name_raw,
        nullif(trim(product_name_norm), '') as product_name,

        /* channel buckets */
        channel_raw,
        case
            when channel_norm is null then null
            when lower(trim(channel_norm)) like '%retail%' then 'retail'
            when lower(trim(channel_norm)) like '%wholesale%' then 'wholesale'
            when lower(trim(channel_norm)) like '%distrib%' then 'distributor'
            when lower(trim(channel_norm)) in ('retail','wholesale','distributor') then lower(trim(channel_norm))
            else nullif(lower(trim(channel_norm)), '')
        end as channel,

        /* numerics: prefer typed column; fall back to safe cast from *_raw */
        coalesce(
            qty,
            nullif(regexp_replace(trim(qty_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as qty,
        qty_raw,

        coalesce(
            unit_list_price::numeric,
            nullif(regexp_replace(trim(unit_list_price_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as unit_list_price,
        unit_list_price_raw,

        coalesce(
            discount_rate::numeric,
            nullif(regexp_replace(trim(discount_rate_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as discount_rate,
        discount_rate_raw,

        coalesce(
            unit_net_price::numeric,
            nullif(regexp_replace(trim(unit_net_price_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as unit_net_price,
        unit_net_price_raw,

        coalesce(
            gross_sales::numeric,
            nullif(regexp_replace(trim(gross_sales_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as gross_sales,
        gross_sales_raw,

        coalesce(
            discount_amount::numeric,
            nullif(regexp_replace(trim(discount_amount_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as discount_amount,
        discount_amount_raw,

        coalesce(
            net_sales::numeric,
            nullif(regexp_replace(trim(net_sales_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as net_sales,
        net_sales_raw,

        coalesce(
            cogs::numeric,
            nullif(regexp_replace(trim(cogs_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as cogs,
        cogs_raw,

        coalesce(
            orders,
            nullif(regexp_replace(trim(orders_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as orders,
        orders_raw,

        coalesce(
            customers,
            nullif(regexp_replace(trim(customers_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as customers,
        customers_raw
    from base
),
flags as (
    select
        *,
        /* required flags */
        (
            (gross_sales is not null and gross_sales < 0)
            or (net_sales is not null and net_sales < 0)
            or (discount_amount is not null and discount_amount < 0)
            or (cogs is not null and cogs < 0)
            or (gross_sales is not null and net_sales is not null and net_sales > gross_sales + 0.01)
            or (
                gross_sales is not null and net_sales is not null and discount_amount is not null
                and abs((net_sales + discount_amount) - gross_sales) > 0.50
            )
        ) as is_bad_amount,

        (sale_date is null or store_code is null or sku is null or channel is null) as is_missing_key,

        (
            count(*) over (
                partition by
                    load_id,
                    sale_date,
                    store_code,
                    sku,
                    channel,
                    coalesce(qty, -1),
                    coalesce(net_sales, -1::numeric)
            ) > 1
        ) as is_duplicate_candidate
    from casted
)
select * from flags;