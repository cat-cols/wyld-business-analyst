# Data Dictionary

**Project:** 01_ops_command_center
**Domain:** Sales / Ops / Labor / Finance (Synthetic Business Analyst Portfolio Project)
**Owner:** Brandon Hardison
**Status:** Draft v1

---

## Purpose

This document defines the schema, meaning, and integrity rules for the Project 1 datasets.

It covers:
1) **Modeled truth tables** (clean dims + facts used for analysis)
2) **Messy source extracts** (simulated real-world inputs used for staging/standardization/QA)
3) **Generated run artifacts** (manifests, row counts)

This dictionary is designed to work alongside:
- `01_ops_command_center/docs/metrics_dictionary.md` (metric formulas and definitions)
- `01_ops_command_center/docs/source_register.md` (source ownership, cadence, known issues)

---

## Data Layers

### A) Modeled truth tables (clean)
Location:
- `01_ops_command_center/data/modeled/*.csv`

These are internally consistent and should be treated as the “truth layer.”

### B) Source extracts (messy realism layer)
Location:
- `01_ops_command_center/data/source_extracts/**`

These intentionally contain controlled quality issues to support QA/QC, reconciliation, and pipeline realism.

### C) Sample subsets
Location:
- `01_ops_command_center/data/sample/*_sample.csv`

Small slices of dims/facts for quick demos.

---

## Table Grains (Level of Detail)

### `fact_sales` grain
One row per:
- `date_key`
- `product_key`
- `location_key`
- `channel_key`

### `fact_inventory` grain
One row per:
- `date_key`
- `product_key`
- `location_key`

### `fact_labor` grain
One row per:
- `date_key`
- `location_key`
- `employee_group_key`

### Finance source extract grain
One row per:
- `month_start`
- `metric_name` (label may vary)

---

# MODELED TABLES (Truth Layer)

## 1) `dim_date` (`data/modeled/dim_date.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| date_key | INTEGER | Surrogate date key in `YYYYMMDD` | Primary key, unique | 20250115 |
| full_date | DATE | Calendar date | Not null | 2025-01-15 |
| year_num | INTEGER | Calendar year | 4-digit year | 2025 |
| quarter_num | INTEGER | Calendar quarter | 1–4 | 1 |
| month_num | INTEGER | Month number | 1–12 | 1 |
| month_name | STRING | Month abbreviation | Jan–Dec | Jan |
| week_num | INTEGER | ISO week number | 1–53 | 3 |
| weekday_num | INTEGER | Weekday number (Mon=1) | 1–7 | 3 |
| weekday_name | STRING | Weekday abbreviation | Mon–Sun | Wed |
| month_start_date | DATE | First day of month | Derived | 2025-01-01 |
| is_weekend | INTEGER | Weekend flag | 0/1 | 0 |

---

## 2) `dim_product` (`data/modeled/dim_product.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| product_key | INTEGER | Surrogate product key | Primary key | 7 |
| source_product_code | STRING | Source SKU code | Unique within dim | SKU0007 |
| product_name | STRING | Product full name | Trimmed, canonical | Wyld Marionberry THC Gummies |
| brand_name | STRING | Brand | Fixed: Wyld | Wyld |
| category_name | STRING | Category | e.g., Gummies | Gummies |
| flavor_name | STRING | Flavor | e.g., Marionberry | Marionberry |
| product_line | STRING | Line name | e.g., Mellow | Mellow |
| benefit_line | STRING | Benefit family | e.g., Sleep | Mellow |
| effect_type | STRING | Effect type | e.g., Indica Enhanced | Indica Enhanced |
| ratio_label | STRING | Cannabinoid ratio label | Informational | 2:1 THC:CBN |
| pack_size | INTEGER | Units per pack | > 0 | 10 |
| potency_mg_total | INTEGER | Total mg per pack | > 0 | 100 |
| base_list_price | DECIMAL(10,2) | Base unit list price used by generator | > 0 | 10.50 |
| base_cogs_ratio | DECIMAL(6,4) | Base COGS ratio | 0.25–0.75 (effective) | 0.4700 |
| demand_weight | FLOAT | Relative demand weight | > 0 | 1.12 |
| is_active | INTEGER | Active flag | 0/1 | 1 |

Notes:
- Prices here are synthetic and meant for modeling realism, not real-world pricing.
- Downstream unit pricing in facts also applies channel and discount logic.

---

## 3) `dim_location` (`data/modeled/dim_location.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| location_key | INTEGER | Surrogate location key | Primary key | 12 |
| source_location_code | STRING | Source site/store code | Join key to sources (messy) | OR12 |
| location_name | STRING | Friendly location name | Generated | OR Site 12 |
| state_province | STRING | State code | 2-letter | OR |
| region | STRING | Region label | Controlled list | Pacific NW |
| location_type | STRING | Account type | Retail / Distributor / Facility | Retail Account |
| preferred_channel | STRING | Default sales channel | Retail/Wholesale/Distributor | Retail |
| size_tier | STRING | Size tier | S/M/L | M |
| volume_multiplier | FLOAT | Relative volume scaling | > 0 | 1.0832 |
| is_active | INTEGER | Active flag | 0/1 | 1 |

