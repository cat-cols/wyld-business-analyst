# Wyld Business Analyst SQL Pack

Starter SQL query pack tailored for a Wyld-style cannabis business analyst workflow.

## Files
- 01_kpi_exec_summary.sql
- 02_product_mix.sql
- 03_price_pack_architecture.sql
- 04_promo_performance.sql
- 05_distribution_ros.sql
- 06_inventory_health.sql
- 07_sales_labor_productivity.sql
- 08_account_concentration.sql
- 09_account_retention.sql
- 10_price_volume_mix_decomp.sql
- 11_forecast_accuracy.sql (requires fact_forecast)
- 12_data_quality_checks.sql

## Notes
- PostgreSQL-style syntax.
- Rename columns/types as needed for your warehouse.
- Most queries filter dim_product.brand_name = ''Wyld''.

---

```
│  │  ├─ staging_sql_template.sql
│  │  ├─ conformance_sql_template.sql
│  │  ├─ mart_sql_template.sql
│  │  ├─ validation_checks_template.sql
│  │  └─ variance_decomposition_patterns.sql