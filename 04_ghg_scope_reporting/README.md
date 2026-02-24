# Project 4 — “GHG Scope Reporting + Audit-Ready Documentation” (Sustainability analytics)
>### GHG Scope Reporting
> auditability + sustainability angle

**What it proves:** their sustainability bullets + external assurance readiness + standards-minded thinking.

**Purpose:** show audit-ready transformation discipline

Add prep/QA elements:

* factor version control table
* source-to-metric lineage
* reconciliation of utility/shipping inputs to emissions outputs
* external assurance checklist

This screams “audit-friendly analyst.”

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

---

# What to put on GitHub so it looks *hireable*

Use this structure (simple, professional, familiar):

* `README.md` (business problem → approach → screenshots → KPIs → outcomes)
* `data/` (raw samples + data dictionary)
* `sql/` (staging, marts, KPI views)
* `powerbi/` (pbix or instructions + screenshots if you don’t want to upload pbix)
* `docs/` (playbook, methodology, slide deck PDF)
* `tests/` (even basic SQL checks / reconciliation queries = credibility)

**README sections that make recruiters happy:**

* “Stakeholders & decisions supported”
* “KPIs & definitions” (this is *huge*)
* “Data model” (star schema screenshot)
* “Quality & reconciliation approach”
* “What I’d do next with internal Wyld data”

---
---

**auditability** story.

### Simulate realistic ESG source chaos

Use sample files like:

* `electricity_bills_monthly.xlsx`
* `fuel_usage_facility.csv`
* `shipping_miles_logistics.csv`
* `packaging_materials_procurement.csv`
* `emission_factors_reference.csv`

### Make robustness the whole point

#### A) Add a source lineage register

`docs/source_lineage.md`
For each metric, document:

* source file(s)
* transformation step
* factor version
* final output table

This is auditor candy.

#### B) Create a versioned factor table

`dim_emission_factor`

* `factor_id`
* `factor_type`
* `source_authority`
* `unit`
* `factor_value`
* `effective_start`
* `effective_end`
* `version`

Then reference the factor version in outputs.

#### C) Build reconciliation checks

Examples:

* Sum of facility-level emissions = reported monthly total
* No missing facilities for active sites
* No negative usage
* All factor joins successful
* Scope assignment coverage = 100%

#### D) Assurance request pack folder

Add:

* methodology
* assumptions log
* source register
* control checklist
* sample evidence files list

Even a fake version of this looks extremely strong.

---

# Make the “messy front line” visible in the repo

This is the important part. Don’t hide the mess. **Show that you manage it.**

## Add a shared `source_systems` framework at repo level

Create a top-level section like:

```txt
shared/source_systems/
  source_register_template.md
  file_naming_standards.md
  ingestion_checklist.md
  data_contract_template.md
  issue_log_template.md
```

### What each proves

* `source_register_template.md` → you inventory systems
* `file_naming_standards.md` → you control intake chaos
* `ingestion_checklist.md` → repeatable process mindset
* `data_contract_template.md` → communication with source owners
* `issue_log_template.md` → you track defects and resolution

That is elite BA portfolio behavior.

---

# Add a repeatable “Run Cycle” to every project

This makes your projects feel operational, not one-off.

## Example workflow (document this in each README)

1. Drop raw extracts into `data/source_extracts/...`
2. Run staging SQL / Power Query transforms
3. Run QA rules
4. Review exceptions report
5. Run reconciliation checks
6. Publish modeled tables
7. Refresh Power BI report
8. Export executive summary

This is the real muscle.

---

# Concrete files you should add now (high impact)

## 1) `docs/02_metric_dictionary.md`

Standardized definitions used across all 4 projects.

## 2) `shared/source_systems/source_register_template.md`

Use the same format in every project.

## 3) `shared/source_systems/ingestion_checklist.md`

A checklist for every refresh cycle.

## 4) `project_02.../sql/dq_rules/seed_dq_rules.sql`

Your DQ framework backbone.

## 5) `project_01.../sql/validation/reconciliation_checks.sql`

A “source vs modeled” proof page.

## 6) `project_04.../docs/Methodology.md`

Audit-ready, factor-versioned methodology.

These six things make the repo look way more senior immediately.

---
---

Project 4 (GHG)

Semantic model includes:

* `fact_emissions`
* `dim_factor_version`
* `dim_scope`
* DAX for emissions intensity, YoY, by scope/facility/product line
* audit readiness indicators

---
---

GHG Scope Reporting

**Reporting outputs**

* sustainability scorecard dashboard
* assurance-ready summary exports
* methodology / assumptions doc
* external assurance request pack checklist

**Proof signal**
You can support audit-facing reporting with traceability and documentation.