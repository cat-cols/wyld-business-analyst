-- 01_ops_command_center/sql/_qa/_run_qa.sql
--

-- Run all QA checks

\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '=============================='
\echo ' QA SUITE: int + mart + recon'
\echo '=============================='
\echo ''

\echo '--- QA: INT ---'
\ir int/qa_int.sql
\ir int/qa_int_truth_uniqueness.sql
\echo ''

\echo '--- QA: MART ---'
\ir mart/qa_mart.sql

\echo ''
\echo '--- QA: RECON ---'
\ir recon/qa_recon.sql

\echo ''
\echo '✅ QA SUITE COMPLETE'