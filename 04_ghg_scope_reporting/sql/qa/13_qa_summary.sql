select
    source_system,
    scope,
    count(*) as total_rows,
    count(*) filter (where is_reportable_emissions_row) as reportable_rows,
    count(*) filter (where has_negative_activity) as negative_activity_rows,
    count(*) filter (where has_missing_facility_id) as missing_facility_id_rows,
    count(*) filter (where has_missing_product_line_id) as missing_product_line_id_rows,
    count(*) filter (where has_invalid_activity_month) as invalid_activity_month_rows,
    count(*) filter (where has_unknown_activity_type) as unknown_activity_type_rows,
    count(*) filter (where has_missing_facility_join) as missing_facility_join_rows,
    count(*) filter (where has_missing_product_line_join) as missing_product_line_join_rows,
    count(*) filter (where has_missing_factor_join) as missing_factor_join_rows,
    round(sum(metric_tons_co2e) filter (where is_reportable_emissions_row), 2) as reportable_metric_tons_co2e
from mart.fact_emissions
group by
    source_system,
    scope
order by
    source_system,
    scope;