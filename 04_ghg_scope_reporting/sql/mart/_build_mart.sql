\echo 'Build mart views'

\ir fact_emissions.sql
\ir kpi_emissions_intensity_monthly.sql
\ir controls_missing_factor_joins.sql
\ir controls_negative_activity.sql
\ir controls_missing_dim_joins.sql
\ir controls_unknown_activity_type.sql
\ir controls_duplicate_source_records.sql