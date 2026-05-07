\echo 'QA: materiality threshold checks'

with base as (
    select count(*)::numeric as total_rows
    from mart.fact_emissions
),

actuals as (
    select
        'duplicate_source_records' as control_name,
        count(*)::numeric as exception_rows
    from mart.controls_duplicate_source_records

    union all

    select
        'non_reportable_rows',
        count(*)::numeric
    from mart.fact_emissions
    where not is_reportable_emissions_row

    union all

    select
        'missing_factor_joins',
        count(*)::numeric
    from mart.fact_emissions
    where has_missing_factor_join

    union all

    select
        'negative_activity_rows',
        count(*)::numeric
    from mart.fact_emissions
    where has_negative_activity

    union all

    select
        'unknown_activity_type_rows',
        count(*)::numeric
    from mart.fact_emissions
    where has_unknown_activity_type

    union all

    select
        'missing_dimension_joins',
        count(*)::numeric
    from mart.fact_emissions
    where has_missing_facility_join
       or has_missing_product_line_join
),

scored as (
    select
        a.control_name,
        a.exception_rows,
        b.total_rows,
        round(a.exception_rows / nullif(b.total_rows, 0), 6) as exception_pct,
        t.warning_row_threshold,
        t.failure_row_threshold,
        t.warning_pct_threshold,
        t.failure_pct_threshold,
        t.severity,
        case
            when t.failure_row_threshold is not null
             and a.exception_rows >= t.failure_row_threshold
                then 'FAIL'
            when t.failure_pct_threshold is not null
             and (a.exception_rows / nullif(b.total_rows, 0)) >= t.failure_pct_threshold
                then 'FAIL'
            when t.warning_row_threshold is not null
             and a.exception_rows >= t.warning_row_threshold
                then 'WARN'
            when t.warning_pct_threshold is not null
             and (a.exception_rows / nullif(b.total_rows, 0)) >= t.warning_pct_threshold
                then 'WARN'
            else 'PASS'
        end as materiality_status
    from actuals a
    cross join base b
    left join qa.materiality_thresholds t
        on a.control_name = t.control_name
)

select *
from scored
order by
    case materiality_status
        when 'FAIL' then 1
        when 'WARN' then 2
        else 3
    end,
    control_name;

do $$
begin
    if exists (
        with base as (
            select count(*)::numeric as total_rows
            from mart.fact_emissions
        ),
        actuals as (
            select 'duplicate_source_records' as control_name, count(*)::numeric as exception_rows from mart.controls_duplicate_source_records
            union all select 'non_reportable_rows', count(*)::numeric from mart.fact_emissions where not is_reportable_emissions_row
            union all select 'missing_factor_joins', count(*)::numeric from mart.fact_emissions where has_missing_factor_join
            union all select 'negative_activity_rows', count(*)::numeric from mart.fact_emissions where has_negative_activity
            union all select 'unknown_activity_type_rows', count(*)::numeric from mart.fact_emissions where has_unknown_activity_type
            union all select 'missing_dimension_joins', count(*)::numeric from mart.fact_emissions where has_missing_facility_join or has_missing_product_line_join
        )
        select 1
        from actuals a
        cross join base b
        join qa.materiality_thresholds t
            on a.control_name = t.control_name
        where (
            t.failure_row_threshold is not null
            and a.exception_rows >= t.failure_row_threshold
        )
        or (
            t.failure_pct_threshold is not null
            and (a.exception_rows / nullif(b.total_rows, 0)) >= t.failure_pct_threshold
        )
    ) then
        raise exception 'QA failed: one or more materiality thresholds exceeded failure limits';
    end if;
end $$;

select 'PASS: no materiality failure thresholds exceeded' as qa_result;
