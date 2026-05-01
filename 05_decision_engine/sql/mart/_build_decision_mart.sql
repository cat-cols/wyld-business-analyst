-- ============================================================
-- Project 5: Decision Engine
-- Build: Decision Mart Objects
--
-- Purpose:
--   Runs all SQL files needed to build the Project 5 decision
--   layer marts.
-- ============================================================

\echo ''
\echo '============================================================'
\echo 'PROJECT 5: DECISION TREE MART BUILD'
\echo '============================================================'

\echo ''
\echo 'Building mart.decision_kpi_driver_tree...'
\ir decision_kpi_driver_tree.sql

\echo ''
\echo 'Building mart.decision_revenue_variance_root_cause...'
\ir decision_revenue_variance_root_cause.sql

\echo ''
\echo 'Project 5: decision tree mart build complete.'