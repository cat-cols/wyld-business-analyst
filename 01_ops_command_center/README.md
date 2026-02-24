# Project 1 — “Wyld Ops Command Center” (Sales + Ops + People integrated BI)

# Project 1 — Wyld Ops Command Center

## What it proves
Cross-functional integration + KPI design + reconciliation + executive-ready BI.

## Source intake scenario
- sales_distributor_extract.csv
- inventory_erp_snapshot.csv
- labor_hours_payroll_export.xlsx
- finance_actuals_summary.xlsx

## Build flow
1. Drop extracts in `data/source_extracts/`
2. Run SQL staging/conformance/marts
3. Run validations + reconciliation
4. Refresh Power BI model and pages

>## The Foundation model + KPI dashboard

**What it proves:** cross-functional integration + KPI design + visual narrative + exec-ready dashboards.

**Concept:** Build a Power BI dashboard that unifies **Sales**, **Operations/Inventory**, and **People** into a single “decision cockpit.”

**Data (public + realistic):**
s
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
# Picking the best 2–3 (if you want max impact with minimum sprawl)


---

## Project 1 should prove 3 things:
1. You can ingest messy cross-functional data
2. You can reconcile and model it
3. You can tell the business story in Power BI

That means Project 1 becomes your flagship:
1. Sales + Ops + People integrated
2. with a reconciliation/control page
3. with source mapping docs

---

**cross-functional integration showcase**.

### Add a “source intake” scenario

Pretend you receive these monthly/weekly extracts:

* `sales_distributor_extract.csv`
* `inventory_erp_snapshot.csv`
* `labor_hours_payroll_export.xlsx`
* `finance_actuals_summary.xlsx`

### What to build (robust version)

#### A) `source_register.md`

A table like:

* Source name
* Domain (Sales/Ops/People/Finance)
* File type
* Refresh cadence
* Grain (transaction/daily/monthly)
* Join key(s)
* Known issues
* Owner

This screams “organized adult.”

#### B) Staging SQL layer

Create SQL files like:

* `stg_sales_distributor.sql`
* `stg_inventory_erp.sql`
* `stg_labor_payroll.sql`
* `stg_finance_actuals.sql`

Each one should:

* cast types
* standardize names
* create clean date fields
* trim text/codes
* flag bad rows

#### C) Conformance layer

Then create:

* `int_sales_conformed.sql`
* `int_inventory_conformed.sql`
* `int_labor_conformed.sql`

These align to shared dimensions:

* `dim_date`
* `dim_product`
* `dim_location`

#### D) Reconciliation page in Power BI

Make one dashboard page that shows:

* Source extract totals
* Modeled totals
* Variance ($ / %)
* Status flag (Pass / Warning / Fail)

This is pure job-description ammo.

💡💡 Add a KPI card: **“Data Confidence Score”** = % of checks passed.

Project 1 should explicitly include a **Power BI semantic model design** section.

Not just “here’s a PBIX.”
Show:

* star schema
* conformed dimensions
* DAX measure layer
* reconciliation measures
* report page architecture
* measure governance

That’s very BA/BI-pro move.

---

## Add a semantic model folder pattern to Project 1

Use this inside `project_01_wyld_ops_command_center/`:

```txt id="h1b4xq"
powerbi/
  wyld_ops_command_center.pbix
  semantic_model/
    model_design.md
    relationships_map.md
    dax_measure_catalog.md
    calculation_groups_plan.md        # optional/future
    naming_conventions.md
    refresh_assumptions.md
  report_pages/
    page_inventory.md
    tooltip_narratives.md
  exports/
    kpi_definition_export.csv         # optional
```

This makes the semantic layer visible, not hidden inside a binary `.pbix`.

---

## Robust methods to prove competence (the good stuff)

## 1) Treat DAX like a governed metric layer

Don’t scatter random measures everywhere.

Create a **DAX Measure Catalog** doc (`dax_measure_catalog.md`) with columns like:

* `Measure Name`
* `Business Definition`
* `DAX Expression`
* `Format`
* `Owner`
* `Used On Pages`
* `Notes / Caveats`

Examples:

* `[Net Sales]`
* `[Gross Margin %]`
* `[Net VWAP]`
* `[Stockout Rate]`
* `[Revenue per Labor Hour]`
* `[Reconciliation Delta - Net Sales]`

This is a huge maturity signal. It says:

> “I know metrics are products, not just formulas.”

---

## 2) Build a proper star schema and document relationship rules

In `model_design.md`, explicitly state:

### Fact tables

* `fact_sales`
* `fact_inventory`
* `fact_labor`

### Dimensions

* `dim_date`
* `dim_product`
* `dim_location`
* `dim_channel`
* `dim_employee_group`

### Relationship rules

* one-to-many from dims to facts
* single-direction filtering (where possible)
* no many-to-many unless intentionally bridged
* conformed dimensions reused across facts

Also document:

* what the **grain** of each fact is
* how date joins work
* what happens when a fact lacks a dimension key

