# Sample Outputs

## Purpose

This document shows representative outputs from the Quarterly Data Collection + QA/QC System after the reporting-layer views are built and the latest validation and reconciliation runs have been executed.

The goal is to make the final project outputs easy to review without requiring a dashboarding tool. These examples demonstrate:
- rule-level data quality results,
- open remediation-ready exceptions,
- quarter-level reconciliation status,
- and final certification outcome.

---

## 1. DQ Scorecard

### Source
`reporting.vw_dq_scorecard`

### Example query

```sql
select
    quarter_id,
    rule_name,
    rule_category,
    severity,
    target_table,
    checked_count,
    failed_count,
    failed_pct,
    status
from reporting.vw_dq_scorecard
order by rule_category, rule_name;
````

### Sample output

```text
quarter_id | rule_name                                             | rule_category  | severity | target_table                                | checked_count | failed_count | failed_pct | status
-----------+-------------------------------------------------------+----------------+----------+---------------------------------------------+---------------+--------------+------------+--------
2026Q1     | Required key present - retail sales                   | completeness   | critical | stg.stg_retail_account_sales_quarterly      | 9             | 1            | 0.1111     | fail
2026Q1     | Required key present - wholesale sales                | completeness   | critical | stg.stg_wholesale_account_sales_quarterly   | 9             | 1            | 0.1111     | fail
2026Q1     | Required key present - inventory                      | completeness   | critical | stg.stg_inventory_quarterly                 | 9             | 1            | 0.1111     | fail
2026Q1     | No duplicate business grain - retail sales            | uniqueness     | critical | stg.stg_retail_account_sales_quarterly      | 9             | 1            | 0.1111     | fail
2026Q1     | No duplicate business grain - wholesale sales         | uniqueness     | critical | stg.stg_wholesale_account_sales_quarterly   | 9             | 1            | 0.1111     | fail
2026Q1     | No duplicate business grain - inventory               | uniqueness     | critical | stg.stg_inventory_quarterly                 | 9             | 1            | 0.1111     | fail
2026Q1     | Quarter dates within expected range                   | validity       | high     | stg.stg_retail_account_sales_quarterly      | 9             | 1            | 0.1111     | fail
2026Q1     | Quarter dates within expected range - trade adjustments | validity     | high     | stg.stg_trade_adjustments                   | 7             | 1            | 0.1429     | fail
2026Q1     | No negative quantity - inventory                      | validity       | high     | stg.stg_inventory_quarterly                 | 9             | 1            | 0.1111     | fail
2026Q1     | Negative trade adjustments require valid reason code  | validity       | high     | stg.stg_trade_adjustments                   | 7             | 1            | 0.1429     | fail
```

### What this shows

* The quarter has failures across completeness, uniqueness, and validity.
* Critical failures are present in retail, wholesale, and inventory sources.
* The scorecard makes it easy to see both the count failed and percent failed by rule.
* This is the main rule-level monitoring output for the project.

---

## 2. Open Exceptions

### Source

`reporting.vw_open_exceptions`

### Example query

```sql
select
    quarter_id,
    rule_name,
    severity,
    assigned_team,
    target_table,
    record_key,
    issue_value,
    issue_description
