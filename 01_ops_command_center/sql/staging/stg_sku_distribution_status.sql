-- sql/staging/stg_sku_distribution_status.sql
-- SKU distribution status by store/account (listed/not listed, active/inactive, discontinued, etc.)
-- Raw source: raw.sku_distribution_status
-- Output: stg.stg_sku_distribution_status (typed, normalized keys, flags)

create schema if not exists stg;

create or replace view stg.stg_sku_distribution_status as
with base as (
    select
        -- lineage
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- snapshot date
        as_of_date,
        as_of_date_raw,

        -- keys
        store_code_raw,
        store_code_norm,
        sku_raw,
        sku_norm,

        -- status attrs
        distribution_status_raw,
        distribution_status_norm,
        status_reason_raw,
        status_reason_norm
    from raw.sku_distribution_status
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        coalesce(
            as_of_date,
            case
                when as_of_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then as_of_date_raw::date
                when as_of_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(as_of_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as as_of_date,
        as_of_date_raw,

        nullif(trim(store_code_norm), '') as store_code,
        store_code_raw,

        nullif(trim(sku_norm), '') as sku,
        sku_raw,

        -- canonical bucket (prefer *_norm, fall back to *_raw)
        case
            when coalesce(distribution_status_norm, distribution_status_raw) is null then null
            else nullif(lower(trim(coalesce(distribution_status_norm, distribution_status_raw))), '')
        end as distribution_status,
        distribution_status_raw,

        nullif(trim(coalesce(status_reason_norm, status_reason_raw)), '') as status_reason,
        status_reason_raw
    from base
),
flags as (
    select
        *,
        (as_of_date is null or store_code is null or sku is null or distribution_status is null) as is_missing_key,
        (
            count(*) over (
                partition by load_id, as_of_date, store_code, sku, distribution_status
            ) > 1
        ) as is_duplicate_candidate
    from casted
)
select * from flags;