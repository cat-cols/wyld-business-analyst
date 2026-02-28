-- sql/staging/stg_account_status.sql
-- Account / customer status by dispensary/account (sell-to / not-sell-to, active/inactive, etc.)
-- Output: stg.stg_account_status (typed, normalized keys, flags)

create schema if not exists stg;

create or replace view stg.stg_account_status as
with base as (
    select
        -- lineage (keep if present in raw)
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- expected raw fields
        dispensary_id_raw,
        dispensary_id_norm,

        account_status_raw,
        account_status_norm,

        status_effective_date_raw,
        status_effective_date,

        status_end_date_raw,
        status_end_date,

        status_reason_raw,
        status_reason_norm
    from raw.account_status
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

        account_status_raw,

        /* normalize to a small set of buckets */
        case
            when account_status_norm is null then null
            when lower(trim(account_status_norm)) in ('active','enabled','open','good standing') then 'active'
            when lower(trim(account_status_norm)) in ('inactive','disabled','paused','on hold','hold') then 'inactive'
            when lower(trim(account_status_norm)) in ('suspended','suspension') then 'suspended'
            when lower(trim(account_status_norm)) in ('closed','terminated') then 'closed'
            when lower(trim(account_status_norm)) in ('prospect','lead') then 'prospect'
            when lower(trim(account_status_norm)) like '%not%selling%' then 'not_selling'
            when lower(trim(account_status_norm)) like '%selling%' then 'selling'
            else nullif(lower(trim(account_status_norm)), '')
        end as account_status,

        /* dates: prefer typed; fall back to text parsing */
        coalesce(
            status_effective_date,
            case
                when status_effective_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then status_effective_date_raw::date
                when status_effective_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(status_effective_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as status_effective_date,
        status_effective_date_raw,

        coalesce(
            status_end_date,
            case
                when status_end_date_raw ~ '^\d{4}-\d{2}-\d{2}$' then status_end_date_raw::date
                when status_end_date_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(status_end_date_raw, 'MM/DD/YYYY')
                else null
            end
        ) as status_end_date,
        status_end_date_raw,

        status_reason_raw,
        nullif(lower(trim(status_reason_norm)), '') as status_reason
    from base
),
flags as (
    select
        *,

        (dispensary_id is null or account_status is null or status_effective_date is null) as is_missing_key,

        (account_status is null) as is_unmapped_status,

        (
            status_end_date is not null
            and status_effective_date is not null
            and status_end_date < status_effective_date
        ) as is_bad_date_range
    from clean
)
select * from flags;