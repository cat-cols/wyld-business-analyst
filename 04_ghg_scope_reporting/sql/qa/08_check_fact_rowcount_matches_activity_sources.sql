\echo 'QA: fact_emissions rowcount matches activity source rows'

do $$
declare
    source_row_count integer;
    fact_row_count integer;
begin
    select
        (
            (select count(*) from raw.ghg_electricity_bills_monthly)
          + (select count(*) from raw.ghg_fuel_usage_facility)
          + (select count(*) from raw.ghg_shipping_miles_logistics)
          + (select count(*) from raw.ghg_packaging_materials_procurement)
        )
    into source_row_count;

    select count(*)
    from mart.fact_emissions
    into fact_row_count;

    if source_row_count <> fact_row_count then
        raise exception
            'QA failed: fact_emissions rowcount (%) does not match source activity rowcount (%)',
            fact_row_count,
            source_row_count;
    end if;
end $$;

select
    'PASS: fact_emissions rowcount matches activity source rows' as qa_result;