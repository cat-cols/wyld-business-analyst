-- 01_ops_command_center/sql/_qa/mart/_run_mart.sql

-- Run MART QA checks

\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '=============================='
\echo ' QA: MART ONLY (hard-fail)'
\echo '=============================='
\echo ''

\ir qa_mart_dims.sql

\echo ''
\echo '✅ MART QA COMPLETE'