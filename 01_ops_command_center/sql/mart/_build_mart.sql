-- relative setup (resilient to future renames)
\pset pager off
\set ON_ERROR_STOP on

\cd 01_ops_command_center/sql/mart

\i core/dim_store.sql
\i sales/fact_sales_distributor_daily.sql
\i ops/fact_labor_daily.sql
\i ops/kpi_sales_per_labor_hour_daily.sql


-- absolute setup (for reference)

-- core dims first
-- \i 01_ops_command_center/sql/mart/core/dim_store.sql
-- \i .../dim_date.sql
-- \i .../dim_sku.sql

-- sales facts
-- \i 01_ops_command_center/sql/mart/sales/fact_sales_distributor_daily.sql

-- ops/hr facts
-- \i 01_ops_command_center/sql/mart/ops/fact_labor_daily.sql

-- finance facts
-- \i 01_ops_command_center/sql/mart/finance/fact_actuals_monthly.sql

-- KPIs last
-- \i 01_ops_command_center/sql/mart/ops/kpi_sales_per_labor_hour_daily.sql
