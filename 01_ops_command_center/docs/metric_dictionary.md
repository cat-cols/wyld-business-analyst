# Metrics Dictionary
**Project:** 01_ops_command_center
**Domain:** Sales / Ops / Labor / Finance (Synthetic Business Analyst Portfolio Project)
**Owner:** Brandon Hardison
**Status:** Draft v1 (source-of-truth definitions for modeled and reporting metrics)

---

## Purpose

This document defines the official business meaning and formulas for key metrics used in the Wyld Business Analyst project.

It is the **source of truth** for:
- SQL transformations
- Python data generation logic
- QA/QC checks
- Power BI measures and visuals

This helps keep the same metric definitions consistent across the repo (so we don’t accidentally create three different versions of “net sales” and call it alignment).

---

## Metric Grains

Before defining metrics, here are the main grains (levels of detail) in this project:

### `fact_sales` grain
One row per:
- `date_key`
- `product_key`
- `location_key`
- `channel_key`

This is a **daily product-location-channel sales fact row** (synthetic generated row, not a raw transaction line).

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

### `finance_actuals_summary` source extract grain
One row per:
- `month_start`
- `metric_name`

---

## Pricing Logic Notes (Important)

In `generate_fact_sales`, pricing currently includes:
1. Product base list price (`dim_product.base_list_price`)
2. Small random variation (price noise)
3. Channel price factor (Retail / Wholesale / Distributor)
4. Discount rate

### Channel price factors
- Retail = `1.00`
- Wholesale = `0.88`
- Distributor = `0.82`

This means a row’s **effective unit list price** may be lower than the product’s base list price due to channel pricing.

---

## Sales Metrics (`fact_sales`)

### 1) `units_sold`
- **Definition:** Number of units sold for the row grain (daily x product x location x channel).
- **Type:** Integer
- **Unit:** Count
- **Grain:** `fact_sales`
- **Source inputs:** generated demand logic
- **Formula:** Generated via Poisson demand simulation (`units = max(1, poisson(...))`)
- **Notes:** Foundation for most revenue metrics.

---

### 2) `unit_list_price` *(recommended new column)*
- **Definition:** Effective pre-discount selling price per unit for the row, after channel pricing and price noise.
- **Type:** Decimal
- **Unit:** USD per unit
- **Grain:** `fact_sales`
- **Source inputs:** `dim_product.base_list_price`, channel factor, price noise
- **Formula (row-level):**
  - `unit_list_price = base_list_price_with_noise * channel_price_factor`
- **Notes:**
  - This should represent the actual per-unit gross price basis used in the row.
  - If you also want the pre-channel product list price, create a separate metric like `unit_msrp_price`.

---

### 3) `discount_rate` *(recommended new column)*
- **Definition:** Discount applied to the row’s effective unit list price.
- **Type:** Decimal
- **Unit:** Proportion (0 to 1)
- **Grain:** `fact_sales`
- **Source inputs:** discount generation logic
- **Formula (row-level):**
  - Generated from normal distribution and clipped:
  - `discount_rate = clip(normal(0.08 + promo_discount_extra, 0.035), 0, 0.35)`
- **Notes:**
  - Promo periods increase average discount.
  - Store as decimal (e.g., `0.12`), not percent string.

---

### 4) `unit_net_price` *(recommended new column)*
- **Definition:** Effective price per unit after discount.
- **Type:** Decimal
- **Unit:** USD per unit
- **Grain:** `fact_sales`
- **Source inputs:** `unit_list_price`, `discount_rate`
- **Formula (row-level):**
  - `unit_net_price = unit_list_price * (1 - discount_rate)`
- **Notes:**
  - This is the cleanest “unit economics” metric for downstream analysis.

---

### 5) `gross_sales_amount`
- **Definition:** Total sales before discount for the row.
- **Type:** Decimal
- **Unit:** USD
- **Grain:** `fact_sales`
- **Source inputs:** `units_sold`, `unit_list_price`
- **Formula (row-level):**
  - `gross_sales_amount = units_sold * unit_list_price`
- **Equivalent implementation note:**
  - In the current script, this is built from `units * list_price` and then channel-adjusted.
  - If you add `unit_list_price`, this becomes simpler and more explicit.

---

