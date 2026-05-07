\echo 'QA: reportability logic consistency'

do $$
begin
    if exists (
        select 1
        from mart.fact_emissions
        where is_reportable_emissions_row
          and (
                has_negative_activity
             or has_missing_facility_id
             or has_invalid_activity_month
             or has_unknown_activity_type
             or has_missing_facility_join
             or has_missing_factor_join
          )
    ) then
        raise exception 'QA failed: reportable rows contain blocking QA flags';
    end if;
end $$;

select
    'PASS: reportable rows do not contain blocking QA flags' as qa_result;