# Semantic Model Validation — Project 1 (Ops Command Center)

<!-- > List SQL-vs-Power BI validation tests and pass/fail status.
**Validation approach**
* Semantic-model outputs should tie to `sql/validation/semantic_model_test_queries.sql`
* KPI cards and trend visuals should be validated against SQL reference totals before report signoff -->

## Purpose
This file documents how report-layer outputs should be validated against SQL source-of-truth queries and reconciliation controls.

## Validation Assets

### 1. Semantic Model Reference Queries
File:
- `01_ops_command_center/sql/validation/semantic_model_test_queries.sql`

Current coverage includes:
- monthly sales reference
- monthly gross margin reference
- monthly labor reference
- monthly sales per labor hour
- daily in-stock rate
- daily days-of-supply summary
- monthly sales vs GL reference
- distributor vs POS reference
- fact grain uniqueness sanity
- missing dimension join reference

### 2. Reconciliation / Control Surface
File:
- `01_ops_command_center/sql/validation/reconciliation_checks.sql`

This validation layer standardizes:
- exact int/stg-to-mart reconciliations
- mart reconciliation outputs
- missing dimension joins
- freshness checks

## Current Validation Status

### Strong / Working
- Sales monthly reference totals
- Gross margin monthly reference totals
- Labor monthly reference totals
- Sales per labor hour reference totals
- In-stock rate daily reference outputs
- Validation query pack exists and runs
- Reconciliation checks view exists and surfaces known failures clearly

### Known Exceptions
- `mart.recon_sales_to_gl_monthly` currently fails for January 2025 across:
  - gross_sales
  - net_sales
  - cogs
  - gross_margin
- Primary reason: simulated finance actuals are not yet derived from modeled operational truth
- Freshness controls fail for several mart objects because the project currently uses simulated static data

## Validation Philosophy
The semantic model should not be trusted only because relationships “look right.” It should be validated against:
- stable mart-layer totals
- cross-functional KPI references
- reconciliation outputs
- grain uniqueness sanity checks
- dimensional join coverage checks

## Next Validation Improvements
- align simulated finance actuals generation to operational monthly truth
- reclassify expected simulated-data freshness issues as warnings for cleaner portfolio presentation
- expand measure-level validation notes once DAX measure planning is more complete