This is exactly the stuff people break in Power BI without realizing it.

---

## 3) Separate base measures from derived measures

This is a really good semantic-model habit.

### Base measures (raw aggregations)

* `[Units Sold]`
* `[Gross Sales]`
* `[Net Sales]`
* `[COGS]`
* `[Labor Hours]`

### Derived KPI measures

* `[Gross Margin $]`
* `[Gross Margin %]`
* `[Net VWAP]`
* `[Revenue per Labor Hour]`
* `[Stockout Rate]`

### Comparison measures

* `[Net Sales vs Prior Period $]`
* `[Net Sales vs Prior Period %]`
* `[Margin bps Change]`

### QA / Control measures

* `[Source Net Sales]`
* `[Modeled Net Sales]`
* `[Reconciliation Delta]`
* `[Reconciliation Status]`

This hierarchy makes your model readable and maintainable.

---

## 4) Create a reusable DAX pattern library across projects

Since you have 4 projects, create a shared DAX pattern doc:

```txt id="87s8f1"
shared/
  semantic_model/
    dax_patterns.md
    time_intelligence_patterns.md
    reconciliation_measure_patterns.md
    narrative_measure_patterns.md
```

Put reusable patterns there:

* `DIVIDE()` safe division pattern
* prior-period logic
* rolling 7/28/90 day logic
* anomaly flags
* narrative text measures
* reconciliation status badges

Then Project 1/2/3/4 can each link to it.

That makes your repo look like a real BI practice, not four isolated assignments.

---

## 5) Build a “semantic model QA” section

This is a super strong proof point.

In Project 1, add a `semantic_model_validation.md` doc with checks like:

* totals match source extracts
* dimensions filter correctly across all facts
* no broken relationships
* blank dimension members monitored
* time intelligence validated at month boundaries
* measures return expected values in test slices

You can include a small table:

* Test case
* Expected result
* Actual result
* Pass/Fail

This is nerdy in the best way. Hiring managers love this whether they know it or not.

---

## 6) Use report-page architecture intentionally

Document the report pages like a product.

For Project 1, use something like:

1. **Executive Overview**

   * top KPIs
   * trend
   * key risks/opportunities

2. **Sales & Margin**

   * revenue, margin, VWAP, mix

3. **Ops & Inventory**

   * fill rate, stockouts, DIO, backorders

4. **People & Productivity**

   * labor hours, revenue/labor hour, overtime %, attrition

5. **Reconciliation & Data Health**

   * source vs modeled totals
   * DQ warnings
   * data freshness/status

6. **Diagnostics / Drillthrough**

   * product/location detail
   * exceptions

That layout feels like something a real company would use.

---

## 7) Add narrative measures (plain-English DAX)

This is a killer feature because it proves communication skill.

Examples:

* “Net Sales increased 8.4% vs prior month, driven by higher units in CA and OR, partially offset by lower margin in beverages.”
* “Stockout rate is elevated this month (6.2%), primarily in WA accounts for THC gummies.”

Store these in `tooltip_narratives.md` and note the logic.

This maps directly to their “data storytelling” requirement.

---

## 8) Build a shared semantic model concept across projects

Even if each project has its own `.pbix`, design them as if they could sit on top of shared datasets.

### Shared conformed dims (across all 4)

* `dim_date`
* `dim_location`
* `dim_product`

### Domain-specific facts

* Project 1: sales/inventory/labor
* Project 2: dq_results + exceptions + reconciliation
* Project 3: forecast + actuals + variance bridge
* Project 4: emissions + factors + assurance requests

This proves you understand the difference between:

* a dashboard
* a semantic model ecosystem

That’s advanced thinking for this role.

---

## Make this visible in your repo structure

Add this top-level shared section:

```txt id="9f98x1"
shared/
  semantic_model/
    conformed_dimensions.md
    relationship_standards.md
    dax_patterns.md
    measure_naming_conventions.md
    semantic_model_qa_checklist.md
```

Then in Project 1:

```txt id="lmt1i2"
project_01_wyld_ops_command_center/
  powerbi/
    wyld_ops_command_center.pbix
    semantic_model/
      model_design.md
      relationships_map.md
      dax_measure_catalog.md
      semantic_model_validation.md
    report_pages/
      page_inventory.md
      tooltip_narratives.md
```

This is a very clean “I know what I’m doing” look.

---

## How to describe this in Project 1 README

Use wording like:

> The core deliverable is a Power BI semantic model built on a conformed star schema (Sales, Inventory, Labor facts with shared Date/Product/Location dimensions), with governed DAX measures, reconciliation controls, and executive-facing report pages.

That sentence alone does a lot of work.

---

## Robust methods to prove competence in the reporting layer

## 1) Build a report page architecture with audience design

For each dashboard, define pages by audience and decision type.

Example for **Project 1 (Ops Command Center)**:

