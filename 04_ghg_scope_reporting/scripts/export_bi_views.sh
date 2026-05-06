#!/usr/bin/env bash
set -euo pipefail

mkdir -p 04_ghg_scope_reporting/bi_exports

psql "$P1_PG_OPS" -c "\copy (select * from mart.fact_emissions) to '04_ghg_scope_reporting/bi_exports/fact_emissions.csv' csv header"
psql "$P1_PG_OPS" -c "\copy (select * from mart.kpi_emissions_intensity_monthly) to '04_ghg_scope_reporting/bi_exports/kpi_emissions_intensity_monthly.csv' csv header"
psql "$P1_PG_OPS" -c "\copy (select * from mart.controls_unknown_activity_type) to '04_ghg_scope_reporting/bi_exports/controls_unknown_activity_type.csv' csv header"
psql "$P1_PG_OPS" -c "\copy (select * from mart.controls_negative_activity) to '04_ghg_scope_reporting/bi_exports/controls_negative_activity.csv' csv header"
psql "$P1_PG_OPS" -c "\copy (select * from mart.controls_missing_factor_joins) to '04_ghg_scope_reporting/bi_exports/controls_missing_factor_joins.csv' csv header"
psql "$P1_PG_OPS" -c "\copy (select * from mart.controls_missing_dim_joins) to '04_ghg_scope_reporting/bi_exports/controls_missing_dim_joins.csv' csv header"

echo ""
echo "BI exports written to 04_ghg_scope_reporting/bi_exports"
ls -lh 04_ghg_scope_reporting/bi_exports