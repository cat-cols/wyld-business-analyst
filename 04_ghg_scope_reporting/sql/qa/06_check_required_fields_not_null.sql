\echo 'QA: required fields are populated for reportable emissions rows'

do $$
begin
    if exists (
        select 1
        from mart.fact_emissions
        where is_reportable_emissions_row
          and (
              activity_id is null
              or source_system is null
              or source_record_id is null
              or activity_month is null
              or scope is null
              or facility_id is null
              or activity_category is null
              or factor_type is null
              or activity_amount is null
              or activity_unit is null
              or factor_id is null
              or factor_version is null
              or factor_value_kg_co2e_per_unit is null
              or kg_co2e is null
              or metric_tons_co2e is null
              or qa_status_label is null
          )
    ) then
        raise exception 'QA failed: required fields are null on reportable emissions rows';
    end if;
end $$;

select
    'PASS: required fields are populated for reportable emissions rows' as qa_result;