create or replace view stg.stg_ghg_fuel_usage as
with source as (
    select
        row_number() over () as raw_row_id,
        *
    from raw.ghg_fuel_usage_facility
),

normalized as (
    select
        raw_row_id,

        case
            when trim(activity_month) ~ '^\d{4}-\d{2}-\d{2}$'
                then trim(activity_month)::date
            when trim(activity_month) ~ '^[A-Za-z]{3}-\d{4}$'
                then to_date(trim(activity_month), 'Mon-YYYY')
            when trim(activity_month) ~ '^\d{1,2}/\d{1,2}/\d{4}$'
                then to_date(trim(activity_month), 'MM/DD/YYYY')
            else null
        end as activity_month,

        upper(nullif(trim(facility_id), '')) as facility_id,

        case
            when lower(trim(fuel_type)) in ('natural gas', 'natural_gas')
                then 'natural_gas'
            when lower(trim(fuel_type)) = 'diesel'
                then 'diesel'
            when lower(trim(fuel_type)) = 'gasoline'
                then 'gasoline'
            else lower(trim(fuel_type))
        end as fuel_type,

        case
            when trim(activity_amount) ~ '^-?\d+(\.\d+)?$'
                then trim(activity_amount)::numeric(18, 4)
            else null
        end as activity_amount,

        case
            when lower(trim(activity_unit)) in ('gal', 'gallon', 'gallons')
                then 'gallon'
            when lower(trim(activity_unit)) in ('therm', 'therms')
                then 'therm'
            else lower(trim(activity_unit))
        end as activity_unit,

        trim(vendor_name) as vendor_name,
        upper(nullif(trim(invoice_number), '')) as invoice_number,

        case
            when trim(cost_usd) ~ '^-?\d+(\.\d+)?$'
                then trim(cost_usd)::numeric(18, 2)
            else null
        end as cost_usd

    from source
),

classified as (
    select
        *,
        'Scope 1' as scope,

        case
            when fuel_type = 'natural_gas' and activity_unit = 'therm'
                then 'natural_gas_therm'
            when fuel_type = 'diesel' and activity_unit = 'gallon'
                then 'diesel_gallon'
            when fuel_type = 'gasoline' and activity_unit = 'gallon'
                then 'gasoline_gallon'
            else null
        end as factor_type,

        case
            when fuel_type = 'natural_gas' and activity_unit <> 'therm'
                then true
            when fuel_type in ('diesel', 'gasoline') and activity_unit <> 'gallon'
                then true
            else false
        end as has_invalid_fuel_unit,

        'fuel_usage' as source_system

    from normalized
)

select
    *,
    activity_amount < 0 as has_negative_activity,
    facility_id is null as has_missing_facility_id,
    activity_month is null as has_invalid_activity_month,
    factor_type is null as has_unknown_fuel_type
from classified;