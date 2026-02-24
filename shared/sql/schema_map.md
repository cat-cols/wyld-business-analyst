# schema_map.md

## Purpose

This file maps the **assumed schema** used in the Wyld SQL pack to your **actual warehouse tables/columns**.

Use it before editing the SQL files so you can swap names cleanly and avoid mystery bugs.

---

## How to use this file

1. Fill in the **Actual Table / Column** values.
2. Mark each row:
   - `✅` = available and confirmed
   - `⚠️` = available but different meaning / grain
   - `❌` = missing (needs workaround)
3. Add notes for any business rules (returns, promotions, inventory snapshots, etc.).
4. Update the SQL pack queries using this map.

---

## Grain assumptions (important)

- `fact_sales` = transaction-level or daily sales by product/location/channel
- `fact_inventory` = daily inventory snapshots (preferred) or movements
- `fact_labor` = labor by date/location/team
- `dim_date` = one row per calendar date
- `dim_product` = one row per product SKU
- `dim_location` = one row per store/facility/account
- `dim_channel` = one row per channel
- `dim_employee_group` = optional org/team dimension

---

## Table-level mapping

| Assumed Table | Actual Table | Grain | Status | Notes |
|---|---|---|---|---|
| `fact_sales` |  |  |  |  |
| `fact_inventory` |  |  |  |  |
| `fact_labor` |  |  |  |  |
| `dim_date` |  |  |  |  |
| `dim_product` |  |  |  |  |
| `dim_location` |  |  |  |  |
| `dim_channel` |  |  |  |  |
| `dim_employee_group` |  |  |  | Optional |

---

## Column mapping: `fact_sales`

### Required for core KPI, pricing, mix, promo

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `date_key` |  |  |  |  | FK to `dim_date` |
| `product_key` |  |  |  |  | FK to `dim_product` |
| `location_key` |  |  |  |  | FK to `dim_location` |
| `channel_key` |  |  |  |  | FK to `dim_channel` |
| `units_sold` |  |  |  |  | Net of returns? |
| `gross_sales_amount` |  |  |  |  | Before discounts |
| `net_sales_amount` |  |  |  |  | After discounts |
| `cogs_amount` |  |  |  |  | Cost of goods sold |
| `promo_flag` |  |  |  |  | 0/1 or boolean |
| `order_count` *(optional)* |  |  |  |  | Helpful for conversion/order metrics |
| `customer_count` *(optional)* |  |  |  |  | Usually aggregated source only |

### Nice-to-have (for advanced analysis)

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `discount_amount` |  |  |  |  | If available, enables deeper promo analysis |
| `gross_unit_price` |  |  |  |  | If not available, derive = gross_sales / units |
| `net_unit_price` |  |  |  |  | If not available, derive = net_sales / units |
| `customer_id` |  |  |  |  | Needed for consumer repeat purchase analysis |
| `invoice_id` / `order_id` |  |  |  |  | Needed for order-level metrics |
| `return_units` |  |  |  |  | Helps separate returns from sales |
| `return_sales_amount` |  |  |  |  | Helps netting logic |

---

## Column mapping: `fact_inventory`

### Daily snapshot model (preferred)

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `date_key` |  |  |  |  | FK to `dim_date` |
| `product_key` |  |  |  |  | FK to `dim_product` |
| `location_key` |  |  |  |  | FK to `dim_location` |
| `on_hand_units` |  |  |  |  | End-of-day on hand |
| `in_stock_flag` *(optional)* |  |  |  |  | If missing, derive from `on_hand_units > 0` |
| `received_units` *(optional)* |  |  |  |  | Optional movement metric |
| `shipped_units` *(optional)* |  |  |  |  | Optional movement metric |
| `inventory_value_amount` *(optional)* |  |  |  |  | For value-based turnover |

### If inventory is movement-based instead of snapshots

| Assumed Concept | Actual Source / Column | Status | Notes |
|---|---|---|---|
| Opening inventory |  |  | Needed to reconstruct snapshots |
| Receipts |  |  |  |
| Shipments / sales depletion |  |  |  |
| Adjustments / shrink |  |  |  |
| Closing inventory |  |  |  |

---

## Column mapping: `fact_labor`

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `date_key` |  |  |  |  | FK to `dim_date` |
| `location_key` |  |  |  |  | FK to `dim_location` |
| `employee_group_key` *(optional)* |  |  |  |  | FK to `dim_employee_group` |
| `labor_hours` |  |  |  |  | Required for productivity metrics |
| `headcount` |  |  |  |  | Optional but useful |
| `labor_cost_amount` |  |  |  |  | Strongly recommended |

---

## Column mapping: `dim_date`

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `date_key` |  |  |  |  | Surrogate key or date |
| `full_date` |  |  |  |  | Calendar date |
| `week_start_date` |  |  |  |  | Monday/Sunday? define standard |
| `month_start_date` |  |  |  |  | Required by monthly queries |
| `year` *(optional)* |  |  |  |  |  |
| `month` *(optional)* |  |  |  |  |  |

**Calendar convention notes**
- Week starts on: `_____`
- Fiscal calendar used? `Yes / No`
- Fiscal month key column: `_____`

---

