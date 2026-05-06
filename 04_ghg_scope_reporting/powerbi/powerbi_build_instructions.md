# Power BI Build Instructions — GHG Scope Reporting

## Purpose

This document describes how to implement the Project 4 semantic model in Power BI when Power BI Desktop or the Power BI service is available.

Power BI Desktop is not available natively on macOS, so this repo includes the SQL mart layer, CSV exports, semantic model blueprint, DAX catalog, and report page architecture.

---

## Option A — Build from CSV Exports

1. Open Power BI Desktop on Windows or a Windows VM.
2. Select **Get Data → Text/CSV**.
3. Load files from:

```text
04_ghg_scope_reporting/bi_exports/
```

4. Import:

* `fact_emissions.csv`
* `kpi_emissions_intensity_monthly.csv`
* control view CSVs

5. Create dimensions from `fact_emissions` or use Power Query reference tables.
6. Create relationships listed in `semantic_model_blueprint.md`.
7. Add DAX measures from `dax_measure_catalog.md`.
8. Build report pages from `report_page_architecture.md`.

---

## Option B — Build from PostgreSQL

1. Open Power BI Desktop.
2. Select **Get Data → PostgreSQL database**.
3. Connect to local or hosted Postgres database.
4. Load mart views:

* `mart.fact_emissions`
* `mart.kpi_emissions_intensity_monthly`
* `mart.controls_missing_factor_joins`
* `mart.controls_negative_activity`
* `mart.controls_missing_dim_joins`
* `mart.controls_unknown_activity_type`

5. Build relationships and DAX measures.

---

## Option C — Power BI Service Browser Workflow

If a semantic model already exists or can be created in the Power BI service, reports can be authored in the browser from that semantic model.

Use this repo’s artifacts as the implementation guide:

* semantic model design
* DAX measure catalog
* page architecture
* exported mart data
* QA/control definitions

---

## Validation Checklist

Before publishing:

* KPI totals match SQL totals
* reportable rows match QA summary
* non-reportable rows appear only on QA/control pages
* missing factor joins reconcile to control view
* unknown activity rows reconcile to control view
* date filters work as expected
* no many-to-many relationships were introduced
* measure definitions are documented