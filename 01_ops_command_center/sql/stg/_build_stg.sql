\pset pager off

\echo ''
\echo '=============================='
\echo ' BUILD: STG'
\echo '=============================='
\echo ''

\i 01_ops_command_center/sql/stg/00_create_schemas.sql

\echo ''
\echo '--- STG ---'

\i 01_ops_command_center/sql/stg/stg_account_status.sql
\i 01_ops_command_center/sql/stg/stg_dispensary_master.sql
\i 01_ops_command_center/sql/stg/stg_sku_distribution_status.sql
\i 01_ops_command_center/sql/stg/stg_sales_distributor.sql
\i 01_ops_command_center/sql/stg/stg_pos_transactions.sql
\i 01_ops_command_center/sql/stg/stg_inventory_erp.sql
\i 01_ops_command_center/sql/stg/stg_wms_shipments.sql
\i 01_ops_command_center/sql/stg/stg_timeclock_punches.sql
\i 01_ops_command_center/sql/stg/stg_labor_payroll.sql
\i 01_ops_command_center/sql/stg/stg_finance_actuals.sql

\echo ''
\echo '✅ BUILD STG COMPLETE'
\echo ''