\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '=============================='
\echo ' DEBUG SUITE: INT + MART (triage)'
\echo '=============================='
\echo ''

\echo '--- DEBUG: INT ---'
\ir int/debug_duplicates.sql

\echo ''
\echo '--- DEBUG: MART ---'
\ir mart/debug_mart_dims.sql

\echo ''
\echo '🧰 DEBUG SUITE COMPLETE'