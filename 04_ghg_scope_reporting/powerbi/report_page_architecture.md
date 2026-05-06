# Power BI Report Page Architecture — GHG Scope Reporting

## Purpose

This document defines the planned report pages, visuals, and business questions for a Power BI Sustainability Scorecard.

---

## Page 1 — Sustainability Scorecard

### Main Question

What are total reportable emissions and how are they trending?

### KPI Cards

- Reportable Metric Tons CO2e
- Scope 1 Metric Tons CO2e
- Scope 2 Metric Tons CO2e
- Scope 3 Metric Tons CO2e
- Reportable Row Rate
- QA Status

### Visuals

- Line chart: Reportable emissions by month
- Bar chart: emissions by scope
- Bar chart: emissions by facility
- Matrix: scope by activity category
- Insight box: top emissions drivers

---

## Page 2 — Emissions by Facility

### Main Question

Which facilities are driving emissions?

### KPI Cards

- Total reportable emissions
- Top emitting facility
- Facility count
- Scope 2 emissions

### Visuals

- Ranked bar: metric tons CO2e by facility
- Stacked bar: facility by scope
- Trend: monthly emissions by facility
- Matrix: facility, scope, activity category, metric tons CO2e

---

## Page 3 — Scope 3 Detail

### Main Question

What is driving Scope 3 freight and packaging emissions?

### KPI Cards

- Scope 3 Metric Tons CO2e
- Freight Metric Tons CO2e
- Packaging Metric Tons CO2e
- Missing product-line rows

### Visuals

- Bar chart: emissions by shipping mode
- Bar chart: emissions by packaging material
- Bar chart: emissions by product line
- Detail table: source system, product line, activity amount, metric tons CO2e

---

## Page 4 — Factor Version / Audit Review

### Main Question

Which emission factors and factor versions support the reported emissions?

### KPI Cards

- Factor count
- Factor versions used
- Rows with factor joins
- Missing factor join rows

### Visuals

- Table: factor ID, version, source authority, factor value
- Matrix: scope by factor type
- Bar chart: emissions by factor version
- Detail table: activity ID, evidence reference, factor ID, factor version

---

## Page 5 — Data Quality / Assurance Controls

### Main Question

Can stakeholders trust the emissions report?

### KPI Cards

- Total Rows
- Reportable Rows
- Non-Reportable Rows
- Missing Factor Join Rows
- Unknown Activity Type Rows
- Negative Activity Rows

### Visuals

- Bar chart: rows by QA status label
- Table: unknown activity type exceptions
- Table: negative activity exceptions
- Table: missing dimension joins
- Table: missing factor joins
- QA summary by source system

---

## Design Notes

- Executive pages should use reportable rows only.
- QA pages should include all rows.
- Red/yellow/green status should be used only for review labels.
- Definitions should be visible in tooltips or an appendix page.
- All visuals should support filtering by month, scope, facility, product line, and source system.