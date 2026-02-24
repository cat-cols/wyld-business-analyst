# Metrics Dictionary (Repo-Level)
**Repository:** wyld-business-analyst
**Scope:** Cross-project metric standards, naming conventions, and KPI governance
**Owner:** Brandon Hardison
**Status:** Draft v1 (repo-level canonical standards)

---

## Purpose

This document defines the **shared metric standards** for the entire repository.

It is the repo-wide source of truth for:
- metric naming conventions
- calculation standards
- rounding and null-handling rules
- KPI definitions used across projects
- governance rules for project-specific metric dictionaries

This file is **not** meant to replace project-level metric docs.
It defines the **rules of the road** so each project dictionary can implement metrics consistently without drifting into chaos.

---

## Scope and Hierarchy

### Governance hierarchy
1. **Repo-level metrics dictionary (this file)**
   - Defines shared naming, calculation, and QA standards
   - Defines canonical metric meaning across the repo

2. **Project-level metrics dictionary**
   - Example: `01_ops_command_center/docs/metrics_dictionary.md`
   - Defines project-specific grain, implementation details, and source-system quirks
   - May extend repo standards, but should not contradict them unless explicitly documented

### Rule of thumb
- **Repo-level = standards**
- **Project-level = implementation**

---

## Project Metric Dictionary Registry

Use project-specific dictionaries for row-grain and business logic specifics.

### Current / planned project metric docs
- `01_ops_command_center/docs/metrics_dictionary.md` ✅ (active)
- `02_quarterly_dc_qaqc_system/docs/metrics_dictionary.md` *(planned)*
- `03_forecasting_variance_story/docs/metrics_dictionary.md` *(planned)*
- `04_ghg_scope_reporting/docs/metrics_dictionary.md` *(planned)*

---

## Core Metric Design Principles

### 1) One metric, one meaning
A metric name should have **one consistent business meaning** across the repo.

Example:
- `net_sales_amount` always means **sales after discount**
- not “sometimes after discount, sometimes after returns, depending on the dashboard mood”

### 2) Store atomic metrics, derive reporting KPIs later
Prefer storing row-level atomic fields (e.g., `units_sold`, `unit_net_price`, `discount_rate`) and calculate aggregate KPIs in:
- SQL marts
- BI measures
- reporting layer logic

### 3) Separate row-level facts from reporting KPIs
- Row-level fields belong in fact tables
- Ratios/percentages are often better as derived measures
- Weighted averages should be computed at query/report time unless there is a strong reason to persist them

### 4) Rates are decimals, not formatted strings
Store rates as decimals:
- ✅ `0.12`
- ❌ `"12%"`
- ❌ `12`

Formatting belongs in BI/reporting.

---

## Naming Conventions (Repo Standard)

### Required suffix conventions
Use these consistently across all projects.

- `_amount` → currency totals (USD unless otherwise documented)
  - `net_sales_amount`
  - `cogs_amount`
  - `labor_cost_amount`

- `_price` → per-unit monetary value
  - `unit_list_price`
  - `unit_net_price`

- `_rate` → proportion (0 to 1)
  - `discount_rate`
  - `overtime_rate`

- `_pct` → presentation/reporting percentage (usually derived)
  - `gross_margin_pct`
  - `fill_rate_pct` *(optional naming; many teams still use `_rate`)*

- `_count` → integer counts
  - `order_count`
  - `customer_count`

- `_flag` → binary indicator (0/1)
  - `in_stock_flag`

- `_units` → unit quantities / counts of items
  - `units_sold`
  - `on_hand_units`
  - `backordered_units`

### Naming style
- Use **snake_case**
- Be explicit (avoid `sales`, prefer `net_sales_amount`)
- Avoid ambiguous prefixes like `total_` unless needed for semantic clarity

---

## Data Type Standards

### Currency fields
- Type: decimal / numeric
- Unit: USD (unless another currency is explicitly documented)
- Naming: `_amount` or `_price`

### Rates and percentages
- Store as decimal proportion (0–1)
- Format as percent only in BI/reporting

### Counts and units
- Integer where possible
- If simulated/estimated, document that in the project-level dictionary

### Flags
- Binary integer: `0` / `1`
- Avoid free-text boolean values (`"Y"`, `"N"`, `"true"`, `"false"`)

---

## Calculation Standards

### Rounding policy
To keep metrics reproducible and QA-friendly:

- **Row-level monetary fields** (`*_amount`, `*_price`)
  Round to **2 decimal places** in persisted modeled outputs

- **Rates** (`*_rate`)
  Store at **4+ decimal places** when possible (or at least enough precision to avoid drift)

- **Aggregate calculations**
  Prefer calculating from base components instead of summing already-rounded derived ratios

### Zero-division handling
Use null-safe division logic in SQL / BI:
- SQL pattern: `x / NULLIF(y, 0)`
- BI equivalent: safe divide functions (e.g., `DIVIDE()` in Power BI)

### Weighted averages
For repo consistency, weighted rates should usually be based on the metric’s natural denominator.

