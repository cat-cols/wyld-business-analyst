# Relationships Map — Project 1 (Ops Command Center)

## Goal
Document the intended one-to-many relationships from conformed dimensions to fact and KPI tables.

## Primary Relationships

### Date Relationships
- `mart.dim_date.date` -> `mart.fact_sales_distributor_daily.sale_date`
- `mart.dim_date.date` -> `mart.fact_sales_pos_daily.sale_date`
- `mart.dim_date.date` -> `mart.fact_labor_daily.work_date`
- `mart.dim_date.date` -> `mart.fact_inventory_snapshot_daily.snapshot_date`
- `mart.dim_date.date` -> `mart.kpi_gross_margin_daily.sale_date`
- `mart.dim_date.date` -> `mart.kpi_sales_per_labor_hour_daily.kpi_date`
- `mart.dim_date.date` -> `mart.kpi_instock_rate_daily.snapshot_date`
- `mart.dim_date.date` -> `mart.kpi_days_of_supply.snapshot_date`

### Store Relationships
- `mart.dim_store.store_code` -> `mart.fact_sales_distributor_daily.store_code`
- `mart.dim_store.store_code` -> `mart.fact_sales_pos_daily.store_code`
- `mart.dim_store.store_code` -> `mart.fact_labor_daily.store_code`
- `mart.dim_store.store_code` -> `mart.fact_inventory_snapshot_daily.store_code`
- `mart.dim_store.store_code` -> `mart.kpi_gross_margin_daily.store_code`
- `mart.dim_store.store_code` -> `mart.kpi_sales_per_labor_hour_daily.store_code`
- `mart.dim_store.store_code` -> `mart.kpi_instock_rate_daily.store_code`
- `mart.dim_store.store_code` -> `mart.kpi_days_of_supply.store_code`

### SKU Relationships
- `mart.dim_sku.sku` -> `mart.fact_sales_distributor_daily.sku`
- `mart.dim_sku.sku` -> `mart.fact_sales_pos_daily.sku`
- `mart.dim_sku.sku` -> `mart.fact_inventory_snapshot_daily.sku`
- `mart.dim_sku.sku` -> `mart.kpi_days_of_supply.sku`

### Channel Relationships
- `mart.dim_channel.channel` -> `mart.fact_sales_distributor_daily.channel`

## Notes on KPI Tables
KPI marts are intentionally treated as report-ready facts:
- `mart.kpi_gross_margin_daily`
- `mart.kpi_sales_per_labor_hour_daily`
- `mart.kpi_instock_rate_daily`
- `mart.kpi_days_of_supply`

These tables reduce BI-layer complexity by pushing business logic into SQL.

## Reconciliation Objects
The following objects are best treated as diagnostics / trust pages rather than core dimensional facts:
- `mart.recon_sales_to_gl_monthly`
- `mart.recon_sales_distributor_vs_pos`
- `mart.controls_missing_dim_joins`
- `mart.controls_freshness`

## Validation Rule
Relationships should only be used where the grain remains stable and row multiplication risk is understood. Fact uniqueness should be checked against:
- sales distributor: `sale_date + store_code + sku + channel`
- sales POS: `sale_date + store_code + sku`
- labor: `work_date + store_code`
- inventory snapshot: `snapshot_date + store_code + sku`