-- sql/staging/stg_dispensary_master.sql
-- Dispensary master/reference data (names, location, license, channel, etc.)
-- Output: stg.stg_dispensary_master (typed-ish, normalized keys, flags)

create schema if not exists stg;

create or replace view stg.stg_dispensary_master as
with base as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        dispensary_id_raw,
        dispensary_id_norm,

        dispensary_name_raw,
        dispensary_name_norm,

        state_raw,
        state_norm,

        city_raw,
        city_norm,

        address1_raw,
        address1_norm,

        postal_code_raw,
        postal_code_norm,

        license_number_raw,
        license_number_norm,

        channel_raw,
        channel_norm
    from raw.dispensary_master
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

        dispensary_name_raw,
        nullif(trim(dispensary_name_norm), '') as dispensary_name,

        state_raw,
        case
            when state_norm is null then null
            else upper(trim(state_norm))
        end as state,

        city_raw,
        nullif(initcap(trim(city_norm)), '') as city,

        address1_raw,
        nullif(trim(address1_norm), '') as address1,

        postal_code_raw,
        nullif(trim(postal_code_norm), '') as postal_code,

        license_number_raw,
        nullif(upper(trim(license_number_norm)), '') as license_number,

        channel_raw,
        case
            when channel_norm is null then null
            when lower(trim(channel_norm)) like '%retail%' then 'retail'
            when lower(trim(channel_norm)) like '%wholesale%' then 'wholesale'
            when lower(trim(channel_norm)) like '%distrib%' then 'distributor'
            else nullif(lower(trim(channel_norm)), '')
        end as channel
    from base
),
flags as (
    select
        *,

        (dispensary_id is null or dispensary_name is null) as is_missing_key,

        /* lightweight sanity checks */
        (state is not null and length(state) <> 2) as is_bad_state_code,
        (postal_code is not null and length(postal_code) < 5) as is_bad_postal_code
    from clean
)
select * from flags;