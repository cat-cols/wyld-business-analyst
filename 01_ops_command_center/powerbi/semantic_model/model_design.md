# Model Design — Project 1 (Ops Command Center)

<!-- Facts: fact_sales, fact_inventory, fact_labor
Dims: dim_date, dim_product, dim_location, dim_channel, dim_employee_group -->

## Purpose
This semantic model is intended to support business-facing reporting across sales, inventory, labor, and finance-style KPIs for the Ops Command Center.

The model is designed to answer questions such as:
- What are monthly net sales, gross sales, and gross margin?
- How productive are stores based on sales per labor hour?
- How healthy is inventory based on in-stock rate and days of supply?
- Where do reconciliation issues exist between operational and finance-style totals?

## Design Approach
The semantic layer is built on mart-layer views that already enforce stable grains and QA expectations. The goal is to keep the BI layer thin, with business logic pushed into SQL where possible and measures documented clearly for downstream reporting.

## Core Dimensions
- **mart.dim_date**
  - Grain: 1 row per calendar date
  - Primary reporting date dimension
- **mart.dim_store**
  - Grain: 1 row per store_code
  - Used across sales, labor, and inventory
- **mart.dim_sku**
  - Grain: 1 row per sku
  - Used across sales and inventory
- **mart.dim_channel**
  - Grain: 1 row per channel
  - Used primarily for distributor sales slicing

## Core Fact / KPI Tables
- **mart.fact_sales_distributor_daily**
  - Grain: sale_date + store_code + sku + channel
  - Core sales fact for distributor-driven reporting
- **mart.fact_sales_pos_daily**
  - Grain: sale_date + store_code + sku
  - POS comparison / reconciliation support
- **mart.fact_labor_daily**
  - Grain: work_date + store_code
  - Labor totals for productivity analysis
- **mart.fact_inventory_snapshot_daily**
  - Grain: snapshot_date + store_code + sku
  - Inventory snapshot fact
- **mart.kpi_gross_margin_daily**
  - Grain: sale_date + store_code
  - Finance-style KPI based on sales fact
- **mart.kpi_sales_per_labor_hour_daily**
  - Grain: kpi_date + store_code
  - Cross-functional KPI mart
- **mart.kpi_instock_rate_daily**
  - Grain: snapshot_date + store_code
  - Inventory health KPI mart
- **mart.kpi_days_of_supply**
  - Grain: snapshot_date + store_code + sku
  - Inventory coverage KPI mart
- **mart.fact_actuals_monthly**
  - Grain: period_month + kpi_category
  - Finance-style monthly actuals used for reconciliation
- **mart.recon_sales_to_gl_monthly**
  - Grain: period_month + metric
  - Monthly reconciliation reference
- **mart.recon_sales_distributor_vs_pos**
  - Grain: sale_date + store_code
  - Daily operational reconciliation reference

## Modeling Principles
- Prefer mart-layer facts and KPI marts over raw/staging sources.
- Keep grains explicit and stable.
- Use dimensions for slicing/filtering and facts for additive measures.
- Use SQL reference queries to validate semantic-model outputs.
- Treat reconciliation and data-trust outputs as first-class reporting objects.

## Known Constraints
- Finance actuals are currently simulated independently from operational truth, so sales-to-GL reconciliation is useful but not yet fully aligned.
- Semantic-model documentation is further along than the actual Power BI implementation because the project is being developed on Mac.