Examples:
- Weighted discount rate → weight by `gross_sales_amount`
- ASP (average selling price) → weight by `units_sold`

---

## Canonical Metric Definitions (Shared Standards)

These are repo-wide standard definitions.
Project-level docs should reference these and add implementation details.

---

### Sales & Revenue Standards

#### `units_sold`
- **Definition:** Number of units sold at the row grain
- **Unit:** Count
- **Type:** Integer
- **Notes:** Foundational sales volume metric

---

#### `unit_list_price`
- **Definition:** Effective pre-discount selling price per unit for the row
- **Unit:** USD per unit
- **Type:** Decimal
- **Notes:** May reflect channel pricing or price adjustments; project docs must document pricing logic

---

#### `discount_rate`
- **Definition:** Discount applied to the effective pre-discount price
- **Unit:** Proportion (0 to 1)
- **Type:** Decimal
- **Notes:** Row-level discount, not formatted percent

---

#### `unit_net_price`
- **Definition:** Per-unit selling price after discount
- **Unit:** USD per unit
- **Type:** Decimal
- **Formula (canonical):**
  - `unit_net_price = unit_list_price * (1 - discount_rate)`

---

#### `gross_sales_amount`
- **Definition:** Total sales before discount
- **Unit:** USD
- **Type:** Decimal
- **Formula (canonical):**
  - `gross_sales_amount = units_sold * unit_list_price`

---

#### `discount_amount`
- **Definition:** Total discount dollars applied
- **Unit:** USD
- **Type:** Decimal
- **Formula (canonical):**
  - `discount_amount = gross_sales_amount - net_sales_amount`

---

#### `net_sales_amount`
- **Definition:** Total sales after discount
- **Unit:** USD
- **Type:** Decimal
- **Formula (canonical):**
  - `net_sales_amount = units_sold * unit_net_price`
- **Equivalent formula:**
  - `net_sales_amount = gross_sales_amount * (1 - discount_rate)`

---

#### `cogs_amount`
- **Definition:** Cost of goods sold for the row or period
- **Unit:** USD
- **Type:** Decimal
- **Notes:** Project docs must state whether COGS is modeled from gross or net sales (standard preference: **net sales**)

---

#### `gross_margin_amount`
- **Definition:** Gross profit dollars after COGS
- **Unit:** USD
- **Type:** Decimal (usually derived)
- **Formula (canonical):**
  - `gross_margin_amount = net_sales_amount - cogs_amount`

---

#### `gross_margin_pct`
- **Definition:** Gross margin as a share of net sales
- **Unit:** Proportion (0 to 1) or presentation % in BI
- **Type:** Decimal (derived)
- **Formula (canonical):**
  - `gross_margin_pct = gross_margin_amount / NULLIF(net_sales_amount, 0)`

---

### Orders & Customer Activity Standards

#### `order_count`
- **Definition:** Number of orders represented at the row grain
- **Unit:** Count
- **Type:** Integer
- **Notes:** Can be estimated in synthetic datasets; document logic in project dictionary

---

#### `customer_count`
- **Definition:** Number of customers represented at the row grain
- **Unit:** Count
- **Type:** Integer
- **Notes:** If estimated/simulated, document assumptions

---

### Inventory & Fulfillment Standards

#### `on_hand_units`
- **Definition:** Inventory units available on hand at the defined point in time
- **Unit:** Count
- **Type:** Integer
- **Notes:** Project docs must clarify whether this is start-of-day or end-of-day (standard preference: **end-of-day**)

---

#### `received_units`
- **Definition:** Units received into inventory during the period
- **Unit:** Count
- **Type:** Integer

---

#### `shipped_units`
- **Definition:** Units shipped during the period
- **Unit:** Count
- **Type:** Integer

---

#### `requested_units`
- **Definition:** Demand/requested units for the period
- **Unit:** Count
- **Type:** Integer

---

#### `backordered_units`
- **Definition:** Units requested but not shipped due to stock constraints
- **Unit:** Count
- **Type:** Integer
- **Formula (canonical):**
  - `backordered_units = max(0, requested_units - shipped_units)`

---

#### `in_stock_flag`
- **Definition:** Inventory availability indicator
- **Unit:** Binary (0/1)
- **Type:** Integer
- **Formula (canonical):**
  - `in_stock_flag = 1 if on_hand_units > 0 else 0`

---

### Labor & Workforce Standards

#### `labor_hours`
- **Definition:** Regular labor hours worked
- **Unit:** Hours
- **Type:** Decimal

---

#### `overtime_hours`
- **Definition:** Overtime hours worked
- **Unit:** Hours
- **Type:** Decimal

---

#### `headcount`
- **Definition:** Active employee count at the row grain
- **Unit:** Count
- **Type:** Integer

---

#### `hires`
- **Definition:** Number of hire events in the row period
- **Unit:** Count
- **Type:** Integer

---

#### `terminations`
- **Definition:** Number of termination events in the row period
- **Unit:** Count
- **Type:** Integer

---

