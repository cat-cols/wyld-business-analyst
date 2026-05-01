# Decision Engine - KPI Driver Tree

## Goal

Build a decision-support layer that turns trusted analytics marts into business recommendations, alert tables, opportunity tables, and executive-ready summaries.

This project does not create another raw ingestion pipeline. It consumes modeled, reconciled, and QA-checked outputs from earlier portfolio projects, especially Project 1's sales, inventory, labor, finance, KPI, and reconciliation marts.

## Business scenario

Leadership has access to trusted reporting tables, but they still need help answering:

- What changed?
- Why did it change?
- Where should we focus?
- What action should we take next?

The Decision Engine translates modeled facts into prioritized business actions.

## What this project demonstrates

- KPI driver tree design
- revenue and margin root-cause analysis
- store / SKU / channel performance flagging
- low-margin and inventory-risk alert logic
- opportunity identification
- executive decision summaries
- QA checks for decision outputs

## Upstream dependencies

Primary upstream objects are expected to come from Project 1 marts, including:

- `mart.fact_sales_daily`
- `mart.fact_inventory_snapshot_daily`
- `mart.fact_labor_daily`
- `mart.kpi_gross_margin_daily`
- `mart.kpi_sales_per_labor_hour_daily`
- `mart.kpi_instock_rate_daily`
- `mart.kpi_days_of_supply`
- `mart.recon_sales_to_gl_monthly`
- `mart.controls_missing_dim_joins`

Optional upstream inputs may include Project 3 forecast and variance outputs.

## Planned decision outputs

- `mart.decision_kpi_driver_tree`
- `mart.decision_revenue_variance_root_cause`
- `mart.alerts_low_margin`
- `mart.alerts_inventory_risk`
- `mart.opportunity_high_growth_skus`
- `mart.store_performance_flags`
- `mart.executive_decision_summary`

## Project philosophy

Earlier projects prove that the data can be cleaned, standardized, reconciled, and modeled.

This project proves that trusted data can be converted into business decisions.