### 6) `discount_amount`
- **Definition:** Total discount dollars applied to the row.
- **Type:** Decimal
- **Unit:** USD
- **Grain:** `fact_sales`
- **Source inputs:** `gross_sales_amount`, `net_sales_amount`
- **Formula (row-level):**
  - `discount_amount = gross_sales_amount - net_sales_amount`
- **Notes:**
  - Must be `>= 0`
  - QA rule: `discount_amount <= gross_sales_amount`

---

### 7) `net_sales_amount`
- **Definition:** Total sales after discount for the row.
- **Type:** Decimal
- **Unit:** USD
- **Grain:** `fact_sales`
- **Source inputs:** `units_sold`, `unit_net_price`
- **Formula (row-level):**
  - `net_sales_amount = units_sold * unit_net_price`
- **Equivalent formula:**
  - `net_sales_amount = gross_sales_amount * (1 - discount_rate)`
- **Notes:**
  - This is the primary revenue metric for most reporting.

---

### 8) `cogs_amount`
- **Definition:** Cost of goods sold associated with the row’s net sales.
- **Type:** Decimal
- **Unit:** USD
- **Grain:** `fact_sales`
- **Source inputs:** `net_sales_amount`, product COGS ratio, COGS noise
- **Formula (row-level):**
  - `cogs_ratio_effective = clip(base_cogs_ratio + noise, 0.25, 0.75)`
  - `cogs_amount = net_sales_amount * cogs_ratio_effective`
- **Notes:**
  - COGS is modeled off **net sales**, not gross sales.

---

### 9) `order_count`
- **Definition:** Estimated number of orders represented by the row.
- **Type:** Integer
- **Unit:** Count
- **Grain:** `fact_sales`
- **Source inputs:** `units_sold`, channel order packing assumptions
- **Formula (row-level):**
  - Retail: `ceil(units_sold / randint(2, 6))`
  - Non-retail: `ceil(units_sold / randint(8, 20))`
- **Notes:**
  - Synthetic estimate used for operational KPI demos.

---

### 10) `customer_count`
- **Definition:** Estimated number of customers represented by the row.
- **Type:** Integer
- **Unit:** Count
- **Grain:** `fact_sales`
- **Source inputs:** `order_count`
- **Formula (row-level):**
  - `customer_count = ceil(order_count * uniform(0.85, 1.0))`
- **Notes:**
  - Synthetic estimate for customer reach / penetration visuals.

---

## Suggested Derived Sales KPIs (Reporting Layer)

These can be calculated in SQL or Power BI (not necessarily stored in `fact_sales`).

### Average Selling Price (ASP)
- **Definition:** Average net revenue per unit
- **Formula:**
  - `ASP = SUM(net_sales_amount) / NULLIF(SUM(units_sold), 0)`

### Average Discount Rate (weighted)
- **Definition:** Weighted discount rate based on gross sales
- **Formula:**
  - `weighted_discount_rate = SUM(discount_amount) / NULLIF(SUM(gross_sales_amount), 0)`

### Gross Margin Dollars
- **Definition:** Net sales minus COGS
- **Formula:**
  - `gross_margin_amount = SUM(net_sales_amount) - SUM(cogs_amount)`

### Gross Margin %
- **Definition:** Gross margin as a % of net sales
- **Formula:**
  - `gross_margin_pct = (SUM(net_sales_amount) - SUM(cogs_amount)) / NULLIF(SUM(net_sales_amount), 0)`

### Revenue per Order
- **Formula:**
  - `SUM(net_sales_amount) / NULLIF(SUM(order_count), 0)`

### Units per Order
- **Formula:**
  - `SUM(units_sold) / NULLIF(SUM(order_count), 0)`

---

## Inventory Metrics (`fact_inventory`)

### `on_hand_units`
- **Definition:** Ending on-hand inventory units after shipments and receipts.
- **Unit:** Count
- **Formula basis:** Inventory state simulation

### `received_units`
- **Definition:** Units received into inventory on the day.
- **Unit:** Count

### `shipped_units`
- **Definition:** Units shipped out on the day.
- **Unit:** Count

### `requested_units`
- **Definition:** Requested demand units (may exceed shipped units if stock constrained).
- **Unit:** Count

### `backordered_units`
- **Definition:** Requested units not shipped due to insufficient inventory.
- **Unit:** Count
- **Formula:**
  - `backordered_units = max(0, requested_units - shipped_units)`

