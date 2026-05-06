# DAX Measure Catalog — GHG Scope Reporting

## Purpose

This catalog defines the DAX measures planned for the Project 4 Power BI semantic model.

The measures separate reportable emissions from non-reportable source exceptions.

---

## Core Emissions Measures

```dax
Total Metric Tons CO2e =
SUM(fact_emissions[metric_tons_co2e])
```

```dax
Reportable Metric Tons CO2e =
CALCULATE(
    [Total Metric Tons CO2e],
    fact_emissions[is_reportable_emissions_row] = TRUE()
)
```

```dax
Total kg CO2e =
SUM(fact_emissions[kg_co2e])
```

```dax
Scope 1 Metric Tons CO2e =
CALCULATE(
    [Reportable Metric Tons CO2e],
    fact_emissions[scope] = "Scope 1"
)
```

```dax
Scope 2 Metric Tons CO2e =
CALCULATE(
    [Reportable Metric Tons CO2e],
    fact_emissions[scope] = "Scope 2"
)
```

```dax
Scope 3 Metric Tons CO2e =
CALCULATE(
    [Reportable Metric Tons CO2e],
    fact_emissions[scope] = "Scope 3"
)
```

---

## Row Count / QA Measures

```dax
Total Rows =
COUNTROWS(fact_emissions)
```

```dax
Reportable Rows =
CALCULATE(
    COUNTROWS(fact_emissions),
    fact_emissions[is_reportable_emissions_row] = TRUE()
)
```

```dax
Non-Reportable Rows =
[Total Rows] - [Reportable Rows]
```

```dax
Reportable Row Rate =
DIVIDE([Reportable Rows], [Total Rows])
```

```dax
Missing Factor Join Rows =
CALCULATE(
    COUNTROWS(fact_emissions),
    fact_emissions[has_missing_factor_join] = TRUE()
)
```

```dax
Unknown Activity Type Rows =
CALCULATE(
    COUNTROWS(fact_emissions),
    fact_emissions[has_unknown_activity_type] = TRUE()
)
```

```dax
Negative Activity Rows =
CALCULATE(
    COUNTROWS(fact_emissions),
    fact_emissions[has_negative_activity] = TRUE()
)
```

```dax
Missing Facility Join Rows =
CALCULATE(
    COUNTROWS(fact_emissions),
    fact_emissions[has_missing_facility_join] = TRUE()
)
```

```dax
Missing Product Line Join Rows =
CALCULATE(
    COUNTROWS(fact_emissions),
    fact_emissions[has_missing_product_line_join] = TRUE()
)
```

---

## Time Intelligence Measures

Requires a marked date table.

```dax
Metric Tons CO2e PM =
CALCULATE(
    [Reportable Metric Tons CO2e],
    DATEADD(dim_date[date], -1, MONTH)
)
```

```dax
Metric Tons CO2e MoM Change =
[Reportable Metric Tons CO2e] - [Metric Tons CO2e PM]
```

```dax
Metric Tons CO2e MoM % =
DIVIDE(
    [Metric Tons CO2e MoM Change],
    [Metric Tons CO2e PM]
)
```

```dax
Metric Tons CO2e YTD =
TOTALYTD(
    [Reportable Metric Tons CO2e],
    dim_date[date]
)
```

---

## Intensity Measures

```dax
Total Cost USD =
SUM(fact_emissions[cost_usd])
```

```dax
Metric Tons CO2e per $1K Cost =
DIVIDE(
    [Reportable Metric Tons CO2e],
    [Total Cost USD] / 1000
)
```

---

## Display / Status Measures

```DAX
QA Status =
SWITCH(
    TRUE(),
    [Missing Factor Join Rows] > 0, "❌ Factor Issues",
    [Unknown Activity Type Rows] > 0, "⚠️ Activity Type Review",
    [Negative Activity Rows] > 0, "⚠️ Negative Activity Review",
    "✅ Passing"
)
```

## Notes

Do not use emoji status labels as model keys. Use them only for presentation.