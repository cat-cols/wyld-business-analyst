-- Standardize finance actuals summary for reconciliation
-- SELECT * FROM raw_finance_actuals_summary;
-- stg_finance_actuals.sql
-- Standardize monthly finance actuals; map metric labels to KPI categories; keep source labels/totals for reconciliation.

create schema if not exists stg;

create or replace view stg.stg_finance_actuals as
with base as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        month_start,
        month_start_raw,

        metric_name_norm,
        metric_name_raw,

        actual_amount,
        actual_amount_raw,

        currency_code_norm,
        currency_code_raw
    from raw.finance_actuals_summary
),
casted as (
    select
        load_id,
        source_system,
        cadence,
        drop_date,
        ingested_at,

        /* standardize period month (first of month) */
        date_trunc(
            'month',
            coalesce(
                month_start,
                case
                    when month_start_raw ~ '^\d{4}-\d{2}-\d{2}$' then month_start_raw::date
                    when month_start_raw ~ '^\d{2}/\d{2}/\d{4}$' then to_date(month_start_raw, 'MM/DD/YYYY')
                    else null
                end
            )
        )::date as period_month,
        month_start_raw,

        metric_name_raw,
        nullif(lower(trim(metric_name_norm)), '') as metric_name,

        coalesce(
            actual_amount::numeric,
            nullif(regexp_replace(trim(actual_amount_raw), '[^0-9\.\-]+', '', 'g'), '')::numeric
        ) as actual_amount,
        actual_amount_raw,

        nullif(upper(trim(currency_code_norm)), '') as currency_code,
        currency_code_raw
    from base
),
mapped as (
    select
        *,
        /* map finance account/metric labels to KPI categories */
        case
            when metric_name is null then 'unknown'
            when metric_name like '%gross%sales%' then 'gross_sales'
            when metric_name like '%net%sales%' then 'net_sales'
            when metric_name like '%cogs%' or metric_name like '%cost%of%goods%' then 'cogs'
            when metric_name like '%gross%margin%' then 'gross_margin'
            when metric_name like '%labor%cost%' then 'labor_cost'
            else 'unknown'
        end as kpi_category
    from casted
),
flags as (
    select
        *,
        (kpi_category = 'unknown') as is_unmapped_metric,
        (period_month is null or metric_name is null) as is_missing_key
    from mapped
)
select * from flags;