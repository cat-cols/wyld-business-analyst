# Wyld Business Analyst Portfolio

A four-project business analyst portfolio program designed to mirror real-world workflows:
**source intake → standardization → QA/QC → reconciliation → semantic model → executive reporting**.

## Projects
- `project_01_wyld_ops_command_center`
- `project_02_quarterly_dq_qaqc_system`
- `project_03_forecasting_variance_story`
- `project_04_ghg_scope_reporting`

Run `bash setup_repo.sh` to bootstrap the repo.

Or `chmod +x setup_repo.sh
./setup_repo.sh`

Start with Project 1 and reuse the shared standards across all projects.

If you do **only 3 projects**, do:

1. **Ops Command Center** (Project 1)
2. **Quarterly QA/QC + Reconciliation** (Project 2)
3. **Forecast + Variance Story** *or* **GHG Audit-Ready Scorecard** (Project 3 or 4, depending on what you want to lean into)

This combo nails: dashboards + data integrity + exec narrative + finance/sustainability relevance.

## Project 1 — “Wyld Ops Command Center” (Sales + Ops + People integrated BI)

**What it proves:** cross-functional integration + KPI design + visual narrative + exec-ready dashboards.

**Concept:** Build a Power BI dashboard that unifies **Sales**, **Operations/Inventory**, and **People** into a single “decision cockpit.”

**Data (public + realistic):**

* Sales: a public retail sales dataset (or Kaggle retail transactions)
* Ops: inventory + shipments dataset (or create a small synthetic inventory table to mimic ERP exports)
* People: headcount + labor hours + attrition (synthetic but plausible)

**Core KPIs (choose 10–15, but make them *tight*):**

* Revenue, gross margin %, AOV, units/transaction
* Fill rate, stockouts, days of inventory on hand (DIO), backorder rate
* On-time delivery %, cycle time
* Revenue per labor hour, overtime %, attrition %, hiring velocity

**Hard-mode features (this is the “impressive” part):**

* **Star schema** model with a proper Date table, dimensions, facts
* **Reconciliation page**: compare totals between “source extracts” vs “modeled fact” and flag deltas
* **Anomaly detection** (simple but effective): rolling z-score / IQR flags for sudden margin drops, stockout spikes
* **Narrative tooltips**: “What changed vs last period?” in plain English (DAX measures)

**Deliverables:**

* Power BI `.pbix`
* `sql/` folder with staging + mart queries
* `docs/` folder with a 6–8 slide “executive walkthrough”
* A 2-minute screen-recorded demo (optional, but chefs-kiss)

---


## Project 2 — “Quarterly Data Collection + QA/QC System” (Data quality + reconciliation)

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

---

## Project 3 — “Forecasting + Variance Story” (Planning, trends, partial info)

**What it proves:** trend/pattern detection, forecasting, plugging data gaps intelligently, explaining drivers.

**Concept:** Build a forecasting + variance analysis report:

* Forecast next 8–12 weeks of sales (or demand)
* Compare actuals vs forecast/budget
* Attribute variance to drivers (price, volume, mix)

**Model choices (keep it credible, not weird):**

* Baseline: seasonal naive + moving average
* Better: Prophet / SARIMA (optional)
* Add “confidence bands” and explain them simply

**Variance decomposition (this impresses finance people):**

* Sales variance = Price effect + Volume effect + Mix effect
* Margin variance = Rate effect + Volume effect (or a simple bridge chart)

**Deliverables:**

* Power BI dashboard pages:
  * Forecast
  * Variance bridge (waterfall)
  * Driver diagnostics
* Slide deck: “What happened, why, what to do next” (the holy trinity)

---

# Project 4 — “GHG Scope Reporting + Audit-Ready Documentation” (Sustainability analytics)

**What it proves:** their sustainability bullets + external assurance readiness + standards-minded thinking.

**Concept:** Build a simplified **Scope 1 / 2 / 3** emissions reporting model:

* Inputs: electricity usage, fuel, shipping distances, packaging materials (sample data)
* Outputs: emissions by scope, facility, month, product line, and intensity metrics

**Important:** You don’t need to be a climate scientist. You need to be an **audit-friendly analyst**:

* Clear assumptions table
* Versioned emission factors table
* Documented lineage (“this metric comes from these sources”)

**Deliverables:**

* Power BI “Sustainability Scorecard”
* `docs/Methodology.md` with assumptions + factor sources + change log
* “External assurance request pack” checklist (what an auditor would ask for)

This is very on-the-nose for: “verification of greenhouse gas emissions… maintaining external standards… documenting data processes… external assurance activities.”
