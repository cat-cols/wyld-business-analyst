# Methodology — GHG Scope Reporting + Audit-Ready Documentation

## Purpose

This project simulates an audit-ready greenhouse gas reporting workflow using synthetic Scope 1, Scope 2, and Scope 3 activity data.

The purpose is to demonstrate how messy source extracts can be standardized, joined to versioned emission factors, calculated into emissions outputs, and validated through repeatable QA controls.

This project is not intended to represent official emissions reporting for any real company. All data and emission factors are synthetic and used for portfolio demonstration only.

---

## Reporting Boundary

The reporting boundary includes facility-level and product-line-related activity across the following emissions scopes.

| Scope | Included Activity | Source Extract |
|---|---|---|
| Scope 1 | Natural gas, diesel, gasoline | `fuel_usage_facility.csv` |
| Scope 2 | Purchased electricity | `electricity_bills_monthly.xlsx` |
| Scope 3 | Freight shipping | `shipping_miles_logistics.csv` |
| Scope 3 | Packaging materials | `packaging_materials_procurement.csv` |

Reference data used by the model:

| Reference File | Purpose |
|---|---|
| `facility_master.csv` | Facility, state, country, and grid-region mapping |
| `product_line_master.csv` | Product-line and product-family mapping |
| `emission_factors_reference.csv` | Versioned emission factors by factor type, unit, region, and effective date |

---

## Source-to-Model Flow

The model follows a layered SQL pattern:

```text
raw → stg → int → mart → qa
```

| Layer  | Purpose                                                                       |
| ------ | ----------------------------------------------------------------------------- |
| `raw`  | Preserve source extracts with minimal assumptions                             |
| `stg`  | Standardize names, dates, units, casing, and numeric fields                   |
| `int`  | Conform all activity sources into a shared emissions activity ledger          |
| `mart` | Publish reporting-ready facts, KPIs, and control views                        |
| `qa`   | Validate row counts, uniqueness, factor joins, and reportable emissions logic |

---

## Raw Layer

The raw layer stores source extracts as loaded from files.

Raw tables include:

| Raw Table                                 | Source File                           |
| ----------------------------------------- | ------------------------------------- |
| `raw.ghg_facility_master`                 | `facility_master.csv`                 |
| `raw.ghg_product_line_master`             | `product_line_master.csv`             |
| `raw.ghg_electricity_bills_monthly`       | `electricity_bills_monthly.xlsx`      |
| `raw.ghg_fuel_usage_facility`             | `fuel_usage_facility.csv`             |
| `raw.ghg_shipping_miles_logistics`        | `shipping_miles_logistics.csv`        |
| `raw.ghg_packaging_materials_procurement` | `packaging_materials_procurement.csv` |
| `raw.ghg_emission_factors_reference`      | `emission_factors_reference.csv`      |

Raw columns are intentionally permissive so that messy source issues can be loaded and analyzed rather than rejected before review.

---

## Staging Layer

The staging layer standardizes source-specific extracts into clean, typed, predictable views.

Examples of staging standardization:

| Source Issue                  | Staging Treatment                                       |
| ----------------------------- | ------------------------------------------------------- |
| Mixed month formats           | Parse into `activity_month`                             |
| Casing and whitespace drift   | Normalize with `trim`, `upper`, and `lower`             |
| Numeric fields loaded as text | Cast into numeric values                                |
| Unit synonyms                 | Normalize known units such as `gal` to `gallon`         |
| Invalid units                 | Flag as source defects instead of forcing a calculation |
| Missing facility IDs          | Preserve row and flag for QA review                     |
| Negative usage                | Preserve row and flag for QA review                     |

---

## Conformance Layer

The conformance layer combines all activity sources into a single emissions activity structure.

Primary conformance views:

| View                                | Purpose                                                                       |
| ----------------------------------- | ----------------------------------------------------------------------------- |
| `int.int_ghg_activity_all`          | Unions electricity, fuel, shipping, and packaging into one activity ledger    |
| `int.int_ghg_activity_with_factors` | Joins activity rows to facility, product line, and emission factor references |

The conformed activity grain is:

```text
one emissions activity row per source record / activity event
```

Core shared columns include:

