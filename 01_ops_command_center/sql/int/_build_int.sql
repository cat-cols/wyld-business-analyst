-- 01_ops_command_center/sql/int/_build_int.sql
-- Build INT layer in dependency order (core → sales → hr → ops)
-- Uses \ir so file paths are relative to this script's directory.

\pset pager off
\set ON_ERROR_STOP on

\echo ''
\echo '=============================='
\echo ' BUILD: INT'
\echo '=============================='
\echo ''

-- ----------------------------
-- 1) CORE (shared entities)
-- ----------------------------
\echo ''
\echo '--- INT: core ---'
\ir core/int_dispensary_latest.sql
\ir core/int_account_status_current.sql
\ir core/int_dispensary_standardized.sql
\ir core/int_sku_distribution_status_dedup.sql

-- ----------------------------
-- 2) SALES
-- ----------------------------
\echo ''
\echo '--- INT: sales ---'
\ir sales/int_sales_distributor_dedup.sql
\ir sales/int_pos_dedup.sql
\ir sales/int_pos_daily.sql
-- Optional alternative (leave off unless you intentionally want raw->int bypass):
-- \ir sales/int_pos_dedup_from_raw.sql

-- ----------------------------
-- 3) HR
-- ----------------------------
\echo ''
\echo '--- INT: hr ---'
\ir hr/int_timeclock_punches_latest.sql
\ir hr/int_labor_daily_employee.sql
\ir hr/int_labor_daily.sql

-- ----------------------------
-- 4) OPS
-- ----------------------------
\echo ''
\echo '--- INT: ops ---'
\ir ops/int_inventory_snapshot_dedup.sql
\ir ops/int_coverage_conformed.sql

-- ----------------------------
-- 5) COMMENT-ONLY STUBS (do not run until implemented)
-- ----------------------------
-- \ir hr/int_labor_conformed.sql
-- \ir ops/int_inventory_conformed.sql
-- \ir sales/int_sales_conformed.sql

\echo ''
\echo '✅ BUILD INT COMPLETE'
\echo ''