## Column mapping: `dim_product`

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `product_key` |  |  |  |  | PK |
| `product_name` |  |  |  |  |  |
| `brand_name` |  |  |  |  | Filter on `Wyld` |
| `cannabinoid_family` |  |  |  |  | THC / CBD / CBN / ratio |
| `flavor` |  |  |  |  |  |
| `pack_size` |  |  |  |  | Gummies per pack or unit count |
| `thc_mg_per_pack` |  |  |  |  | For price-per-mg metrics |
| `cbd_mg_per_pack` *(optional)* |  |  |  |  |  |
| `cbn_mg_per_pack` *(optional)* |  |  |  |  |  |
| `status` *(optional)* |  |  |  |  | Active/discontinued |

**Product modeling notes**
- Is potency stored per pack or per serving? `_____`
- Are bundle/multipack SKUs included? `_____`
- Are test products/samples included? `_____`

---

## Column mapping: `dim_location`

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `location_key` |  |  |  |  | PK |
| `location_name` |  |  |  |  | Store/account/facility name |
| `state` |  |  |  |  | 2-letter or full name |
| `region` |  |  |  |  |  |
| `location_type` *(optional)* |  |  |  |  | Store, facility, distributor, etc. |
| `is_active` *(optional)* |  |  |  |  | Helpful for distribution denominator |

**Location modeling notes**
- Does `location` represent retail doors, facilities, or both? `_____`
- If both, how are they distinguished? `_____`

---

## Column mapping: `dim_channel`

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `channel_key` |  |  |  |  | PK |
| `channel_name` |  |  |  |  | retail / ecommerce / wholesale |

---

## Column mapping: `dim_employee_group` (optional)

| Assumed Column | Actual Column | Data Type | Example | Status | Notes |
|---|---|---:|---|---|---|
| `employee_group_key` |  |  |  |  | PK |
| `team_name` |  |  |  |  |  |
| `department_name` |  |  |  |  |  |

---

## Query-to-column dependency map (quick reference)

Use this section to see which SQL files break if a field is missing.

| SQL File | Must-have fields |
|---|---|
| `01_kpi_exec_summary.sql` | sales: `units_sold`, `gross_sales_amount`, `net_sales_amount`, `cogs_amount`; dims: date/location/channel/product |
| `02_product_mix.sql` | sales: `units_sold`, `net_sales_amount`, `cogs_amount`; dims: date/product |
| `03_price_pack_architecture.sql` | sales: `units_sold`, `net_sales_amount`, `cogs_amount`; product: `thc_mg_per_pack`, `pack_size` |
| `04_promo_performance.sql` | sales: `units_sold`, `promo_flag`; dims: date/location/product |
| `05_distribution_ros.sql` | sales: `units_sold`; dims: date/location/product |
| `06_inventory_health.sql` | inventory: `on_hand_units` (+ optional `in_stock_flag`), sales: `units_sold`; dims: date/location/product |
| `07_sales_labor_productivity.sql` | sales: `net_sales_amount`, `units_sold`, `cogs_amount`; labor: `labor_hours` (+ optional `labor_cost_amount`) |
| `08_account_concentration.sql` | sales: `net_sales_amount`; dims: date/location/product |
| `09_account_retention.sql` | sales: `units_sold`; dims: date/product/location |
| `10_price_volume_mix_decomp.sql` | sales: `units_sold`, `net_sales_amount`; dims: date/product |
| `11_forecast_accuracy.sql` | sales: `units_sold`; plus `fact_forecast.forecast_units` if implemented |
| `12_data_quality_checks.sql` | sales: `units_sold`, `gross_sales_amount`, `net_sales_amount`, `cogs_amount` |

---

## Business rules checklist (fill this out before analysis)

### Sales rules
- Returns included in `fact_sales`? `Yes / No`
- If yes, how represented? `negative units / separate rows / separate table`
- Taxes included in sales amounts? `Yes / No`
- Freight included in sales amounts? `Yes / No`
- Discounts embedded in net sales or separate fields? `_____`

### Inventory rules
- Snapshot time each day: `_____`
- Weekend/holiday missing snapshots? `Yes / No`
- `on_hand_units` can be negative? `Yes / No`

### Labor rules
- Labor hours are actuals or scheduled? `_____`
- Contractors included? `Yes / No`
- Corporate/shared labor allocated to sites? `Yes / No`

### Product rules
- Potency values standardized and current? `Yes / No`
- Discontinued SKUs excluded? `Yes / No`

---

## Validation snippets (copy/paste checks)

### Row counts by table
```sql
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM fact_sales
UNION ALL
SELECT 'fact_inventory', COUNT(*) FROM fact_inventory
UNION ALL
SELECT 'fact_labor', COUNT(*) FROM fact_labor;
```

### Null checks on critical sales fields
```sql
SELECT
  SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END) AS null_date_key,
  SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS null_product_key,
  SUM(CASE WHEN location_key IS NULL THEN 1 ELSE 0 END) AS null_location_key,
  SUM(CASE WHEN units_sold IS NULL THEN 1 ELSE 0 END) AS null_units_sold,
  SUM(CASE WHEN net_sales_amount IS NULL THEN 1 ELSE 0 END) AS null_net_sales
FROM fact_sales;
```

### Duplicate key check (example for `dim_product`)
```sql
SELECT product_key, COUNT(*) AS cnt
FROM dim_product
GROUP BY 1
HAVING COUNT(*) > 1;
```

---

## Change log

| Date | Change | By |
|---|---|---|
| 2026-02-23 | Initial template created | B / ChatGPT |

---

## Notes

- This template is intentionally strict. Metrics go sideways fast when grain and definitions are fuzzy.
- Fill this out once, and your SQL edits become much faster and safer.
- Future-you will be extremely grateful.
