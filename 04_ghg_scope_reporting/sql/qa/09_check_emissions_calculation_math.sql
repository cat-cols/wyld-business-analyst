\echo 'QA: emissions calculation math'

do $$
begin
    if exists (
        select 1
        from mart.fact_emissions
        where is_reportable_emissions_row
          and abs(
                metric_tons_co2e
                - ((activity_amount * factor_value_kg_co2e_per_unit) / 1000.0)
              ) > 0.0001
    ) then
        raise exception 'QA failed: metric_tons_co2e does not match activity_amount * factor / 1000';
    end if;
end $$;

select
    'PASS: emissions calculation math is valid for reportable rows' as qa_result;