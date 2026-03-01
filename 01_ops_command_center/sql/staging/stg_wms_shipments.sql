-- sql/staging/stg_wms_shipments.sql
-- WMS shipments staging view (typed + normalized keys + basic QA flags)
-- Raw source: raw.wms_shipments
-- Output: stg.stg_wms_shipments

create schema if not exists stg;

create or replace view stg.stg_wms_shipments as
with base as (
    select
        -- lineage
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- dates
        ship_date,
        ship_date_raw,

        -- identifiers / keys
        shipment_id_norm,
        shipment_id_raw,

        site_code_norm,
        site_code_raw,

        sku_norm,
        sku_raw,

        -- measures / attrs
        units_shipped,
        units_shipped_raw,

        carrier_norm,
        carrier_raw
    from raw.wms_shipments
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        coalesce(
            ship_date,
            case
                when ship_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then ship_date_raw::date
                when ship_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(ship_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as ship_date,
        ship_date_raw,

        nullif(trim(shipment_id_norm), '') as shipment_id,
        shipment_id_raw,

        nullif(trim(site_code_norm), '') as site_code,
        site_code_raw,

        nullif(trim(sku_norm), '') as sku,
        sku_raw,

        coalesce(
            units_shipped,
            nullif(regexp_replace(trim(units_shipped_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as units_shipped,
        units_shipped_raw,

        nullif(trim(carrier_norm), '') as carrier,
        carrier_raw
    from base
),
flags as (
    select
        *,
        -- keys required for joining / facts
        (ship_date is null or site_code is null or sku is null) as is_missing_key,

        -- duplicates are expected in messy landings; truth selection happens in int layer
        (
            count(*) over (
                partition by load_id, ship_date, site_code, sku, shipment_id
            ) > 1
        ) as is_duplicate_candidate,

        -- basic sanity checks
        (units_shipped is not null and units_shipped < 0) as is_negative_units,
        (units_shipped is null) as is_missing_units
    from casted
)
select * from flags;