# Executive Walkthrough — Operations Command Center (Project 1)

## Table of Contents
- [Executive Walkthrough — Operations Command Center (Project 1)](#executive-walkthrough--operations-command-center-project-1)
  - [Table of Contents](#table-of-contents)
  - [1. Business Problem](#1-business-problem)
  - [2. Objective](#2-objective)
  - [3. Simulated Source Systems](#3-simulated-source-systems)
    - [Sales sources](#sales-sources)
    - [Operations / inventory sources](#operations--inventory-sources)
    - [People / labor sources](#people--labor-sources)
    - [Finance sources](#finance-sources)
  - [4. Data Flow: Raw → Stg → Int → Mart](#4-data-flow-raw--stg--int--mart)
    - [Raw](#raw)
    - [Stg](#stg)
    - [Int](#int)
    - [Mart](#mart)
  - [5. QA and Reconciliation Controls](#5-qa-and-reconciliation-controls)
  - [6. Semantic Model Plan](#6-semantic-model-plan)
  - [7. Power BI Page Architecture](#7-power-bi-page-architecture)
    - [Planned page structure](#planned-page-structure)
  - [8. Decisions Supported](#8-decisions-supported)
  - [9. KPI Snapshot](#9-kpi-snapshot)
  - [10. Sales \& Margin Story](#10-sales--margin-story)
  - [11. Ops \& Inventory Story](#11-ops--inventory-story)
  - [12. People \& Productivity Story](#12-people--productivity-story)
  - [13. Reconciliation \& Data Health](#13-reconciliation--data-health)
  - [14. Recommended Actions](#14-recommended-actions)
  - [15. Caveats](#15-caveats)

---

## 1. Business Problem
Operational reporting often breaks down when sales, inventory, labor, and finance data come from different systems with different grains, naming conventions, refresh cadences, and data quality problems.

This project simulates that real-world mess and then models it into a reporting structure that can support executive and operational decision-making. The goal is not just to build tables. The goal is to create a command-center-style analytics layer that is:

- trustworthy,
- business-readable,
- reconciliation-aware,
- and usable in a BI tool without requiring users to interpret raw system chaos.

The intended use case is a business-facing operations command center where leaders can evaluate sales performance, margin, staffing productivity, inventory health, and data trust signals from one reporting surface.

## 2. Objective
Build an executive-facing Ops Command Center that integrates **sales, inventory, labor, and finance-style actuals** into one reporting surface.

This project is meant to prove that the repo can do more than produce tables. It should:

- absorb messy cross-functional extracts,
- standardize them into typed staging models,
- align them to shared business keys,
- surface QA and reconciliation outputs,
- and support Power BI reporting from trusted mart-layer objects.

## 3. Simulated Source Systems
Project 1 simulates multi-source operational reporting by generating source-style drops across business domains.

### Sales sources
- distributor sales summary extracts,
- POS transaction extracts,
- POS SQLite exports.

### Operations / inventory sources
- ERP inventory snapshot extracts,
- WMS shipment extracts.

### People / labor sources
- timeclock punch exports,
- payroll-style labor summaries.

### Finance sources
- monthly actuals summary extracts,
- GL-style detail exports.

These sources are intentionally uneven. They arrive on different cadences, use different field conventions, and do not start in a clean, analytics-ready form. That design is deliberate: the project is supposed to demonstrate cleanup, conformance, and trust-building, not just final reporting.

## 4. Data Flow: Raw → Stg → Int → Mart
The project follows a layered modeling pattern designed to separate ingestion, cleanup, conformance, and reporting.

### Raw
The raw layer represents landed source extracts as received from simulated upstream systems. This is where the project preserves source-level structure before standardization.

Purpose:
- retain source realism,
- preserve landed grain,
- support traceability back to incoming files.

### Stg
The staging layer standardizes source columns into typed, predictable structures.

Purpose:
- clean column names,
- cast fields to usable types,
- normalize dates, identifiers, and flags,
- reduce source-specific irregularities.

### Int
The intermediate layer performs cross-source alignment and business-rule shaping.

Purpose:
- align business keys,
- reconcile alternative source structures,
- produce conformed logic for downstream marts,
- bridge source-specific quirks into reusable modeled forms.

### Mart
The mart layer is the reporting and BI consumption layer.

Purpose:
- expose stable fact tables and dimensions,
- define KPI-ready grains,
- support semantic-model relationships,
- surface control and reconciliation outputs alongside business facts.

This layered structure is the backbone of the project. It allows raw system mess to be transformed into something Power BI can consume without dragging raw-system weirdness into every visual.

## 5. QA and Reconciliation Controls
A major goal of the project is to show that reporting outputs are not simply produced, but evaluated.

Key control patterns in the repo include:

- rowcount and object health checks,
- freshness checks,
- missing-dimension join checks,
- source-to-model reconciliation checks,
- modeled validation queries for semantic-model review.

Important trust objects include:

- `validation.reconciliation_checks`
- `mart.controls_rowcounts_daily`
- `mart.controls_missing_dim_joins`
- `mart.recon_sales_distributor_vs_pos`
- `mart.recon_sales_to_gl_monthly`

These controls help answer questions such as:

- Did the modeled object refresh with the expected data?
- Are facts joining correctly to dimensions?
- Do alternative sales views tell a consistent story?
- Does modeled sales align to finance-style actuals within tolerance?
- Which failures are expected because the dataset is simulated rather than live?

This control layer is what makes the project feel like analytics engineering rather than dashboard decoration with extra steps.

## 6. Semantic Model Plan
The Power BI semantic layer is designed to sit on top of mart-layer objects rather than raw or staging tables.

The intended model emphasizes:

- fact tables at stable grains,
- shared dimensions across sales, inventory, and labor,
- reusable KPI measures,
- and naming conventions that make the model understandable to report consumers.

Core intended facts and KPI-ready objects include:

- `mart.fact_sales_distributor_daily`
- `mart.fact_sales_pos_daily`
- `mart.fact_sales_daily`
- `mart.fact_inventory_snapshot_daily`
- `mart.fact_shipments_daily`
- `mart.fact_labor_daily`
- `mart.fact_labor_daily_employee`
- `mart.kpi_gross_margin_daily`
- `mart.kpi_instock_rate_daily`
- `mart.kpi_days_of_supply`
- `mart.kpi_sales_per_labor_hour_daily`

The semantic model should allow slicing by common business dimensions such as:

- date,
- store,
- SKU,
- channel,
- employee grouping where relevant.

The intent is to keep business logic centralized and reusable so report visuals consume governed objects rather than re-creating calculations ad hoc inside the BI layer.

## 7. Power BI Page Architecture
The first version of the report is intended to follow a command-center layout rather than a loose collection of visuals.

### Planned page structure
1. **Executive Overview**  
   High-level KPI summary across sales, margin, labor, inventory, and trust signals.

2. **Sales & Margin**  
   Trend, mix, discount impact, and gross margin movement.

3. **Inventory & Distribution Health**  
   In-stock performance, supply risk, and shipment / distribution coverage.

4. **Labor & Productivity**  
   Labor hours, labor cost, and sales-per-labor-hour analysis.

5. **Reconciliation & Data Health**  
   Pass/fail counts, major variances, freshness, and known expected exceptions.

The point of this structure is to let users move from headline KPIs to operational explanation without needing to understand the underlying SQL.

## 8. Decisions Supported
The reporting layer is meant to support practical operating questions rather than abstract metric tourism.

Examples include:

- Which stores, SKUs, or channels are driving the strongest net sales?
- Where are discounts reducing realized revenue?
- Where is inventory at risk of being too thin to support demand?
- Which stores appear under- or over-staffed relative to sales volume?
- Are labor hours rising faster than revenue?
- Are inventory and shipment patterns consistent with what sales performance suggests?
- Are the reported metrics trustworthy enough to use for decision-making today?

This is important because the value of the project is not merely that it models data. The value is that it creates a reporting layer that can inform action.

## 9. KPI Snapshot
Primary KPI families for the first report release:

- **Sales:** Net Sales, Gross Sales, Units Sold, Orders, Average Selling Price
- **Profitability:** COGS, Gross Margin $, Gross Margin %
- **Labor / productivity:** Labor Hours, Labor Cost, Sales per Labor Hour
- **Inventory health:** In-Stock Rate, Days of Supply, On-Hand Units
- **Trust / controls:** Missing-dim joins, freshness, distributor-vs-POS comparison, sales-vs-GL comparison

Detailed KPI definitions are documented separately in the metric dictionary and metrics registry.

## 10. Sales & Margin Story
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

This section is intended to combine top-line sales performance with explainability. It should not just show revenue movement. It should help explain *why* revenue or margin changed.

## 11. Ops & Inventory Story
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

This section is intended to connect availability, movement, and coverage. It should help distinguish normal inventory variation from operational risk.

## 12. People & Productivity Story
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

This section is meant to show whether labor deployment appears efficient relative to operational performance, not just whether labor cost is increasing or decreasing.

## 13. Reconciliation & Data Health
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

This page should make it easy to understand whether a data issue is:
- a modeling problem,
- a source discrepancy,
- a simulated-data limitation,
- or an expected edge case.

## 14. Recommended Actions
Near-term actions for the repo:

1. finalize the business-facing doc set (`source_register`, `metrics_registry`, `reconciliation_log`),
2. tighten README and overall project packaging,
3. align simulated finance actuals more closely to operational truth,
4. resolve or retire remaining INT and MART stub files,
5. build the first Power BI report page using the already-defined mart and KPI objects.

## 15. Caveats
- Finance actuals are currently simulated independently from operational truth, so monthly sales-to-GL reconciliation is expected to show known deltas.
- Static simulated data can make freshness checks look worse than a live operating environment.
- Some semantic-model planning docs are ahead of the actual Power BI implementation because the project is being developed on Mac.
- Several INT and MART stub files still exist and should either be implemented or retired so the repo looks intentional rather than haunted.
- This project is designed as a portfolio case study, so the focus is on demonstrating realistic analytics engineering patterns rather than reproducing any company’s exact internal schema or business process.

---