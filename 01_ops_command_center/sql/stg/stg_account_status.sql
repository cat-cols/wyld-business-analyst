-- sql/staging/stg_account_status.sql
-- Account / customer status by dispensary/account (sell-to / not-sell-to, active/inactive, etc.)
-- Standardize account status into a typed, joinable staging view.
-- Raw source: raw.account_status
-- Output: stg.stg_account_status (typed, normalized keys, flags)

create schema if not exists stg;

create or replace view stg.stg_account_status as
with base as (
    select
        -- lineage
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- dates
        status_date,
        status_date_raw,

        -- keys
        store_code_raw,
        store_code_norm,

        -- status + reason
        account_status_raw,
        account_status_norm,
        status_reason_raw,
        status_reason_norm
    from raw.account_status
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        coalesce(
            status_date,
            case
                when status_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then status_date_raw::date
                when status_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(status_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as status_date,
        status_date_raw,

        nullif(trim(store_code_norm), '') as store_code,
        nullif(trim(store_code_raw), '') as store_code_raw,

        -- canonical status bucket (prefer *_norm)
        case
            when coalesce(account_status_norm, account_status_raw) is null then null
            when lower(trim(coalesce(account_status_norm, account_status_raw))) like '%inactive%' then 'inactive'
            when lower(trim(coalesce(account_status_norm, account_status_raw))) like '%suspend%' then 'suspended'
            when lower(trim(coalesce(account_status_norm, account_status_raw))) like '%pending%' then 'pending'
            when lower(trim(coalesce(account_status_norm, account_status_raw))) like '%active%' then 'active'
            else nullif(lower(trim(coalesce(account_status_norm, account_status_raw))), '')
        end as account_status,
        account_status_raw,

        nullif(trim(status_reason_norm), '') as status_reason,
        status_reason_raw
    from base
),
flags as (
    select
        *,
        (status_date is null or store_code is null or account_status is null) as is_missing_key,
        (
            count(*) over (
                partition by load_id, status_date, store_code, account_status
            ) > 1
        ) as is_duplicate_candidate
    from casted
)
select * from flags;