* **Executive Overview** (CEO/VP level)
* **Sales & Margin** (Finance/Commercial)
* **Ops & Inventory** (Operations)
* **People & Productivity** (People/Ops)
* **Reconciliation & Data Health** (analyst/finance controls)
* **Detail Drillthrough** (ad hoc analysis support)

In `report_pages/page_inventory.md`, document:

* page name
* audience
* purpose
* core KPIs
* key filters
* refresh cadence

That’s a very mature reporting move.

---

## 2) Create a deck-ready reporting pack for each project

Executives often want slides, not slicers. Grim but true.

For each project, include a `reports/executive_decks/` folder with a **structured slide outline** (markdown is fine) and a few exported images/screenshots.

### Example deck structure (works for all 4 projects)

1. **What happened** (headline KPIs)
2. **Why it happened** (drivers)
3. **What changed vs last period** (trend/variance)
4. **Risks / issues** (stockouts, DQ failures, forecast misses, audit gaps)
5. **Actions recommended** (3 bullets)

That “what / why / what now” rhythm is executive-native.

---

## 3) Add scheduled export artifacts

This is underrated and very realistic.

Create a `scheduled_exports/` folder in relevant projects with examples like:

* `ops_kpi_weekly_export.csv`
* `dq_exceptions_open_items.xlsx` (or csv)
* `forecast_variance_monthly_pack.csv`
* `ghg_scope_summary_monthly.csv`

Then add a small `docs/reporting_calendar.md`:

* report name
* audience
* cadence (weekly/monthly/quarterly)
* owner
* SLA date/time
* delivery format (Power BI / Excel / PPT)

This directly proves you understand “timeliness and completeness.”

---

## 4) Build an ad hoc request template

This is one of the most realistic artifacts you can add.

Create `reports/ad_hoc_requests/ad_hoc_request_template.md` with:

* requester
* business question
* date needed
* metric definitions used
* assumptions
* source(s)
* QA checks performed
* summary answer
* follow-up risks/questions

Then include 2–3 example completed ad hoc requests (simulated VP asks).

That maps to:

> “Performs ad hoc analysis as required by the VP…”

…and makes your repo feel like a working analyst workspace, not a class project.

---

## 5) Include “decision notes” with each dashboard page

This is a slick move.

In each project’s `docs/stakeholder_notes.md`, include short sections like:

* **What to watch**
* **How to interpret this KPI**
* **Known caveats**
* **Recommended actions if threshold is breached**

Example:

* If stockout rate > 4%, review top affected SKUs and locations on the Ops page.
* If DQ score < 95%, reconcile Sales and Finance extracts before publishing.

This proves you can bridge analytics into operations.

---

## 6) Use versioned executive walkthroughs

Make your walkthrough docs feel like living reporting artifacts.

For example:

* `executive_walkthrough_v1_0.md`
* `executive_walkthrough_v1_1.md`

Or simpler:

* `executive_walkthrough.md` with a change log section:

  * Added reconciliation page
  * Updated margin calc to use net sales
  * Added stockout threshold alert

That shows process maturity and documentation discipline.

---

## 7) Build a “reporting QA checklist” for publish readiness

Before a deck/dashboard goes out, what gets checked?

Create a shared checklist in:
`shared/reporting_ops/report_publish_checklist.md`

Include:

* data refresh complete
* reconciliation deltas within tolerance
* page filters validated
* KPI labels/formats correct
* commentary updated
* export files generated
* known issues disclosed

This is exactly the kind of quiet competence companies depend on.

---

## 8) Make executive narrative a first-class deliverable

Don’t just show charts — include the *story*.

For each project, write a short “Executive Summary” doc:

* 5 bullets max
* plain language
* one recommendation per bullet if possible

That directly proves:

* data storytelling
* stakeholder communication
* ability to turn analysis into action

Which is basically half the job description.

---

## How this maps into your 4 projects

## Project 1 — Ops Command Center

**Reporting outputs**

* Power BI executive dashboard (cross-functional)
* weekly KPI export sample
* executive walkthrough deck (6–8 slides)
* ad hoc request example (e.g., margin drop in AZ)

**Proof signal**
You can support recurring business reviews and leadership decision-making.

---
---

# What to put in `README.md` for Project 1

Use this structure:

1. **Business problem**

   * Leadership needs one integrated view of Sales + Ops + People.

2. **What this project proves**

   * Cross-functional integration, KPI design, reconciliation, storytelling.

3. **Source intake scenario**

   * List your 4 source extracts and known issues.

4. **Architecture**

   * Source → Staging → Conformance → Marts → Power BI semantic model.

5. **Star schema**

   * Fact grains + conformed dimensions.

6. **KPIs**

   * 10–15 tight KPIs with definitions (link metric dictionary).

7. **Reconciliation controls**

   * Explain tolerances + Data Confidence Score.

8. **Report pages**

   * 6-page architecture and audiences.

9. **How to run**

   * SQL steps, Power BI refresh, where outputs live.

10. **Screenshots / demo**

* Add images and demo link (if recorded).