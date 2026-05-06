# Power BI Semantic Model Blueprint — GHG Scope Reporting

## Purpose

This document defines the planned Power BI semantic model for Project 4: GHG Scope Reporting + Audit-Ready Documentation.

The goal is to translate the SQL mart layer into a reporting model that supports sustainability scorecards, emissions trend analysis, and data quality / assurance review.

---

## Core Reporting Table

### `mart.fact_emissions`

Primary fact table for emissions reporting.

**Grain:**

```text
one row per emissions activity record
```

**Key fields:**

| Field                         | Purpose                                     |
| ----------------------------- | ------------------------------------------- |
| `activity_id`                 | Unique emissions activity row               |
| `activity_month`              | Reporting month                             |
| `scope`                       | Scope 1, Scope 2, or Scope 3                |
| `source_system`               | Originating source extract                  |
| `facility_id`                 | Facility key                                |
| `product_line_id`             | Product-line key when applicable            |
| `activity_category`           | Electricity, fuel, freight, packaging, etc. |
| `activity_amount`             | Source activity amount                      |
| `activity_unit`               | Unit of measure                             |
| `factor_id`                   | Emission factor used                        |
| `factor_version`              | Version of factor used                      |
| `kg_co2e`                     | Calculated kilograms CO2e                   |
| `metric_tons_co2e`            | Calculated metric tons CO2e                 |
| `is_reportable_emissions_row` | Final reportability flag                    |
| `qa_status_label`             | Human-readable QA status                    |

---

## Supporting Mart Tables / Views

| Table / View                           | Purpose                                |
| -------------------------------------- | -------------------------------------- |
| `mart.fact_emissions`                  | Main emissions reporting fact          |
| `mart.kpi_emissions_intensity_monthly` | Monthly emissions and intensity rollup |
| `mart.controls_missing_factor_joins`   | Missing factor exceptions              |
| `mart.controls_negative_activity`      | Negative activity exceptions           |
| `mart.controls_missing_dim_joins`      | Facility/product join exceptions       |
| `mart.controls_unknown_activity_type`  | Invalid activity/unit exceptions       |

---

## Suggested Dimensions

These can be modeled directly from fields in `mart.fact_emissions` or promoted into separate dimension views later.

| Dimension      | Key                           | Source                                                    |
| -------------- | ----------------------------- | --------------------------------------------------------- |
| Date           | `activity_month`              | `mart.fact_emissions`                                     |
| Facility       | `facility_id`                 | `mart.fact_emissions` / `stg.stg_ghg_facility_master`     |
| Product Line   | `product_line_id`             | `mart.fact_emissions` / `stg.stg_ghg_product_line_master` |
| Scope          | `scope`                       | `mart.fact_emissions`                                     |
| Source System  | `source_system`               | `mart.fact_emissions`                                     |
| Factor Version | `factor_id`, `factor_version` | `mart.fact_emissions`                                     |

---

## Recommended Star Schema

```text
dim_date
   ↓
mart.fact_emissions
   ↑
dim_facility
dim_product_line
dim_scope
dim_source_system
dim_factor_version
```

For the first Power BI version, it is acceptable to use `mart.fact_emissions` as a wide fact table and create dimensions later if needed.

---

## Core Measures

### Emissions Measures

```DAX
Total Metric Tons CO2e =
SUM(mart_fact_emissions[metric_tons_co2e])
```

```DAX
Reportable Metric Tons CO2e =
CALCULATE(
    [Total Metric Tons CO2e],
    mart_fact_emissions[is_reportable_emissions_row] = TRUE()
)
```

```DAX
Total kg CO2e =
SUM(mart_fact_emissions[kg_co2e])
```

---

### Activity Measures

```DAX
Total Activity Amount =
SUM(mart_fact_emissions[activity_amount])
```

```DAX
Reportable Rows =
CALCULATE(
    COUNTROWS(mart_fact_emissions),
    mart_fact_emissions[is_reportable_emissions_row] = TRUE()
)
```

```DAX
Total Rows =
COUNTROWS(mart_fact_emissions)
```

```DAX
Non-Reportable Rows =
[Total Rows] - [Reportable Rows]
```

---

### QA Measures

```DAX
Missing Factor Join Rows =
CALCULATE(
    COUNTROWS(mart_fact_emissions),
    mart_fact_emissions[has_missing_factor_join] = TRUE()
)
```

```DAX
Unknown Activity Type Rows =
CALCULATE(
    COUNTROWS(mart_fact_emissions),
    mart_fact_emissions[has_unknown_activity_type] = TRUE()
)
```

```DAX
Negative Activity Rows =
CALCULATE(
    COUNTROWS(mart_fact_emissions),
    mart_fact_emissions[has_negative_activity] = TRUE()
)
```

```DAX
Missing Dimension Join Rows =
CALCULATE(
    COUNTROWS(mart_fact_emissions),
    mart_fact_emissions[has_missing_facility_join] = TRUE()
        || mart_fact_emissions[has_missing_product_line_join] = TRUE()
)
```

```DAX
Reportable Row Rate =
DIVIDE([Reportable Rows], [Total Rows])
```

---

## Suggested Report Pages

## Page 1 — Sustainability Scorecard

**Purpose:** Executive overview of reportable emissions.

Recommended visuals:

* KPI card: Reportable Metric Tons CO2e
* KPI card: Scope 1 Emissions
* KPI card: Scope 2 Emissions
* KPI card: Scope 3 Emissions
* Line chart: emissions by month
* Bar chart: emissions by scope
* Bar chart: emissions by facility
* QA card: Reportable Row Rate

---

## Page 2 — Emissions by Scope and Facility

**Purpose:** Show where emissions are coming from.

Recommended visuals:

* stacked bar: metric tons CO2e by scope and facility
* matrix: facility by scope
* trend: monthly emissions by facility
* slicers: scope, facility type, state, activity category

---

## Page 3 — Scope 3 Detail

**Purpose:** Focus on freight and packaging emissions.

Recommended visuals:

* freight emissions by shipping mode
* packaging emissions by material type
* emissions by product line
* activity amount vs emissions
* exception table for missing product-line joins

---

## Page 4 — Factor Version / Audit Review

**Purpose:** Show factor traceability.

Recommended visuals:

* table: factor ID, factor version, source authority, activity unit, region
* emissions by factor version
* count of rows by factor ID
* filter by activity month and scope

---

## Page 5 — Data Quality / Assurance Controls

**Purpose:** Show whether the emissions model is trustworthy.

Recommended visuals:

* card: Missing Factor Join Rows
* card: Unknown Activity Type Rows
* card: Negative Activity Rows
* card: Missing Dimension Join Rows
* table: exceptions by source system
* table: `qa_status_label` by row count
* drillthrough table: evidence reference, source system, facility, activity unit, status

---

## Key Design Principle

The report should separate:

```text
reportable emissions
```

**from**

```text
source/data quality exceptions
```

The scorecard should use reportable rows only.

The QA page should show both reportable and non-reportable rows so reviewers can understand what was excluded and why.

---

## Future Enhancements

* Create physical dimension views for date, facility, product line, scope, and factor version
* Add persistent QA results by run ID
* Add exception owner and resolution status
* Add Power BI tooltip pages explaining metric definitions
* Add exportable assurance summary page