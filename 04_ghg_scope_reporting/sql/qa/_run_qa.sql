\echo '============================================================'
\echo 'PROJECT 4 QA START'
\echo 'GHG Scope Reporting Validation Checks'
\echo '============================================================'

\echo 'QA 1: raw rowcounts'
\ir 01_check_raw_rowcounts.sql

\echo 'QA 2: fact_emissions activity_id uniqueness'
\ir 02_check_fact_emissions_unique_activity_id.sql

\echo 'QA 3: reportable emissions rows have calculated emissions'
\ir 03_check_reportable_emissions_not_null.sql

\echo 'QA 4: clean rows have factor joins'
\ir 04_check_clean_rows_have_factor.sql

\echo 'QA 5: QA summary'
\ir 05_qa_summary.sql

\echo 'QA 6: duplicate source records'
\ir qa_duplicate_source_records.sql

\echo '============================================================'
\echo 'PROJECT 4 QA COMPLETE'
\echo '============================================================'