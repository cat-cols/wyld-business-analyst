-- sql/staging/stg_pos_transactions.sql
-- POS transactions staging view (typed + normalized keys + basic QA flags)
-- Raw source: raw.pos_transactions_csv
-- Output: stg.stg_pos_transactions

create schema if not exists stg;

create or replace view stg.stg_pos_transactions as
with base as (
    select
        -- lineage
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- transaction identifiers / timestamps
        txn_id,
        txn_ts_raw,
        txn_ts_parsed,
        txn_date,

        -- keys
        store_code_raw,
        store_code_norm,
        product_sku_raw,
        product_sku_norm,

        -- measures
        qty_raw,
        qty,
        unit_price_raw,
        unit_price,
        discount_pct_raw,
        discount_pct,
        gross_amount_raw,
        gross_amount,
        net_amount_raw,
        net_amount
    from raw.pos_transactions_csv
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        txn_id,
        txn_ts_raw,
        txn_ts_parsed,
        txn_date,

        nullif(trim(store_code_norm), '') as store_code,
        store_code_raw,

        nullif(trim(product_sku_norm), '') as sku,
        product_sku_raw,

        qty,
        qty_raw,

        unit_price,
        unit_price_raw,

        discount_pct,
        discount_pct_raw,

        gross_amount,
        gross_amount_raw,

        net_amount,
        net_amount_raw
    from base
),
flags as (
    select
        *,
        (txn_id is null or txn_date is null or store_code is null or sku is null) as is_missing_key,
        (
            count(*) over (partition by txn_id) > 1
        ) as is_duplicate_candidate
    from casted
)
select * from flags;