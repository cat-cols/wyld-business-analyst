-- Standardize labor/payroll extract
-- SELECT * FROM raw_labor_hours_payroll_export;

-- stg_labor_payroll.sql
-- Standardize weekly payroll export into a typed staging view; normalize dept/team labels; add missing dept/team flag.

create schema if not exists stg;

create or replace view stg.stg_labor_payroll as
with base as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        week_ending,
        week_ending_raw,

        site_code_norm,
        site_code_raw,

        department_norm,
        department_raw,

        team_norm,
        team_raw,

        hours_worked,
        hours_worked_raw,

        ot_hours,
        ot_hours_raw,

        employee_count,
        employee_count_raw,

        labor_cost,
        labor_cost_raw
    from raw.project1_payroll_weekly
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        coalesce(
            week_ending,
            case
                when week_ending_raw ~ '^\d{4}-\d{2}-\d{2}$' then week_ending_raw::date
                when week_ending_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(week_ending_raw, 'MM/DD/YYYY')
                else null
            end
        ) as week_ending,
        week_ending_raw,

        nullif(trim(site_code_norm), '') as site_code,
        site_code_raw,

        nullif(lower(trim(department_norm)), '') as department,
        department_raw,

        /* normalize employee group/team names */
        case
            when team_norm is null then null
            when lower(trim(team_norm)) in ('fulfilment') then 'fulfillment'
            else nullif(lower(trim(team_norm)), '')
        end as team,
        team_raw,

        coalesce(
            hours_worked::numeric,
            nullif(regexp_replace(trim(hours_worked_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as hours_worked,
        hours_worked_raw,

        coalesce(
            ot_hours::numeric,
            nullif(regexp_replace(trim(ot_hours_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as ot_hours,
        ot_hours_raw,

        coalesce(
            employee_count,
            nullif(regexp_replace(trim(employee_count_raw), '[^0-9\-]+', '', 'g'), '')::integer
        ) as employee_count,
        employee_count_raw,

        coalesce(
            labor_cost::numeric,
            nullif(regexp_replace(trim(labor_cost_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as labor_cost,
        labor_cost_raw
    from base
),
flags as (
    select
        *,
        (department is null or team is null) as is_missing_department_or_team
    from casted
)
select * from flags;