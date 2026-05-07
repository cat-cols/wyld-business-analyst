\echo '============================================================'
\echo 'GHG SCOPE REPORTING QA START'
\echo 'Core QA + advanced governance controls'
\echo '============================================================'

\echo 'QA setup: create QA persistence tables'
\ir 00_create_qa_tables.sql

\echo 'QA setup: start QA run history record'
\ir 00_start_qa_run.sql

\echo 'QA 1: raw rowcounts'
\ir 01_check_raw_rowcounts.sql

\echo 'QA 2: fact_emissions activity_id uniqueness'
\ir 02_check_fact_emissions_unique_activity_id.sql

\echo 'QA 3: reportable emissions rows have calculated emissions'
\ir 03_check_reportable_emissions_not_null.sql

\echo 'QA 4: clean rows have factor joins'
\ir 04_check_clean_rows_have_factor.sql

\echo 'QA 5: duplicate source records'
\ir 05_check_duplicate_source_records.sql

\echo 'QA 6: required fields are populated for reportable rows'
\ir 06_check_required_fields_not_null.sql

\echo 'QA 7: null profile by source system'
\ir 07_profile_nulls_by_source_system.sql

\echo 'QA 8: fact rowcount matches activity source rows'
\ir 08_check_fact_rowcount_matches_activity_sources.sql

\echo 'QA 9: emissions calculation math'
\ir 09_check_emissions_calculation_math.sql

\echo 'QA 10: factor reference uniqueness'
\ir 10_check_factor_reference_uniqueness.sql

\echo 'QA 11: reportability logic consistency'
\ir 11_check_reportability_logic.sql

\echo 'QA 12: control view counts reconcile to fact flags'
\ir 12_check_control_view_reconciliation.sql

\echo 'QA 13: QA summary'
\ir 13_qa_summary.sql

\echo 'QA 14: materiality threshold checks'
\ir 14_check_materiality_thresholds.sql

\echo 'QA 15: source owner certifications'
\ir 15_check_source_owner_certifications.sql

\echo 'QA 16: exception resolution status profile'
\ir 16_profile_exception_resolution_status.sql

\echo 'QA 17: period-over-period anomaly profile'
\ir 17_profile_period_over_period_anomalies.sql

\echo 'QA complete: update QA run history'
\ir 99_complete_qa_run.sql

\echo '============================================================'
\echo 'GHG SCOPE REPORTING QA CHECKS COMPLETE'
\echo '============================================================'