---

## 4) `dim_channel` (`data/modeled/dim_channel.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| channel_key | INTEGER | Surrogate channel key | Primary key | 1 |
| channel_name | STRING | Channel name | Retail/Wholesale/Distributor | Retail |

---

## 5) `dim_employee_group` (`data/modeled/dim_employee_group.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| employee_group_key | INTEGER | Surrogate key | Primary key | 2 |
| department_name | STRING | Department | Controlled list | Operations |
| team_name | STRING | Team | Controlled list | Warehouse |

---

## 6) `fact_sales` (`data/modeled/fact_sales.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| date_key | INTEGER | Date key | FK → dim_date | 20250115 |
| product_key | INTEGER | Product key | FK → dim_product | 7 |
| location_key | INTEGER | Location key | FK → dim_location | 12 |
| channel_key | INTEGER | Channel key | FK → dim_channel | 1 |
| units_sold | INTEGER | Units sold | >= 1 | 8 |
| unit_list_price | DECIMAL(10,2) | Effective pre-discount unit price | > 0 | 10.34 |
| discount_rate | DECIMAL(6,4) | Discount rate | 0–0.35 | 0.1200 |
| unit_net_price | DECIMAL(10,2) | Net unit price after discount | <= unit_list_price | 9.10 |
| gross_sales_amount | DECIMAL(12,2) | Gross extended amount | units_sold * unit_list_price | 82.72 |
| net_sales_amount | DECIMAL(12,2) | Net extended amount | units_sold * unit_net_price | 72.80 |
| discount_amount | DECIMAL(12,2) | Discount dollars | gross - net | 9.92 |
| cogs_amount | DECIMAL(12,2) | Cost of goods | <= net_sales_amount (typical) | 33.49 |
| order_count | INTEGER | Estimated order count | >= 1 | 3 |
| customer_count | INTEGER | Estimated customer count | >= 1 | 3 |

Integrity checks (recommended):
- `discount_amount = gross_sales_amount - net_sales_amount` (within rounding tolerance)
- `unit_net_price = unit_list_price * (1 - discount_rate)` (within rounding tolerance)
- `gross_sales_amount = units_sold * unit_list_price` (within rounding tolerance)
- `net_sales_amount = units_sold * unit_net_price` (within rounding tolerance)

---

## 7) `fact_inventory` (`data/modeled/fact_inventory.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| date_key | INTEGER | Date key | FK → dim_date | 20250115 |
| product_key | INTEGER | Product key | FK → dim_product | 7 |
| location_key | INTEGER | Location key | FK → dim_location | 12 |
| on_hand_units | INTEGER | Ending on-hand | >= 0 in truth layer | 144 |
| received_units | INTEGER | Units received | >= 0 | 55 |
| shipped_units | INTEGER | Units shipped | >= 0 | 48 |
| requested_units | INTEGER | Requested demand | >= shipped_units | 52 |
| backordered_units | INTEGER | Unfilled demand | max(0, requested - shipped) | 4 |
| in_stock_flag | INTEGER | In-stock flag | 0/1 | 1 |

---

## 8) `fact_labor` (`data/modeled/fact_labor.csv`)

| Field | Type | Description | Rules | Example |
|---|---|---|---|---|
| date_key | INTEGER | Date key | FK → dim_date | 20250115 |
| location_key | INTEGER | Location key | FK → dim_location | 12 |
| employee_group_key | INTEGER | Employee group | FK → dim_employee_group | 2 |
| labor_hours | DECIMAL(10,2) | Regular hours | >= 0 | 68.50 |
| overtime_hours | DECIMAL(10,2) | Overtime hours | >= 0 | 6.00 |
| headcount | INTEGER | Headcount | >= 1 | 9 |
| hires | INTEGER | Hires events | 0/1 (per row) | 0 |
| terminations | INTEGER | Terminations events | 0/1 (per row) | 0 |
| labor_cost_amount | DECIMAL(12,2) | Labor cost | >= 0 | 2114.25 |

---

# SOURCE EXTRACTS (Messy Intake Simulation)

These files are intentionally “imperfect.” They simulate real-world inbound data feeds.

## SRC-001 — Sales Distributor Extract
Path:
- `01_ops_command_center/data/source_extracts/sales/sales_distributor_extract.csv`

Common issues included (by design):
- duplicates
- missing Store ID
- mixed date formats (`YYYY-MM-DD` and `MM/DD/YYYY`)
- channel casing/whitespace drift
- trailing spaces in product_name
- inconsistent headers (Title Case)

Expected fields (headers may vary):