#### `labor_cost_amount`
- **Definition:** Labor cost for the row or period, including any overtime premium
- **Unit:** USD
- **Type:** Decimal
- **Notes:** Project docs should define cost composition (base + OT premium, etc.)

---

## Canonical Derived KPI Standards (Reporting Layer)

These are generally computed in SQL marts or BI measures, not persisted in base fact tables.

### `asp` (Average Selling Price)
- **Definition:** Average net revenue per unit
- **Formula:**
  - `SUM(net_sales_amount) / NULLIF(SUM(units_sold), 0)`

---

### `weighted_discount_rate`
- **Definition:** Discount rate weighted by gross sales
- **Formula:**
  - `SUM(discount_amount) / NULLIF(SUM(gross_sales_amount), 0)`

---

### `revenue_per_order`
- **Definition:** Net sales per order
- **Formula:**
  - `SUM(net_sales_amount) / NULLIF(SUM(order_count), 0)`

---

### `units_per_order`
- **Definition:** Average units sold per order
- **Formula:**
  - `SUM(units_sold) / NULLIF(SUM(order_count), 0)`

---

### `fill_rate`
- **Definition:** Percent of requested units fulfilled
- **Formula:**
  - `SUM(shipped_units) / NULLIF(SUM(requested_units), 0)`

---

### `backorder_rate`
- **Definition:** Percent of requested units that were backordered
- **Formula:**
  - `SUM(backordered_units) / NULLIF(SUM(requested_units), 0)`

---

### `in_stock_rate`
- **Definition:** Share of rows in stock
- **Formula:**
  - `AVG(in_stock_flag)`

---

### `overtime_rate`
- **Definition:** Share of total labor hours that are overtime
- **Formula:**
  - `SUM(overtime_hours) / NULLIF(SUM(labor_hours + overtime_hours), 0)`

---

### `labor_cost_pct_net_sales`
- **Definition:** Labor cost as a share of net sales
- **Formula:**
  - `SUM(labor_cost_amount) / NULLIF(SUM(net_sales_amount), 0)`
- **Notes:** Requires aligned grain/join logic in reporting layer if labor and sales are in separate fact tables

---

## Grain Standards and Documentation Rules

Every project-level metrics dictionary must document:

1. **Fact table grain**
   - Example: one row per date x product x location x channel

2. **Metric grain**
   - If a metric is stored in a fact, it inherits the fact grain unless documented otherwise

3. **Time semantics**
   - Daily vs monthly
   - Start-of-period vs end-of-period (especially inventory)

4. **Synthetic vs real-world assumptions**
   - If a metric is simulated/estimated, say so plainly

---

## QA & Validation Standards (Repo Minimums)

Every project should implement metric QA checks.
Below are repo-wide minimum standards.

### Currency and pricing
- `*_amount` fields should not be null in modeled outputs unless explicitly allowed
- `*_price > 0` when units or sales exist
- `discount_amount >= 0`

### Rates
- `0 <= *_rate <= 1` unless documented exception exists
- Stored as numeric, not strings

### Counts and units
- `*_count >= 0`
- `*_units >= 0` unless negative values are intentionally used for exceptions/testing and documented

### Flags
- `*_flag IN (0,1)`

### Formula integrity (with rounding tolerance)
Use small tolerance checks (e.g., ±0.01) for row-level currency comparisons:
- `gross_sales_amount ≈ units_sold * unit_list_price`
- `net_sales_amount ≈ units_sold * unit_net_price`
- `discount_amount ≈ gross_sales_amount - net_sales_amount`

---

## Where Business Logic Should Live

### Python scripts
Store **row-level generation logic** and simulation logic here.
- Example: `scripts/generate_project1_data.py`

### Project-level metric dictionary
Store **project-specific definitions and implementation notes** here.
- Channel pricing factors
- promo behavior
- source quirks
- row-grain specifics

### SQL marts / semantic layer / BI
Store **aggregated metrics and presentation logic** here.
- rolling averages
- MTD/QTD/YTD
- percent formatting
- executive KPI calculations

### QA scripts / validation SQL
Store **testable metric integrity rules** here.

---

## Metric Definition Template (For Future Projects)

Use this template in project-level dictionaries.

### `metric_name`
- **Definition:**
- **Type:**
- **Unit:**
- **Grain:**
- **Source inputs:**
- **Formula:**
- **Notes:**
- **QA checks:**

---

## Change Management

### How to update a metric definition
When changing metric logic:
1. Update this repo-level dictionary **if the shared standard changes**
2. Update the relevant project-level dictionary
3. Update SQL / Python / BI logic
4. Add or update QA checks
5. Note the change in the project changelog and/or repo changelog

### Backward compatibility rule
If a metric’s meaning changes materially, prefer:
- a new metric name (recommended), or
- a clearly documented version note

Do not silently redefine a metric and hope no one notices. Future You will absolutely notice.

---

## Change Log

### v1 (Draft)
- Established repo-wide standards for:
  - naming conventions
  - data types
  - rounding and safe-division logic
  - canonical sales, inventory, and labor metric definitions
  - shared derived KPI formulas
- Added governance relationship between repo-level and project-level metric dictionaries