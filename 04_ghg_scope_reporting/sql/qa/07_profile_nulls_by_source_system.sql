\echo 'QA: null profile by source system'

select
    source_system,
    count(*) as total_rows,

    count(*) filter (where activity_month is null) as null_activity_month_rows,
    count(*) filter (where facility_id is null) as null_facility_id_rows,
    count(*) filter (where product_line_id is null) as null_product_line_id_rows,
    count(*) filter (where activity_amount is null) as null_activity_amount_rows,
    count(*) filter (where activity_unit is null) as null_activity_unit_rows,
    count(*) filter (where factor_type is null) as null_factor_type_rows,
    count(*) filter (where factor_id is null) as null_factor_id_rows,
    count(*) filter (where metric_tons_co2e is null) as null_metric_tons_co2e_rows,
    count(*) filter (where evidence_reference is null) as null_evidence_reference_rows

from mart.fact_emissions
group by source_system
order by source_system;