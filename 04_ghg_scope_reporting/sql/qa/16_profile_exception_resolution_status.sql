\echo 'QA profile: exception resolution status'

with current_exceptions as (
    select
        md5(concat_ws('|', 'unknown_activity_type', activity_month::text, source_system, facility_id, product_line_id, evidence_reference)) as exception_id,
        'unknown_activity_type' as exception_type,
        source_system,
        evidence_reference,
        activity_month,
        facility_id,
        product_line_id
    from mart.controls_unknown_activity_type

    union all

    select
        md5(concat_ws('|', 'negative_activity', activity_month::text, source_system, facility_id, product_line_id, evidence_reference)) as exception_id,
        'negative_activity' as exception_type,
        source_system,
        evidence_reference,
        activity_month,
        facility_id,
        product_line_id
    from mart.controls_negative_activity

    union all

    select
        md5(concat_ws('|', 'missing_dim_join', activity_month::text, source_system, facility_id, product_line_id, evidence_reference)) as exception_id,
        'missing_dim_join' as exception_type,
        source_system,
        evidence_reference,
        activity_month,
        facility_id,
        product_line_id
    from mart.controls_missing_dim_joins

    union all

    select
        md5(concat_ws('|', 'missing_factor_join', first_activity_month::text, source_system, factor_type, activity_unit)) as exception_id,
        'missing_factor_join' as exception_type,
        source_system,
        null::text as evidence_reference,
        first_activity_month as activity_month,
        null::text as facility_id,
        null::text as product_line_id
    from mart.controls_missing_factor_joins
),

resolution_status as (
    select
        ce.exception_type,
        ce.source_system,
        count(*) as current_exception_count,
        count(*) filter (where erl.resolution_status = 'resolved') as resolved_count,
        count(*) filter (where erl.resolution_status = 'in_progress') as in_progress_count,
        count(*) filter (where erl.resolution_status is null or erl.resolution_status = 'open') as open_or_unlogged_count
    from current_exceptions ce
    left join qa.exception_resolution_log erl
        on ce.exception_id = erl.exception_id
    group by
        ce.exception_type,
        ce.source_system
)

select *
from resolution_status
order by
    exception_type,
    source_system;

do $$
begin
    raise notice 'Exception resolution profile is informational. Add rows to qa.exception_resolution_log to track remediation ownership and status.';
end $$;