from reporting.vw_open_exceptions
order by assigned_team, rule_name, record_key;
```

### Sample output

```text
quarter_id | rule_name                                             | severity | assigned_team                    | target_table                                | record_key                        | issue_value                                      | issue_description
-----------+-------------------------------------------------------+----------+----------------------------------+---------------------------------------------+-----------------------------------+--------------------------------------------------+---------------------------------------------------------------
2026Q1     | Required key present - wholesale sales                | critical | Commercial / Wholesale           | stg.stg_wholesale_account_sales_quarterly   | 2026Q1|2026-01-18|WH004|MISSING | sku_id is null                                   | Required key missing in wholesale sales submission
2026Q1     | No duplicate business grain - wholesale sales         | critical | Commercial / Wholesale           | stg.stg_wholesale_account_sales_quarterly   | 2026Q1|2026-01-11|WH001|SKU001   | duplicate_row_count=2                            | Duplicate wholesale sales business grain detected
2026Q1     | Required key present - retail sales                   | critical | Sales Operations                 | stg.stg_retail_account_sales_quarterly      | 2026Q1|2026-01-18|MISSING|SKU001 | dispensary_account_id is null                    | Required key missing in retail sales submission
2026Q1     | No duplicate business grain - retail sales            | critical | Sales Operations                 | stg.stg_retail_account_sales_quarterly      | 2026Q1|2026-01-11|DSP001|SKU001  | duplicate_row_count=2                            | Duplicate retail sales business grain detected
2026Q1     | Quarter dates within expected range                   | high     | Sales Operations                 | stg.stg_retail_account_sales_quarterly      | 2026Q1|2026-04-12|DSP002|SKU001  | week_end_date=2026-04-12                         | Retail sales week_end_date falls outside expected quarter range
2026Q1     | Required key present - inventory                      | critical | Supply Chain / Inventory Control | stg.stg_inventory_quarterly                 | 2026Q1|2026-01-25|WHSE02|MISSING | sku_id is null                                   | Required key missing in inventory submission
2026Q1     | No duplicate business grain - inventory               | critical | Supply Chain / Inventory Control | stg.stg_inventory_quarterly                 | 2026Q1|2026-01-11|WHSE01|SKU001  | duplicate_row_count=2                            | Duplicate inventory business grain detected
2026Q1     | No negative quantity - inventory                      | high     | Supply Chain / Inventory Control | stg.stg_inventory_quarterly                 | 2026Q1|2026-01-18|WHSE01|SKU003  | on_hand_units=-12                                | Inventory on_hand_units is negative
2026Q1     | Negative trade adjustments require valid reason code  | high     | Trade Marketing / Finance        | stg.stg_trade_adjustments                   | 2026Q1|ADJ005                     | adjustment_amount=-150.00 and reason_code is null | Negative trade adjustment is missing a required reason code
2026Q1     | Quarter dates within expected range - trade adjustments | high   | Trade Marketing / Finance        | stg.stg_trade_adjustments                   | 2026Q1|ADJ006                     | adjustment_date=2026-04-15                       | Trade adjustment date falls outside expected quarter range
```

### What this shows

* The system produces a remediation-ready exception queue, not just summary rule failures.
* Each issue is assigned to the business team best positioned to resolve it.
* Exceptions preserve business keys and concrete issue values, making them actionable.
* This is the main output for remediation workflow and issue ownership.

---

## 3. Reconciliation Summary

### Source

`reporting.vw_reconciliation_summary`

### Example query

```sql
select
    quarter_id,
    recon_name,
    metric_name,
    left_value,
    right_value,
    variance_value,
    variance_pct,
    tolerance_pct,
    status
from reporting.vw_reconciliation_summary
order by quarter_id, recon_name;
```

### Sample output

```text
quarter_id | recon_name                                        | metric_name                        | left_value | right_value | variance_value | variance_pct | tolerance_pct | status
-----------+---------------------------------------------------+------------------------------------+------------+-------------+----------------+--------------+---------------+--------
2026Q1     | Sales vs Finance reconciliation within tolerance  | net_sales_vs_finance_net_revenue   | 7740.00    | 7527.15     | 212.85         | 0.0283       | 0.0100        | fail
```

### What this shows

* Operational sales totals do not reconcile to finance net revenue within the approved 1.00% tolerance.
* Operational net sales exceed finance by 212.85.
* The variance percent is 2.83%, which is above tolerance.
* This output is the main quarter-level finance tie-out result.

---

## 4. Certification Output

### Source

`reporting.certified_quarterly_reporting`

### Example query

```sql
select
    quarter_id,
    run_id,
    run_status,
    open_exception_count,
    open_critical_exception_count,
    reconciliation_status,
    certification_status,
    certification_reason
from reporting.certified_quarterly_reporting
order by quarter_id;
```

### Sample output

```text
quarter_id | run_id | run_status | open_exception_count | open_critical_exception_count | reconciliation_status | certification_status | certification_reason
-----------+--------+------------+----------------------+-------------------------------+-----------------------+----------------------+----------------------------------
2026Q1     | 13     | completed  | 10                   | 7                             | fail                  | hold                 | reconciliation failed or not run
```

### What this shows

* The latest validation run completed successfully.
* The quarter still has open exceptions, including critical ones.
* Reconciliation failed.
* The quarter is therefore placed on **hold** rather than certified for reporting.

---

## Summary Interpretation

Across the current sample quarter:

* multiple critical rule failures remain open,
* reconciliation failed against finance,
* and certification is correctly held.

This is the intended behavior for the portfolio scenario. The source submissions were intentionally designed with realistic defects so the QA/QC framework could demonstrate:

* governed rule execution,
* detailed exception tracking,
* quarter-level finance tie-out,
* and explicit certification decision support.
