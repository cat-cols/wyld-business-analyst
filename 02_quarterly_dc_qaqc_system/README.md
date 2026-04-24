## Project 2 — Quarterly Data Collection + QA/QC System

**What it is**
A governed quarterly intake, validation, reconciliation, and certification workflow for messy departmental submissions.

**What it proves**
I can build a repeatable business process for quarterly reporting that does more than ingest files. This project shows I can standardize inconsistent source extracts, apply governed QA/QC rules, surface remediation-ready exceptions, reconcile operational reporting to finance, and publish reporting-ready outputs that support certification decisions.

**Business problem**
Quarterly reporting often depends on files submitted by different teams using inconsistent templates, incomplete keys, invalid dates, duplicate business-grain rows, unexplained adjustments, and conflicting totals. Those problems slow reporting cycles, create manual cleanup work, and reduce trust in the final numbers.

**Current implementation**
This project currently includes:

- raw landing tables for quarterly source submissions
- typed staging views that preserve source defects for QA
- a governed DQ rules catalog
- run logging, rule-level scorecard results, and record-level exceptions
- first-pass completeness, uniqueness, and validity checks
- sales-to-finance reconciliation with tolerance logic
- reporting views for DQ scorecard, open exceptions, reconciliation summary, and quarter-level certification status

**In-scope source submissions**
- `retail_account_sales_quarterly_extract.csv`
- `wholesale_account_sales_quarterly_extract.csv`
- `finance_quarterly_actuals.csv`
- `inventory_quarterly_extract.csv`
- `trade_adjustments_extract.csv`

**Examples of issues intentionally simulated**
- missing required business keys
- duplicate business-grain rows
- out-of-period dates
- missing reporting weeks
- negative inventory quantities
- negative trade adjustments without reason codes
- suspicious wholesale sales relationships
- operational sales totals that do not reconcile to finance net revenue

**Core framework objects**
- `dq.dq_rules`
- `dq.dq_run_log`
- `dq.dq_results_fact`
- `dq.dq_exceptions_detail`
- `dq.recon_results`

**Reporting outputs**
- `reporting.vw_dq_scorecard`
- `reporting.vw_open_exceptions`
- `reporting.vw_reconciliation_summary`
- `reporting.certified_quarterly_reporting`

**Documentation**
- `docs/quarterly_data_collection_playbook.md`
- `docs/dq_rules_catalog.md`
- `docs/reconciliation_guide.md`
- `docs/release_notes.md`

**Why this matters**
This project is designed to show the process-control side of analytics work: not just building reports, but protecting reporting integrity before publication. It maps directly to QA/QC, discrepancy tracking, reconciliation across sources, exception management, process documentation, and continuous data quality improvement.

**Proof signal**
I can build a quarterly reporting QA/QC system that identifies data risk, routes issues to the right business owners, reconciles operational data to finance, and supports a clear hold-or-certify decision before reporting goes out.

