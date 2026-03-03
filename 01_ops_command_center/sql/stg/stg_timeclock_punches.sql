-- 01_ops_command_center/sql/staging/stg_timeclock_punches.sql
-- Standardize timeclock punches into a typed staging view; normalize keys + action; add basic flags.
-- Raw source: raw.timeclock_punches

create schema if not exists stg;

create or replace view stg.stg_timeclock_punches as
with base as (
    select
        -- lineage
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        -- timestamps/dates
        punch_ts_parsed,
        punch_ts_raw,
        punch_date,

        -- keys
        employee_id,
        employee_id_raw,
        site_code_norm,
        site_code_raw,

        -- event
        action_norm,
        action_raw
    from raw.timeclock_punches
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        coalesce(
            punch_ts_parsed,
            case
                when punch_ts_raw is null then null
                -- tolerate either "YYYY-MM-DD HH:MM:SS" or "MM/DD/YYYY HH:MM"
                when punch_ts_raw ~ '^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}$' then punch_ts_raw::timestamp
                when punch_ts_raw ~ '^\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}$' then to_timestamp(punch_ts_raw, 'MM/DD/YYYY HH24:MI')
                else null
            end
        ) as punch_ts,
        punch_ts_raw,

        coalesce(
            punch_date,
            case
                when punch_ts_raw ~ '^\d{4}-\d{2}-\d{2}' then (left(punch_ts_raw, 10))::date
                when punch_ts_raw ~ '^\d{2}/\d{2}/\d{4}' then to_date(left(punch_ts_raw, 10), 'MM/DD/YYYY')
                else null
            end
        ) as punch_date,
        punch_date as punch_date_src,

        nullif(trim(site_code_norm), '') as site_code,
        site_code_raw,

        coalesce(
            employee_id,
            nullif(regexp_replace(trim(employee_id_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as employee_id,
        employee_id_raw,

        -- normalize action (prefer action_norm, fall back to action_raw)
        case
            when coalesce(action_norm, action_raw) is null then null
            when upper(trim(coalesce(action_norm, action_raw))) in ('IN','CLOCKIN','CLOCK_IN','START','PUNCHIN','PUNCH_IN') then 'IN'
            when upper(trim(coalesce(action_norm, action_raw))) in ('OUT','CLOCKOUT','CLOCK_OUT','END','PUNCHOUT','PUNCH_OUT') then 'OUT'
            else nullif(upper(trim(coalesce(action_norm, action_raw))), '')
        end as action,
        action_raw
    from base
),
flags as (
    select
        *,
        -- missing key if any core key is missing
        (punch_ts is null or punch_date is null or site_code is null or employee_id is null or action is null) as is_missing_key,

        -- duplicates at natural grain
        (
            count(*) over (
                partition by load_id, punch_ts, site_code, employee_id, action
            ) > 1
        ) as is_duplicate_candidate,

        -- sanity flags
        (action is not null and action not in ('IN','OUT')) as is_bad_action
    from casted
)
select * from flags;
