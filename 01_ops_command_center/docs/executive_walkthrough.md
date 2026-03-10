# Executive Walkthrough — Operations Command Center (Project 1)

## Table of Contents
- [Executive Walkthrough — Operations Command Center (Project 1)](#executive-walkthrough--operations-command-center-project-1)
  - [Table of Contents](#table-of-contents)
- [Executive Walkthrough — Operations Command Center (Project 1)](#executive-walkthrough--operations-command-center-project-1-1)
  - [1. Objective](#1-objective)
  - [2. KPI Snapshot](#2-kpi-snapshot)
  - [3. Sales \& Margin Story](#3-sales--margin-story)
  - [4. Ops \& Inventory Story](#4-ops--inventory-story)
  - [5. People \& Productivity Story](#5-people--productivity-story)
  - [6. Reconciliation \& Data Health](#6-reconciliation--data-health)
  - [7. Recommended Actions](#7-recommended-actions)
  - [8. Caveats](#8-caveats)

---

# Executive Walkthrough — Operations Command Center (Project 1)

## 1. Objective
Build an executive-facing Ops Command Center that integrates **sales, inventory, labor, and finance-style actuals** into one reporting surface.

This project is meant to prove that the repo can do more than produce tables. It should:
- absorb messy cross-functional extracts,
- standardize them into typed staging models,
- align them to shared business keys,
- surface QA and reconciliation outputs,
- and support Power BI reporting from trusted mart-layer objects.

## 2. KPI Snapshot
Primary KPI families for the first report release:
- **Sales:** Net Sales, Gross Sales, Units Sold, Orders, Average Selling Price
- **Profitability:** COGS, Gross Margin $, Gross Margin %
- **Labor / productivity:** Labor Hours, Labor Cost, Sales per Labor Hour
- **Inventory health:** In-Stock Rate, Days of Supply, On-Hand Units
- **Trust / controls:** Missing-dim joins, freshness, distributor-vs-POS comparison, sales-vs-GL comparison

## 3. Sales & Margin Story
The sales layer is anchored on:
- `mart.fact_sales_distributor_daily`
- `mart.fact_sales_pos_daily`
- `mart.fact_sales_daily`
- `mart.kpi_gross_margin_daily`

What this section should answer:
- Where are net sales strongest by day, store, SKU, and channel?
- How much of gross sales is being lost to discounts?
- What does gross margin look like over time?
- Where do distributor-facing and POS-facing views disagree?

## 4. Ops & Inventory Story
The inventory / operations layer is anchored on:
- `mart.fact_inventory_snapshot_daily`
- `mart.fact_shipments_daily`
- `mart.fact_sku_distribution_status_daily`
- `mart.kpi_instock_rate_daily`
- `mart.kpi_days_of_supply`

What this section should answer:
- Are stores in stock on the right SKUs?
- Where is inventory thin or at risk?
- Which stores or SKUs show distribution coverage gaps?
- Are shipments and inventory snapshots telling a coherent story?

## 5. People & Productivity Story
The people / labor layer is anchored on:
- `mart.fact_labor_daily`
- `mart.fact_labor_daily_employee`
- `mart.dim_employee`
- `mart.kpi_sales_per_labor_hour_daily`

What this section should answer:
- How many labor hours are being used per day/store?
- What is the labor-cost / productivity trend over time?
- Which stores appear over- or under-staffed relative to sales?
- Are overtime or staffing shifts explaining KPI movement?

## 6. Reconciliation & Data Health
This page is what separates a dashboard from a disciplined analytics project.

Control / trust objects to surface:
- `validation.reconciliation_checks`
- `mart.controls_rowcounts_daily`
- `mart.controls_missing_dim_joins`
- `mart.recon_sales_distributor_vs_pos`
- `mart.recon_sales_to_gl_monthly`

What to show:
- latest pass / fail / warning counts,
- largest variances,
- freshness state by object,
- known expected exceptions for simulated static data.

## 7. Recommended Actions
Near-term actions for the repo:
1. finalize the business-facing doc set (`source_register`, `metrics_registry`, `reconciliation_log`),
2. tighten README / project packaging,
3. align simulated finance actuals more closely to operational truth,
4. build the first Power BI report page using the already-defined mart and KPI objects.

## 8. Caveats
- Finance actuals are currently simulated independently from operational truth, so monthly sales-to-GL reconciliation is expected to show known deltas.
- Static simulated data can make freshness checks look worse than a live operating environment.
- Some semantic-model planning docs are ahead of the actual Power BI implementation because the project is being developed on Mac.
- Several INT and MART stub files still exist and should either be implemented or retired so the repo looks intentional rather than haunted.
