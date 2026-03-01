-- Standardize inventory ERP snapshot extract
-- SELECT * FROM raw_inventory_erp_snapshot;

-- stg_inventory_erp.sql
-- Standardize ERP inventory snapshots into a typed, joinable staging view with flags.

create schema if not exists stg;

create or replace view stg.stg_inventory_erp as
with base as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        snapshot_date,
        snapshot_date_raw,

        site_code_norm,
        site_code_raw,

        sku,

        on_hand,
        on_hand_raw,

        receipts,
        receipts_raw,

        shipments,
        shipments_raw,

        requested_units,
        requested_units_raw,

        backordered_units,
        backordered_units_raw
    from raw.inventory_erp_snapshot
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        coalesce(
            snapshot_date,
            case
                when snapshot_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then snapshot_date_raw::date
                when snapshot_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(snapshot_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as snapshot_date,
        snapshot_date_raw,

        nullif(trim(site_code_norm), '') as site_code,
        site_code_raw,

        nullif(trim(sku), '') as sku,

        coalesce(
            on_hand,
            nullif(regexp_replace(trim(on_hand_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as on_hand,
        on_hand_raw,

        /* split to received_units / shipped_units as requested */
        coalesce(
            receipts,
            nullif(regexp_replace(trim(receipts_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as received_units,
        receipts_raw as received_units_raw,

        coalesce(
            shipments,
            nullif(regexp_replace(trim(shipments_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as shipped_units,
        shipments_raw as shipped_units_raw,

        coalesce(
            requested_units,
            nullif(regexp_replace(trim(requested_units_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as requested_units,
        requested_units_raw,

        coalesce(
            backordered_units,
            nullif(regexp_replace(trim(backordered_units_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as backordered_units,
        backordered_units_raw
    from base
),
flags as (
    select
        *,

        /* ensure on-hand is nonnegative for downstream use (but keep original on_hand for auditing) */
        case
            when on_hand is null then null
            else greatest(on_hand, 0)
        end as on_hand_nonnegative,

        (on_hand is not null and on_hand < 0) as is_negative_inventory,

        (coalesce(greatest(on_hand, 0), 0) > 0) as in_stock_flag,

        (snapshot_date is null or site_code is null or sku is null) as is_missing_key
    from casted
)
select * from flags;