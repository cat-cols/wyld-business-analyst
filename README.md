# Wyld-Style Business Analyst Portfolio

![Project](https://img.shields.io/badge/flagship-Ops%20Command%20Center-4f46e5)
![Status](https://img.shields.io/badge/status-active%20multi--project%20portfolio-brightgreen)
![Focus](https://img.shields.io/badge/focus-SQL%20%7C%20QA%2FQC%20%7C%20reconciliation-blue)
![Docs](https://img.shields.io/badge/docs-playbooks%20%7C%20rules%20%7C%20methodology-0ea5e9)

A multi-project analytics portfolio designed to simulate realistic Business Analyst and Analytics Engineering work across messy source intake, standardization, QA/QC, reconciliation, semantic-model planning, and decision-ready reporting.

This repository is built to show more than dashboarding. It is meant to demonstrate how analytical work holds up when the environment is messy: inconsistent source files, data quality failures, reconciliation gaps, documentation requirements, and reporting controls.

**Workflow focus:**
**source intake → standardization → QA/QC → reconciliation → semantic model → executive reporting**

---

## What this repo proves

- **Cross-functional analytics thinking** across Sales, Operations, Labor, Forecasting, and Sustainability
- **Data quality and reconciliation discipline**, not just report-building
- **SQL-first modeling habits** from staging to conformance to marts to validation
- **Documentation maturity** through playbooks, source registers, reconciliation logs, and methodology docs
- **Portfolio-ready project structure** with reusable templates, shared standards, and realistic project scoping
- **Business-facing communication** through walkthroughs, release notes, and reporting narratives

---

## Current portfolio status

### Most complete now
- **01_ops_command_center** — flagship integrated analytics project
- **02_quarterly_dc_qaqc_system** — governed quarterly QA/QC and reconciliation workflow

### In progress / planned next
- **03_forecasting_variance_story** — forecasting + variance analysis
- **04_ghg_scope_reporting** — sustainability reporting + audit-ready documentation
- **05_decision_engine** — decision engine and recommendation system
- **06_fpna_planning** — FPNA planning and forecasting
- **07_sales_data_coordinator** — sales data coordination and standardization

### Shared across projects
- **shared/** — reusable SQL, semantic-model, governance, and documentation templates

---

## Repository structure

```text
.
├── 01_ops_command_center/               # Flagship BI + reconciliation project
│   ├── data/
│   ├── sql/
│   ├── powerbi/
│   ├── docs/
│   ├── reports/
│   ├── scripts/
│   └── requirements.txt
|
├── 02_quarterly_dc_qaqc_system/         # Quarterly QA/QC + reconciliation project
├── 03_forecasting_variance_story/       # Forecasting + variance analysis
├── 04_ghg_scope_reporting/              # GHG / ESG reporting + assurance-ready docs
├── 05_decision_engine/                  # Decision engine and recommendation system
├── 06_fpna_planning/                    # FPNA planning and forecasting
├── 07_sales_data_coordinator/           # Sales data coordination and standardization
|
├── shared/                              # Reusable patterns/templates across projects
│   ├── sql/
│   ├── semantic_model/
│   ├── source_systems/
│   ├── templates/
│   └── reporting_ops/
|
├── docs/                                # Cross-project architecture, dictionaries, notes
├── scripts/                             # Data generation + utility scripts
├── assets/diagrams/                     # Architecture / schema diagrams
├── setup_repo.sh                        # Bootstrap script
└── README.md
```

---

## Quick start

### 1) Clone the repo

```bash
git clone git@github.com:cat-cols/wyld-business-analyst.git
cd wyld-business-analyst
```

### 2) Bootstrap the project

```bash
bash setup_repo.sh
```

Useful options:

```bash
bash setup_repo.sh --skip-venv
bash setup_repo.sh --venv-name .venv
```

### 3) Activate the environment

```bash
source .venv/bin/activate
```

### 4) Generate sample data for Project 1

```bash
python scripts/generate_project1_data.py
```

> **Note:** Project 1 currently has the most complete end-to-end sample generation workflow. Other projects use a mix of implemented assets and scaffolding as the portfolio is finalized.

---

## Data strategy

This repository is intentionally kept lightweight for GitHub review.

### Tracked in Git

* code
* SQL
* docs
* templates
* small sample files
* diagrams and screenshots

### Not tracked in Git

* large databases (`.db`, `.sqlite`)
* large raw extracts
* large modeled outputs
* local runtime `environment/` data
* archives / zip bundles

Large synthetic datasets and local database artifacts are intended to be generated locally or distributed separately so the repo stays easy to clone and review.

---

## Synthetic enterprise analytics sandbox

This portfolio uses a synthetic “Wyld-like” analytics environment designed to simulate realistic business analyst workflows across multiple domains.

### Synthetic environment highlights
* **Date range:** 2022-01-01 to 2026-02-23
* **Domains:** Sales, Inventory, Labor, Forecasting, Emissions
* **Shared dimensions:** Date, Product, Location, Channel, Employee Group
* **Database support:** local SQL workflows with patterns adaptable to PostgreSQL / DuckDB / SQL Server

### Example synthetic row counts

* `fact_sales` — 356,030
* `fact_inventory` — 422,124
* `fact_labor` — 86,197
* `fact_forecast` — 367,284
* `fact_emissions` — 13,714

> All data in this repository is **synthetic** and used only for practice, portfolio demonstration, and workflow design.

---

## Projects

## 01 — Ops Command Center (Sales + Ops + Labor BI)

**Goal:** Build a decision-ready command center that integrates cross-functional data with reconciliation and control logic.

### What it demonstrates

* cross-functional KPI design
* source-to-model reconciliation
* dimensional modeling and mart design
* SQL validation and QA patterns
* semantic-model and report planning
* executive walkthrough documentation

### Key folders

* [`01_ops_command_center/sql/`](01_ops_command_center/sql/) — staging, conformance, marts, validation
* [`01_ops_command_center/docs/`](01_ops_command_center/docs/) — source register, stakeholder notes, reconciliation logs
* [`01_ops_command_center/powerbi/`](01_ops_command_center/powerbi/) — semantic model planning and report structure
* [`01_ops_command_center/reports/`](01_ops_command_center/reports/) — exports, ad hoc requests, deck outlines

---

## 02 — Quarterly Data Collection + QA/QC System

**Goal:** Simulate a governed quarterly intake, validation, reconciliation, and certification workflow for messy departmental submissions.

### What it demonstrates

* quarterly data intake process design
* DQ rule governance
* record-level exceptions handling
* release notes / rules change discipline
* operational-to-finance reconciliation
* reporting integrity before publication
* hold-or-certify decision support

### Current implemented outputs
* staged quarterly source views
* governed `dq_rules`, run log, results fact, exceptions detail, and recon tables
* first-pass completeness, uniqueness, and validity checks
* reporting views for:
  * `vw_dq_scorecard`
  * `vw_open_exceptions`
  * `vw_reconciliation_summary`
  * `certified_quarterly_reporting`
* project documentation including:
  * quarterly data collection playbook
  * rules catalog
  * reconciliation guide
  * release notes

### Key folders

* [`02_quarterly_dc_qaqc_system/sql/`](02_quarterly_dc_qaqc_system/sql/)
* [`02_quarterly_dc_qaqc_system/docs/`](02_quarterly_dc_qaqc_system/docs/)
* [`02_quarterly_dc_qaqc_system/README.md`](02_quarterly_dc_qaqc_system/README.md)

---

## 03 — Forecasting + Variance Story

**Goal:** Build a forecasting and variance-analysis project that explains not just what happened, but why actuals diverged from plan.

### Planned focus

* forecast vs actual comparisons
* variance decomposition
* business-driver framing
* narrative reporting for commercial and finance audiences

---

## 04 — GHG Scope Reporting + Audit-Ready Documentation

**Goal:** Build a sustainability reporting workflow with methodology clarity, factor versioning, lineage, and audit-friendly controls.

### What it demonstrates

* auditability and controls mindset
* methodology documentation
* source-to-metric lineage
* sustainability reporting structure
* assurance-readiness practices

### Planned/active deliverables

* methodology documentation
* factor/version tracking
* assurance request checklist
* sustainability scorecard/report scaffolding

---

## Shared standards across projects

This repo uses a `shared/` layer to show repeatable operating discipline across projects.

* [`shared/source_systems/`](shared/source_systems/) — source register templates, naming standards, ingestion checklists
* [`shared/semantic_model/`](shared/semantic_model/) — relationship standards, naming patterns, QA checklists
* [`shared/sql/`](shared/sql/) — reusable SQL and KPI patterns
* [`shared/templates/`](shared/templates/) — SOPs, methodology, reconciliation templates

This is intentional: the repo is meant to show not just analysis, but **repeatable analytics operations**.

---

## Tech stack

* **SQL** — PostgreSQL / DuckDB-style workflows
* **Python** — pandas, numpy, openpyxl, pyarrow
* **Power BI** — semantic-model and report-design planning
* **Data Quality** — rules-driven QA/QC workflows
* **Forecasting** — planned Project 3 expansion
* **Documentation-first workflow** — playbooks, source registers, methodology, release notes

---

## Where to start

If you want the clearest current examples, start here:

### Flagship project

* [`01_ops_command_center/docs/`](01_ops_command_center/docs/)

### Strongest process-control project

* [`02_quarterly_dc_qaqc_system/README.md`](02_quarterly_dc_qaqc_system/README.md)
* [`02_quarterly_dc_qaqc_system/docs/quarterly_data_collection_playbook.md`](02_quarterly_dc_qaqc_system/docs/quarterly_data_collection_playbook.md)
* [`02_quarterly_dc_qaqc_system/docs/dq_rules_catalog.md`](02_quarterly_dc_qaqc_system/docs/dq_rules_catalog.md)
* [`02_quarterly_dc_qaqc_system/docs/reconciliation_guide.md`](02_quarterly_dc_qaqc_system/docs/reconciliation_guide.md)

### Cross-project docs

* [`docs/`](docs/)

---

## Power BI note

Power BI Desktop is Windows-only. On Mac, this repo still demonstrates:

* SQL modeling
* QA/QC and reconciliation logic
* semantic-model planning
* documentation and output walkthroughs
* reporting-layer design without requiring Desktop itself

---

## Simulation / data disclaimer

This repository uses **simulated and synthetic data** for portfolio purposes.

* no proprietary internal company data is included
* no confidential business records are used
* company-like naming is used only for educational simulation and workflow realism

The focus is on demonstrating **analytics process quality**, not representing any real company’s internal reporting systems.

---

## Roadmap

Near-term improvements:

* finalize Project 2 sample outputs and walkthrough assets
* add screenshot-based report previews
* continue Project 3 forecasting build
* continue Project 4 sustainability reporting build
* keep shared templates and standards aligned across projects

---

## Author

**Brandon Hardison**
GitHub: [cat-cols](https://github.com/cat-cols)
LinkedIn: [brandon-hardison](https://www.linkedin.com/in/brandon-hardison-14003293/)

---

## License

This project is licensed under the terms in [`LICENSE`](LICENSE).
