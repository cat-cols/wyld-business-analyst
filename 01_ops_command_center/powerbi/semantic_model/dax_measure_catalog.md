# DAX Measure Catalog — Project 1 (Ops Command Center)
<!-- Track measure name, business definition, DAX, format, and page usage. -->

## Purpose
Track report-layer measures, business definitions, SQL reference sources, and implementation status.

## Status Key
- **SQL validated** = logic already exists in mart / validation SQL
- **Planned in semantic model** = intended for Power BI layer, not yet implemented in PBIX
- **Known caveat** = measure is valid but subject to current simulation limitations

| Measure Name | Business Definition | SQL Reference | Intended Page | Status | Notes |
|---|---|---|---|---|---|
| Net Sales | Sum of distributor net sales | `mart.fact_sales_distributor_daily`, `semantic_model_test_queries.sql` | Executive Overview, Sales & Margin | SQL validated | Core executive metric |
| Gross Sales | Sum of distributor gross sales | `mart.fact_sales_distributor_daily`, `semantic_model_test_queries.sql` | Executive Overview, Sales & Margin | SQL validated | Currently does not align to finance actuals in January 2025 |
| Discount Amount | Gross sales minus net sales / explicit discount amount | `mart.fact_sales_distributor_daily` | Sales & Margin | SQL validated | Useful for pricing/discount storytelling |
| Gross Margin $ | Net sales minus COGS | `mart.kpi_gross_margin_daily` | Sales & Margin | SQL validated | Finance-style KPI |
| Gross Margin % | Gross margin divided by net sales | `mart.kpi_gross_margin_daily` | Sales & Margin | SQL validated | Safe-divide required |
| Labor Hours | Sum of hours worked | `mart.fact_labor_daily`, `semantic_model_test_queries.sql` | People & Productivity | SQL validated | Core labor fact |
| Net Sales per Labor Hour | Net sales divided by labor hours | `mart.kpi_sales_per_labor_hour_daily` | People & Productivity, Executive Overview | SQL validated | Strong cross-functional KPI |
| Gross Sales per Labor Hour | Gross sales divided by labor hours | `mart.kpi_sales_per_labor_hour_daily` | People & Productivity | SQL validated | Cross-functional KPI |
| In-Stock Rate (Inventory Universe) | In-stock SKUs divided by total SKUs in inventory | `mart.kpi_instock_rate_daily` | Ops & Inventory | SQL validated | Daily operational KPI |
| In-Stock Rate (Carried Universe) | In-stock carried SKUs divided by total carried SKUs | `mart.kpi_instock_rate_daily` | Ops & Inventory | SQL validated | Better for assortment-aware analysis |
| Avg Days of Supply | Average days of supply across SKU-store rows | `mart.kpi_days_of_supply`, `semantic_model_test_queries.sql` | Ops & Inventory | SQL validated | Use summary output, not raw SKU dump |
| ROI (Gross Margin over Labor) | Gross margin divided by labor cost | `mart.kpi_roi_monthly` | Finance / Strategy | SQL validated | Monthly finance-style KPI |
| ROI (Contribution over Labor) | Contribution margin divided by labor cost | `mart.kpi_roi_monthly` | Finance / Strategy | SQL validated | Monthly finance-style KPI |
| Breakeven Net Sales | Net sales required to cover labor cost | `mart.kpi_breakeven_monthly` | Finance / Strategy | SQL validated | Monthly approximation |
| Sales vs GL Delta % | Percent difference between mart sales and finance actuals | `mart.recon_sales_to_gl_monthly` | Reconciliation / Data Trust | SQL validated | Known January 2025 caveat |
| Distributor vs POS Delta % | Percent difference between distributor and POS net sales | `mart.recon_sales_distributor_vs_pos` | Reconciliation / Data Trust | SQL validated | Daily operational trust metric |

## Notes
- Most business logic is intentionally pushed into SQL marts and KPI views.
- The semantic model should stay thin and primarily expose validated business measures.
- Where possible, report values should be checked against `semantic_model_test_queries.sql`.