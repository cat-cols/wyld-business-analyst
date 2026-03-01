create schema if not exists int;

create or replace view int.int_pos_dedup as
with base as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        txn_id,
        txn_ts_parsed,
        txn_date,

        store_code_norm as store_code,
        store_code_raw,

        product_sku_norm as sku,
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
    from raw.pos_transactions_csv
),
ranked as (
    select
        b.*,
        row_number() over (
            partition by b.txn_id
            order by
                (b.txn_ts_parsed is not null) desc,
                (b.store_code is not null) desc,
                (b.sku is not null) desc,
                b.ingested_at desc nulls last,
                b.drop_date desc nulls last,
                b.load_id desc nulls last
        ) as rn
    from base b
    where b.txn_id is not null
)
select *
from ranked
where rn = 1
;