| Field (as seen) | Type | Description | Notes / Rules | Example |
|---|---|---|---|---|
| Sale Date | STRING | Sale date | Mixed formats possible | 01/15/2025 |
| sku | STRING | SKU code | Joins to dim_product.source_product_code | SKU0007 |
| product_name | STRING | Product name | May include trailing spaces | Wyld Marionberry THC Gummies␠␠ |
| Store ID | STRING | Store/site code | May be missing | OR12 |
| channel | STRING | Channel name | Case/whitespace drift | " retail " |
| qty | INTEGER | Units sold | May be aggregated per grain | 8 |
| Gross Sales | DECIMAL | Gross dollars | | 82.72 |
| Discount Amount | DECIMAL | Discount dollars | | 9.92 |
| Net Sales | DECIMAL | Net dollars | | 72.80 |
| cogs | DECIMAL | COGS dollars | | 33.49 |
| orders | INTEGER | Orders estimate | | 3 |
| customers | INTEGER | Customers estimate | | 3 |
| Unit List Price | DECIMAL | Unit pre-discount | | 10.34 |
| Unit Net Price | DECIMAL | Unit post-discount | | 9.10 |
| Discount Rate | DECIMAL | Discount rate | 0–0.35 | 0.1200 |

---

## SRC-002 — Inventory ERP Snapshot
Path:
- `01_ops_command_center/data/source_extracts/ops/inventory_erp_snapshot.csv`

Issues included:
- negative On Hand for a few rows (data defect)
- site code casing/format drift (e.g., `or12`, `OR-12`)
- one missing snapshot day for one site (gap)

Fields:

| Field (as seen) | Type | Description | Notes / Rules | Example |
|---|---|---|---|---|
| Snapshot Date | STRING | Snapshot date | Generally `YYYY-MM-DD` | 2025-01-15 |
| sku | STRING | SKU code | Join to dim_product.source_product_code | SKU0007 |
| Site Code | STRING | Site/store code | Drift in casing/format | OR-12 |
| On Hand | INTEGER | On-hand units | May include negatives | -12 |
| receipts | INTEGER | Units received | >= 0 | 55 |
| shipments | INTEGER | Units shipped | >= 0 | 48 |
| Requested Units | INTEGER | Requested demand | >= 0 | 52 |
| Backordered Units | INTEGER | Backordered | >= 0 | 4 |

---

## SRC-003 — Labor Hours Payroll Export (XLSX)
Path:
- `01_ops_command_center/data/source_extracts/people/labor_hours_payroll_export.xlsx`
Sheet:
- `labor_export`

Issues included:
- team spelling variation (`Fulfillment` vs `Fulfilment`)
- some rows with 0 hours but non-zero cost (data defect)
- missing week window for one team/site

Fields:

| Field (as seen) | Type | Description | Notes / Rules | Example |
|---|---|---|---|---|
| Work Date | STRING | Work date | `YYYY-MM-DD` | 2025-01-15 |
| Site Code | STRING | Site/store code | | OR12 |
| department | STRING | Department | | Operations |
| team | STRING | Team | Spelling drift possible | Fulfilment |
| Hours Worked | DECIMAL | Regular hours | May contain 0 defect | 0 |
| OT Hours | DECIMAL | Overtime hours | >= 0 | 6.0 |
| Employee Count | INTEGER | Headcount | >= 0 | 9 |
| Labor Cost | DECIMAL | Labor cost | May remain > 0 if hours = 0 defect | 50.00 |

---

## SRC-004 — Finance Actuals Summary (XLSX)
Path:
- `01_ops_command_center/data/source_extracts/finance/finance_actuals_summary.xlsx`
Sheet:
- `finance_actuals`

Issues included:
- metric label variations (`Net Sales` vs `NET_SALES` vs `net_sales`)
- small drift vs modeled aggregates (reconciliation realism)

Fields:

| Field | Type | Description | Notes / Rules | Example |
|---|---|---|---|---|
| month_start | DATE | Month start date | Grain is monthly | 2025-01-01 |
| metric_name | STRING | Metric label | May vary in casing | NET_SALES |
| actual_amount | DECIMAL(14,2) | Amount in USD | Slight drift possible | 182334.22 |
| currency_code | STRING | Currency | USD | USD |

---

# GENERATED RUN ARTIFACTS

These are created when running `scripts/generate_project1_data.py`.

| File | Description |
|---|---|
| `01_ops_command_center/docs/generated_row_counts.csv` | Row counts of each table/extract |
| `01_ops_command_center/docs/generated_data_summary.json` | Run config + output paths + notes |
| `01_ops_command_center/docs/source_extract_manifest.csv` | Source manifest including row/col counts and generation notes |

---

## Notes on Real Locations (if used later)

If you later incorporate real dispensary/retailer lists:
- keep the repo clean by storing only small samples in `data/sample/`
- store full lists outside git (or as optional downloads)
- document provenance + scope in `docs/source_register.md`