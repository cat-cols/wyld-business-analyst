# Wyld Style Business Analyst Portfolio

This repo is organized as a multi-project portfolio program.

A portfolio repository that simulates a real Business Analyst / Analytics workflow:

**source intake → standardization → QA/QC → reconciliation → semantic model → executive reporting**

This repo is built to demonstrate business analysis and analytics engineering habits in a realistic operating environment: messy inputs, documented controls, reusable SQL patterns, semantic model planning, and decision-ready reporting outputs.

---

## What this repo proves

- **Cross-functional analytics thinking** (Sales, Operations, Labor, Sustainability)
- **Data quality and reconciliation discipline** (not just dashboards)
- **SQL-first modeling habits** (staging → conformance → marts → validation)
- **BI/semantic model planning** (DAX catalogs, relationships, naming conventions)
- **Documentation maturity** (playbooks, source registers, metric dictionary, methodology)
- **Portfolio-ready project structure** with reusable templates and standards

---

## Current project status

### ✅ Included now
- **shared/** — reusable SQL, semantic model, governance, and source-system templates

### 🚧 In progress / planned
- **01_ops_command_center** — integrated Sales/Ops/Labor BI + reconciliation focus
- **02_quarterly_dc_qaqc_system** — data quality / QAQC system scaffolding and docs
- **03_forecasting_variance_story** — forecasting + variance analysis project (planned next)
- **04_ghg_scope_reporting** — sustainability reporting + auditability scaffolding and docs

---

## Repository structure

```text
.
├── 01_ops_command_center/               # Flagship BI + reconciliation project
│   ├── data/
│   ├── sql/                             # staging / conformance / marts / validation
│   ├── powerbi/                         # semantic model + report page docs
│   ├── docs/
│   └── reports/
├── 02_quarterly_dc_qaqc_system/         # DQ/QAQC controls + scorecard project
├── 04_ghg_scope_reporting/              # GHG / ESG reporting + assurance-ready docs
├── shared/                              # Reusable patterns/templates across projects
│   ├── sql/
│   ├── semantic_model/
│   ├── source_systems/
│   ├── templates/
│   └── reporting_ops/
├── docs/                                # Cross-project architecture, dictionaries, notes
├── scripts/                             # Data generation + utility scripts
├── assets/diagrams/                     # Architecture / schema diagrams
├── setup_repo.sh                        # Bootstrap script
├── requirements.txt
├── requirements-dq.txt
├── requirements-forecasting.txt
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

> **Note:** Project 1 sample generation is the most complete workflow right now. Some other script files are scaffold placeholders and will be filled in as the portfolio is finalized.

---

## Data strategy (important)

This repo is intentionally kept lightweight for GitHub.

### Tracked in Git

* Code
* SQL
* Docs
* Templates
* Small sample files / placeholders
* Diagrams and screenshots

### Not tracked in Git

* Large databases (`.db`, `.sqlite`)
* Large raw extracts
* Large modeled outputs
* Local runtime `environment/` data
* Archives / zip bundles

Large synthetic datasets and database files are intended to be distributed via **GitHub Releases** (or generated locally) so the repo stays fast to clone and easy to review.

---

## Synthetic enterprise analytics sandbox

This portfolio includes a synthetic “Wyld-like” enterprise analytics sandbox (local use) designed to simulate realistic business analyst workflows across multiple domains.

### Synthetic environment highlights

* **Date range:** 2022-01-01 to 2026-02-23
* **Domains:** Sales, Inventory, Labor, Forecasting, Emissions
* **Shared dimensions:** Date, Product, Location, Channel, Employee Group
* **Database support:** SQLite + SQL load script patterns for PostgreSQL / SQL Server

### Example row counts (synthetic)

* `fact_sales` — 356,030
* `fact_inventory` — 422,124
* `fact_labor` — 86,197
* `fact_forecast` — 367,284
* `fact_emissions` — 13,714

> This data is **synthetic** (fake but realistic-ish) and is used only for practice, portfolio demonstration, and workflow design.

---

## Projects

## 01 — Ops Command Center (Sales + Ops + Labor BI)

**Goal:** Build a decision-ready “command center” that integrates cross-functional data and includes a reconciliation/control layer.

### What it demonstrates

* Cross-functional KPI design
* Source-to-model reconciliation
* Star schema modeling habits
* Power BI semantic model planning
* Executive walkthrough documentation

### Core folders

* `01_ops_command_center/sql/` — staging, conformance, marts, validation
* `01_ops_command_center/powerbi/semantic_model/` — DAX catalog, relationships, naming conventions
* `01_ops_command_center/docs/` — source register, stakeholder notes, reconciliation logs
* `01_ops_command_center/reports/` — scheduled exports, ad hoc requests, deck outlines

---

## 02 — Quarterly Data Collection + QA/QC System

**Goal:** Simulate a repeatable quarterly data intake and QA process with DQ rules, exceptions, and reconciliation outputs.

### What it demonstrates

* QA/QC process design
* DQ rule governance
* Exceptions handling
* Release notes / rules change discipline
* Reporting integrity before publication

### Planned/active deliverables

* DQ rules seed table (`sql/dq_rules/`)
* DQ scorecard reporting outputs
* Quarterly playbook + release notes
* Exceptions/reconciliation workflows

---

## 04 — GHG Scope Reporting + Audit-Ready Documentation

**Goal:** Build a sustainability reporting workflow with clear assumptions, factor versioning, lineage, and audit-friendly documentation.

### What it demonstrates

* Auditability and controls mindset
* Methodology documentation
* Source-to-metric lineage
* Reconciliation checks for ESG-style reporting
* External assurance readiness practices

### Planned/active deliverables

* `docs/Methodology.md`
* Change log + lineage notes
* Assurance request checklist
* Sustainability scorecard/report scaffolding

---

## Shared standards across projects

This repo uses a `shared/` layer to show repeatable operating discipline:

* **`shared/source_systems/`** — source register templates, file naming standards, ingestion checklists
* **`shared/semantic_model/`** — relationship standards, DAX patterns, QA checklist
* **`shared/sql/`** — reusable KPI and reporting SQL patterns
* **`shared/templates/`** — SOPs, methodology, reconciliation templates

This is intentional: the point is to show not just analysis, but **repeatable analytics operations**.

---

## Tech stack

* **SQL** (Postgres / DuckDB style workflows)
* **Python** (pandas, numpy, openpyxl, pyarrow)
* **Power BI** (semantic model + report design documentation)
* **Data Quality** (Great Expectations, Pandera — planned/partial integration)
* **Forecasting** (statsmodels / Prophet — planned in Project 3)
* **Documentation-first workflow** (metric dictionary, source register, methodology, release notes)

---

## Environment setup notes

### Python

Main dependencies are listed in:

* `requirements.txt` (core/full setup)
* `requirements-dq.txt` (DQ-focused subset)
* `requirements-forecasting.txt` (forecasting-focused subset)

### Power BI

Power BI Desktop is Windows-only. On Mac, this repo is still useful for:

* SQL/data modeling
* docs and semantic model planning
* data prep and exports
* publishing/opening reports via Power BI Service (if applicable)

---

## Architecture and documentation

This repo is designed to be read by both technical reviewers and hiring managers.

Key docs to review:

* `docs/01_architecture_overview.md`
* `docs/02_metric_dictionary.md`
* `docs/03_data_dictionary.md`
* `docs/04_assumptions_limits.md`
* `01_ops_command_center/docs/source_register.md`
* `01_ops_command_center/docs/reconciliation_log.md`

---

## Simulation / data disclaimer

This repository uses **simulated and synthetic data** for portfolio purposes.

* No proprietary internal company data is included
* No confidential business records are used
* Company-like naming is for educational simulation and workflow realism only

The focus is on demonstrating **analytics process quality**, not representing any real company’s internal reporting systems.

---

## Roadmap

Near-term improvements:
* Move large local databases/assets to **GitHub Releases**
* Finalize repo download/setup links in project docs
* Add screenshot-based report previews
* Add minimal vs full environment setup options
* Build out Project 3 (Forecasting + Variance Story)

See `TODO.md` for the active backlog.

---

## Author

**Brandon Hardison**
GitHub: [cat-cols](https://github.com/cat-cols)

---

## License

This project is licensed under the terms in [`LICENSE`](LICENSE).
