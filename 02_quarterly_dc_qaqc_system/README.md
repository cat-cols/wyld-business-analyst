(1) stitch messy business data together,
(2) build trustworthy KPIs,
(3) tell the story in Power BI + decks
(4) do some finance + sustainability math without flinching.”

Below are **4 portfolio-grade projects** (you can do 2–3 and still look dangerous). Each one is designed so you can demo it in **Power BI + SQL + DAX + Power Query**, and also ship a clean repo + short slide deck.

---

# Project 2 — “Quarterly Data Collection + QA/QC System” (Data quality + reconciliation)
>## DQ/QAQC System

**What it proves:** their exact bullet points: QA/QC, data gaps/outliers, discrepancies during quarterly collection, process documentation.

**Concept:** Build a repeatable pipeline that ingests multiple “department extracts” (CSV/Excel style), validates them, and produces:

1. a clean reporting table
2. a **data quality scorecard**
3. an exceptions report stakeholders can act on

**Use cases to implement (realistic mess):**

* Missing keys (product_id/customer_id/store_id)
* Duplicate records
* Date gaps (missing weeks)
* Outliers (negative quantities, margin > 95%, etc.)
* Cross-source mismatch (Sales says $X, Finance extract says $Y)

**Tools:**

* SQL (Postgres/DuckDB)
* Power Query (for ingestion + shaping)
* Power BI report for DQ scorecard + exceptions

**Make it look “enterprise”:**

* A **DQ rules table** (rule_name, severity, logic, threshold)
* A **DQ results fact** (rule, table, count_failed, pct_failed, run_date)
* A “Release notes” page: what rules changed and why

**Deliverables:**

* A one-page **DQ SOP** (“Quarterly Data Collection Playbook”)
* Power BI “Data Quality Monitor” dashboard
* Reconciliation report template (Excel or Power BI page)

This project maps *directly* to their: “reconciling data across sources,” “tracking gaps/outliers/discrepancies,” “documenting processes,” “continuous data quality improvement.”

---
---

**process/control masterpiece**.

This is where you prove:

> “I can run quarterly collection without everything catching fire.”

### Build it like a mini enterprise DQ framework

#### A) Simulate a quarterly intake folder

Create fake files like:

* `Q1_sales_extract.csv`
* `Q1_finance_summary.csv`
* `Q1_ops_inventory.xlsx`
* `Q1_people_labor.csv`

And intentionally add problems:

* missing rows
* duplicate IDs
* date gaps
* invalid negative values
* mismatched totals

#### B) Create a `dq_rules` table

In SQL (or CSV seed), define:

* `rule_id`
* `rule_name`
* `domain`
* `severity`
* `table_name`
* `field_name`
* `threshold`
* `rule_description`

Examples:

* `NO_NULL_PRODUCT_KEY`
* `NO_DUPLICATE_TRANSACTION_ID`
* `NO_NEGATIVE_UNITS`
* `MARGIN_PCT_LT_95`
* `NO_MISSING_WEEKS`
* `RECON_DELTA_LT_1_PERCENT`

#### C) Create a `fact_dq_results` table

Fields:

* `run_id`
* `run_date`
* `rule_id`
* `table_name`
* `rows_checked`
* `rows_failed`
* `pct_failed`
* `status`
* `notes`

This is a huge credibility signal.

#### D) Exceptions output

Generate a clean exceptions table:

* row-level failures
* source file
* offending column
* issue type
* recommended action

Then show it in Power BI.

#### E) “Release notes” doc

Make `docs/release_notes.md` with entries like:

* Added rule for duplicate invoice IDs after Q2 issue
* Tightened margin threshold from 99% to 95%
* Updated product mapping for new beverage SKUs

---

**Purpose:** show repeatable process + controls

This becomes your **formal data quality engine**:

* `dq_rules` table
* `dq_results` fact
* exceptions report
* DQ scorecard
* SOP / playbook
* release notes

---
---

Project 2 (DQ/QAQC)

Semantic model includes:

* `fact_dq_results`
* `fact_reconciliation_results`
* `dim_rule`
* `dim_source_system`
* DAX for DQ score, failure trend, exceptions aging

---
---

## Project 2 — Quarterly DQ / QAQC System

**Reporting outputs**

* Power BI DQ Monitor dashboard
* exceptions report (open/resolved)
* quarterly QA/QC summary deck
* release notes + rules-changed log

**Proof signal**
You can manage reporting integrity and communicate data risk before publication.