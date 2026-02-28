-- sql/staging/stg_sku_distribution_status.sql
-- SKU x dispensary distribution/listing status (listed, active, discontinued, etc.)
-- Output: stg.stg_sku_distribution_status (typed, normalized keys, flags)

create schema if not exists stg;

create or replace view stg.stg_sku_distribution_status as
with base as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        dispensary_id_raw,
        dispensary_id_norm,

        sku_raw,
        sku_norm,

        distribution_status_raw,
        distribution_status_norm,

        first_listed_date_raw,
        first_listed_date,

        last_sold_date_raw,
        last_sold_date
    from raw.sku_distribution_status
),
clean as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        nullif(trim(dispensary_id_norm), '') as dispensary_id,
        dispensary_id_raw,

        nullif(trim(sku_norm), '') as sku,
        sku_raw,

        distribution_status_raw,
        case
            when distribution_status_norm is null then null
            when lower(trim(distribution_status_norm)) in ('listed','active','available','enabled','in distribution') then 'active'
            when lower(trim(distribution_status_norm)) in ('not listed','unlisted','inactive','disabled') then 'inactive'
            when lower(trim(distribution_status_norm)) in ('discontinued','delisted','retired') then 'discontinued'
            when lower(trim(distribution_status_norm)) in ('out of stock','oos') then 'oos'
            else nullif(lower(trim(distribution_status_norm)), '')
        end as distribution_status,

        /* derived booleans */
        case
            when lower(trim(distribution_status_norm)) in ('listed','active','available','enabled','in distribution') then true
            when lower(trim(distribution_status_norm)) in ('not listed','unlisted','inactive','disabled','discontinued','delisted','retired') then false
            else null
        end as is_listed,

        coalesce(
            first_listed_date,
            case
                when first_listed_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then first_listed_date_raw::date
                when first_listed_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(first_listed_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as first_listed_date,
        first_listed_date_raw,

        coalesce(
            last_sold_date,
            case
                when last_sold_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then last_sold_date_raw::date
                when last_sold_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(last_sold_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as last_sold_date,
        last_sold_date_raw
    from base
),
flags as (
    select
        *,

        (dispensary_id is null or sku is null) as is_missing_key,

        (distribution_status is null) as is_unmapped_status,

        (
            first_listed_date is not null
            and last_sold_date is not null
            and last_sold_date < first_listed_date
        ) as is_bad_date_range
    from clean
)
select * from flags;