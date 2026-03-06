-- 01_ops_command_center/sql/mart/_build_mart.sql
-- Build MART layer in dependency order (dims → facts → kpis → controls → recon).
-- Uses \ir so paths are relative to this script's directory.

\pset pager off
\set ON_ERROR_STOP on

\echo ''
\echo '=============================='
\echo ' BUILD: MART'
\echo '=============================='
\echo ''

-- ----------------------------
-- 1) Core dimensions (spine)
-- ----------------------------
\echo ''
\echo '--- MART: core dims ---'
\ir core/dim_date.sql
\ir core/dim_store.sql
\ir core/dim_sku.sql

-- Optional / currently stubby in your repo:
-- \ir core/_dim_channel.sql
-- \ir core/_dim_state.sql

-- Optional controls (keep commented until verified correct):
-- NOTE: core/controls_freshness.sql is currently incorrect in your repo (duplicates dim_sku)
-- \ir core/controls_freshness.sql

-- ----------------------------
-- 2) Facts (stable grains)
-- ----------------------------
\echo ''
\echo '--- MART: sales facts ---'
\ir sales/fact_sales_distributor_daily.sql
\ir sales/fact_sales_pos_daily.sql
\ir sales/fact_sales_daily.sql
\ir sales/agg_sales_store_daily.sql
\ir sales/fact_distribution_coverage.sql

\echo ''
\echo '--- MART: ops facts ---'
\ir ops/fact_inventory_snapshot_daily.sql
\ir ops/fact_shipments_daily.sql
\ir ops/fact_sku_distribution_status_daily.sql

\echo ''
\echo '--- MART: hr facts + dims ---'
\ir hr/fact_labor_daily.sql
\ir hr/fact_labor_daily_employee.sql
\ir hr/dim_employee.sql

-- NOTE: hr/fact_timeclock_punches.sql is currently 0 bytes in your repo, so do not include yet:
-- \ir hr/fact_timeclock_punches.sql

\echo ''
\echo '--- MART: finance facts ---'
\ir finance/fact_actuals_monthly.sql

-- ----------------------------
-- 3) KPIs
-- ----------------------------
\echo ''
\echo '--- MART: KPIs ---'
-- Canonical KPI definition (do not use ops/_kpi_sales_per_labor_hour_daily.sql; it is 0 bytes)
\ir sales/_kpi_sales_per_labor_hour_daily.sql

\ir ops/kpi_instock_rate_daily.sql
\ir ops/kpi_days_of_supply.sql

\ir finance/kpi_gross_margin_daily.sql
\ir finance/roi_monthly.sql
\ir finance/breakeven_monthly.sql

-- ----------------------------
-- 4) Controls (guardrails)
-- ----------------------------
\echo ''
\echo '--- MART: controls ---'
\ir controls/controls_rowcounts_daily.sql
\ir controls/controls_missing_dim_joins.sql
\ir core/controls_dim_join_coverage.sql

-- Optional: currently comment-only stub in your repo
-- \ir controls/_mart_reconciliation_controls.sql

-- ----------------------------
-- 5) Recon (trust but verify)
-- ----------------------------
\echo ''
\echo '--- MART: recon ---'
\ir recon/recon_sales_distributor_vs_pos.sql
\ir finance/recon_sales_to_gl_monthly.sql

-- ----------------------------
-- 6) Anomaly flags (nice-to-have)
-- ----------------------------
\echo ''
\echo '--- MART: anomaly flags ---'
\ir mart_anomaly_flags.sql

\echo ''
\echo '✅ BUILD MART COMPLETE'
\echo ''