| Column              | Purpose                                 |
| ------------------- | --------------------------------------- |
| `activity_id`       | Stable generated row identifier         |
| `source_system`     | Originating source extract              |
| `activity_month`    | Reporting month                         |
| `scope`             | Scope 1, Scope 2, or Scope 3            |
| `facility_id`       | Facility key                            |
| `product_line_id`   | Product-line key when applicable        |
| `activity_category` | Business activity type                  |
| `factor_type`       | Standardized factor classification      |
| `activity_amount`   | Quantity to multiply by emission factor |
| `activity_unit`     | Unit of measure                         |
| `factor_id`         | Matched emission factor                 |
| `factor_version`    | Factor version used in calculation      |

---

## Emissions Calculation Method

Emissions are calculated using the following method:

```text
activity_amount × factor_value_kg_co2e_per_unit = kg_co2e
kg_co2e ÷ 1000 = metric_tons_co2e
```

The model calculates emissions only when:

* activity amount is present
* activity amount is non-negative
* factor value is present
* factor join succeeds
* source activity type and unit are valid

---

## Emission Factor Matching Logic

Activity rows are joined to emission factors using:

| Join Field       | Purpose                                                  |
| ---------------- | -------------------------------------------------------- |
| `factor_type`    | Maps activity to the correct factor category             |
| `activity_unit`  | Ensures the unit matches the factor unit                 |
| `activity_month` | Ensures the factor is effective for the reporting period |
| `region`         | Applies regional electricity factors where needed        |

For Scope 2 electricity, factor region is based on the facility grid region.

For Scope 1 and Scope 3 activity, the current synthetic model uses `US` as the factor region.

---

## Reportable Row Logic

Rows are retained in the model even when they are not reportable. This supports audit review and source remediation.

A row is considered reportable when it does not have:

* negative activity amount
* missing facility ID
* invalid activity month
* unknown activity type
* missing facility join
* missing emission factor join

The reporting field is:

```text
is_reportable_emissions_row
```

Rows that fail reportability checks remain available in control views.

---

## QA and Control Views

Implemented QA checks include:

| QA Check                      | Purpose                                                        |
| ----------------------------- | -------------------------------------------------------------- |
| Raw rowcount check            | Confirms all source files loaded                               |
| Activity ID uniqueness        | Confirms `mart.fact_emissions` has a stable grain              |
| Reportable emissions not null | Confirms reportable rows have calculated emissions             |
| Clean rows have factor joins  | Confirms valid activity rows map to emission factors           |
| QA summary                    | Summarizes exception counts and reportable emissions by source |

Implemented mart control views include:

| Control View                          | Purpose                                            |
| ------------------------------------- | -------------------------------------------------- |
| `mart.controls_missing_factor_joins`  | Surfaces activity rows without factor matches      |
| `mart.controls_negative_activity`     | Surfaces invalid negative activity amounts         |
| `mart.controls_missing_dim_joins`     | Surfaces missing facility or product-line joins    |
| `mart.controls_unknown_activity_type` | Surfaces invalid activity type / unit combinations |

---

## Known Synthetic Source Defects

The source simulator intentionally creates defects to demonstrate data quality handling.

Known source defects include:

* duplicate source records
* missing facility IDs
* missing product line IDs
* mixed date formats
* negative usage amounts
* unit drift
* casing and whitespace inconsistencies
* natural gas rows reported in gallons instead of therms

The model does not delete these records. It preserves and flags them for review.

---

## Example Control Finding

The fuel usage extract includes a small number of natural gas rows reported with `gallon` as the activity unit.

Natural gas should map to the `natural_gas_therm` factor only when the activity unit is `therm`.

The model classifies these rows as unknown activity type exceptions and excludes them from reportable emissions totals until the source unit is corrected.

---

## Limitations

This project uses synthetic activity data and synthetic emission factors.

The factor values are not intended for official reporting. They are included to demonstrate:

* factor versioning
* factor matching logic
* emissions calculation structure
* QA and control design
* audit-ready documentation patterns

---

## Future Enhancements

Potential future enhancements include:

* persistent QA results table with run IDs
* exception resolution workflow
* source owner certification status
* Power BI Sustainability Scorecard
* external assurance evidence export pack
* official factor source citations
* change log for factor updates