### `in_stock_flag`
- **Definition:** Whether ending on-hand inventory is positive.
- **Unit:** Binary (0/1)
- **Formula:**
  - `in_stock_flag = 1 if on_hand_units > 0 else 0`

### Suggested derived inventory KPIs
- **Fill Rate**
  - `SUM(shipped_units) / NULLIF(SUM(requested_units), 0)`
- **Backorder Rate**
  - `SUM(backordered_units) / NULLIF(SUM(requested_units), 0)`
- **In-Stock %**
  - `AVG(in_stock_flag)`

---

## Labor Metrics (`fact_labor`)

### `labor_hours`
- **Definition:** Total regular labor hours worked.
- **Unit:** Hours

### `overtime_hours`
- **Definition:** Overtime hours worked.
- **Unit:** Hours

### `headcount`
- **Definition:** Active headcount for employee group at location/date.
- **Unit:** Count

### `hires`
- **Definition:** Hire events recorded for the row.
- **Unit:** Count (0/1)

### `terminations`
- **Definition:** Termination events recorded for the row.
- **Unit:** Count (0/1)

### `labor_cost_amount`
- **Definition:** Total labor cost (regular + overtime premium).
- **Unit:** USD
- **Formula basis:** `labor_hours * rate + overtime_hours * rate * 0.5`

### Suggested derived labor KPIs
- **Avg Hourly Labor Cost**
  - `SUM(labor_cost_amount) / NULLIF(SUM(labor_hours + overtime_hours), 0)`
- **Overtime Rate**
  - `SUM(overtime_hours) / NULLIF(SUM(labor_hours + overtime_hours), 0)`
- **Labor Cost % of Net Sales**
  - `SUM(labor_cost_amount) / NULLIF(SUM(net_sales_amount), 0)`
  *(join via date/location at reporting layer)*

---

## Finance Summary Metrics (`finance_actuals_summary.xlsx`)

These are monthly finance extract values (with intentional label variation/noise for QA/QC demo work).

### `Gross Sales`
- Monthly gross sales total (USD)

### `Net Sales`
- Monthly net sales total (USD)

### `COGS`
- Monthly cost of goods sold (USD)

### `Gross Margin`
- **Formula:**
  - `Gross Margin = Net Sales - COGS`

### `Labor Cost`
- Monthly labor cost total (USD)

---

## Recommended QA Rules (Metric Integrity Checks)

Use these in SQL validation or Python QA scripts:

### Sales QA
- `units_sold >= 1`
- `unit_list_price > 0`
- `0 <= discount_rate <= 0.35`
- `unit_net_price <= unit_list_price`
- `gross_sales_amount = units_sold * unit_list_price` (within rounding tolerance)
- `net_sales_amount = units_sold * unit_net_price` (within rounding tolerance)
- `discount_amount = gross_sales_amount - net_sales_amount` (within rounding tolerance)
- `cogs_amount <= net_sales_amount` (usually true in your model due to clip)
- `discount_amount >= 0`

### Inventory QA
- `requested_units >= shipped_units`
- `backordered_units = requested_units - shipped_units` (if positive, else 0)
- `in_stock_flag IN (0,1)`

### Labor QA
- `labor_hours >= 0`
- `overtime_hours >= 0`
- `headcount >= 1`
- `labor_cost_amount >= 0`

---

## Implementation Guidance

### Where logic should live
- **Row-level generation logic:** Python (`scripts/generate_project1_data.py`)
- **Standardized metric definitions:** This file (`metrics_dictionary.md`)
- **Aggregated/reporting logic:** SQL / Power BI measures
- **Validation logic:** SQL validation scripts or Python QA checks

### Naming conventions
Use clear suffixes:
- `_amount` for currency totals (USD)
- `_price` for per-unit prices
- `_rate` for proportions (0–1)
- `_count` for counts
- `_pct` for presentation ratios (optional, often reporting-only)

---

## Change Log

### v1 (Draft)
- Established canonical definitions for:
  - `gross_sales_amount`
  - `net_sales_amount`
  - `discount_amount`
  - `unit_list_price` (proposed)
  - `unit_net_price` (proposed)
  - `discount_rate` (proposed)
- Added inventory and labor metric definitions
- Added QA rule suggestions
