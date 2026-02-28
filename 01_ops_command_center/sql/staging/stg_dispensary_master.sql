-- sql/staging/stg_dispensary_master.sql
-- Dispensary master/reference data (names, location, license, account type, etc.)
-- Raw source: raw.dispensary_master
-- Output: stg.stg_dispensary_master (typed-ish, normalized keys, flags)

create schema if not exists stg;

create or replace view stg.stg_dispensary_master as
with base as (
    select
        -- lineage
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- snapshot (optional but preferred)
        as_of_date,
        as_of_date_raw,

        -- keys
        dispensary_id_raw,
        dispensary_id_norm,
        store_code_raw,
        store_code_norm,

        -- identity
        dispensary_name_raw,
        dispensary_name_norm,

        -- location
        state_raw,
        state_norm,
        city_raw,
        city_norm,
        postal_code_raw,
        postal_code_norm,

        -- business attrs
        license_id_raw,
        license_id_norm,
        account_type_raw,
        account_type_norm
    from raw.dispensary_master
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        /* snapshot date: prefer typed, else parse */
        coalesce(
            as_of_date,
            case
                when as_of_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then as_of_date_raw::date
                when as_of_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(as_of_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as as_of_date,
        as_of_date_raw,

        /* keys */
        nullif(trim(dispensary_id_norm), '') as dispensary_id,
        dispensary_id_raw,

        nullif(trim(store_code_norm), '') as store_code,
        store_code_raw,

        /* identity */
        dispensary_name_raw,
        nullif(trim(dispensary_name_norm), '') as dispensary_name,

        /* location */
        state_raw,
        case
            when state_norm is null then null
            else upper(trim(state_norm))
        end as state,

        city_raw,
        nullif(initcap(trim(city_norm)), '') as city,

        postal_code_raw,
        nullif(trim(postal_code_norm), '') as postal_code,

        /* business attrs */
        license_id_raw,
        nullif(upper(trim(license_id_norm)), '') as license_id,

        account_type_raw,
        case
            when coalesce(account_type_norm, account_type_raw) is null then null
            else lower(trim(coalesce(account_type_norm, account_type_raw)))
        end as account_type
    from base
),
flags as (
    select
        *,

        /* choose your “required” keys */
        (dispensary_id is null or dispensary_name is null) as is_missing_key,

        /* sanity checks */
        (state is not null and length(state) <> 2) as is_bad_state_code,
        (postal_code is not null and length(postal_code) < 5) as is_bad_postal_code,

        /* duplicates at the snapshot grain */
        (
            count(*) over (
                partition by
                    coalesce(as_of_date, drop_date),
                    dispensary_id
            ) > 1
        ) as is_duplicate_candidate
    from casted
)
select * from flags;