# Project 2 — Quarterly Data Collection + QA/QC System
## TODO / Build Tracker

This file tracks what has been completed, what still needs cleanup, and what remains to finish the project as a strong portfolio artifact.

---

## CURRENT SPRINT / TOP PRIORITY

### Highest-payout next steps
- [ ] Build Power BI page 1 — Data Quality Monitor
- [ ] Build Power BI page 2 — Open Exceptions
- [ ] Build Power BI page 3 — Reconciliation & Certification
- [ ] Export screenshots from Power BI
- [ ] Add screenshots to README
- [ ] Create one-page architecture diagram

### Nice-to-have after current sprint
- [ ] Final README polish
- [ ] Add short “How to run Project 2” section
- [ ] Decide whether to build a short summary deck

---

## 1. Project foundation

- [x] Define Project 2 scope and business problem
- [x] Define in-scope quarterly source submissions
- [x] Create project folder structure
- [x] Create schema setup SQL
- [x] Create `raw`, `ops`, `stg`, `dq`, and `reporting` schemas

---

## 2. Simulated source data

- [x] Create simulated quarterly source files
- [x] Include intentional defects for QA/QC testing
  - [x] missing required keys
  - [x] duplicate business-grain rows
  - [x] out-of-period dates
  - [x] negative inventory quantity
  - [x] missing trade-adjustment reason code
  - [x] sales vs finance mismatch
- [x] Build Project 2 data-generation script

---

## 3. Raw landing layer

- [x] Create raw landing tables
- [x] Load retail quarterly sales extract into raw
- [x] Load wholesale quarterly sales extract into raw
- [x] Load finance quarterly actuals into raw
- [x] Load inventory quarterly extract into raw
- [x] Load trade adjustments extract into raw

---

## 4. Staging layer

- [x] Create `stg.stg_retail_account_sales_quarterly`
- [x] Create `stg.stg_wholesale_account_sales_quarterly`
- [x] Create `stg.stg_finance_quarterly_actuals`
- [x] Create `stg.stg_inventory_quarterly`
- [x] Create `stg.stg_trade_adjustments`
- [x] Validate staged outputs against expected defects

---

## 5. DQ framework

- [x] Create `dq.dq_rules`
- [x] Create `dq.dq_run_log`
- [x] Create `dq.dq_results_fact`
- [x] Create `dq.dq_exceptions_detail`
- [x] Create `dq.recon_results`
- [x] Add indexes for DQ / exception / recon tables

---

## 6. Governed rule catalog

- [x] Seed completeness rules
- [x] Seed uniqueness rules
- [x] Seed validity rules
- [x] Seed timeliness rules
- [x] Seed reconciliation rules
- [x] Add missing `Required key present - inventory` rule
- [x] Add missing `No duplicate business grain - wholesale sales` rule
- [x] Rename trade-adjustment validity rule to `Negative trade adjustments require valid reason code`
- [x] Add `Quarter dates within expected range - trade adjustments`
- [x] Fix `target_column` metadata bug in `02_seed_dq_rules.sql`

### Rule catalog cleanup still to do
- [ ] Add idempotency protection to `sql/dq/02_seed_dq_rules.sql`
- [x] Clean up duplicate active wholesale duplicate-grain rule in `dq.dq_rules`

---

## 7. First-pass DQ execution

- [x] Create `sql/dq/03_run_first_pass_checks.sql`
- [x] Insert run metadata into `dq.dq_run_log`
- [x] Insert rule-level summary results into `dq.dq_results_fact`
- [x] Insert record-level failures into `dq.dq_exceptions_detail`
- [x] Update run status to `completed` at end of run

### Completeness rules implemented
- [x] Required key present - retail sales
- [x] Required key present - wholesale sales
- [x] Required key present - inventory

### Uniqueness rules implemented
- [x] No duplicate business grain - retail sales
- [x] No duplicate business grain - wholesale sales
- [x] No duplicate business grain - inventory

### Validity rules implemented
- [x] Quarter dates within expected range - retail sales
- [x] Quarter dates within expected range - trade adjustments
- [x] No negative quantity - inventory
- [x] Negative trade adjustments require valid reason code

### DQ runner improvements still to do
- [ ] Refactor `03_run_first_pass_checks.sql` to carry exact `run_id` via one `DO` block, temp table, or cleaner orchestration
- [ ] Add execution for cataloged-but-not-yet-run rules
  - [ ] Weekly continuity by source - retail sales
  - [ ] Approved template version submitted
  - [ ] Submission timeliness against due date
  - [ ] Margin percent within tolerance

---

## 8. Reconciliation

- [x] Create `sql/dq/04_run_reconciliation_checks.sql`
- [x] Reconcile operational sales to finance net revenue
- [x] Insert reconciliation output into `dq.recon_results`
- [x] Validate reconciliation output and failure status

### Reconciliation expansion still to do
- [ ] Decide whether to add more recon tests beyond first-pass sales vs finance
- [ ] Optionally add channel-level or source-level reconciliation detail

---

## 9. Reporting layer

- [x] Create `reporting.vw_dq_scorecard`
- [x] Create `reporting.vw_open_exceptions`
- [x] Create `reporting.vw_reconciliation_summary`
- [x] Create `reporting.certified_quarterly_reporting`
- [x] Validate certification logic for current quarter

### Reporting layer cleanup still to do
- [ ] Decide whether to add more certification logic detail
- [ ] Decide whether to add historical run-trend reporting views

---

## 10. Documentation

- [x] Update Project 2 overview / brief to match implemented workflow
- [x] Create `docs/quarterly_data_collection_playbook.md`
- [x] Create `docs/dq_rules_catalog.md`
- [x] Create `docs/reconciliation_guide.md`
- [x] Create `docs/release_notes.md`
- [x] Update Project 2 README / overview to reflect implemented workflow

### Documentation still to do
- [ ] Final README polish after visuals are ready
- [ ] Add screenshots into README
- [ ] Add short “How to run Project 2” section if not already included

---

## 11. Power BI / presentation

### Highest-payout next work
- [ ] Build Power BI report pages
  - [ ] Page 1 — Data Quality Monitor
  - [ ] Page 2 — Open Exceptions
  - [ ] Page 3 — Reconciliation & Certification

### After Power BI pages
- [ ] Export screenshots
- [ ] Add screenshots to README
- [ ] Create one-page architecture diagram
- [ ] Optionally create short summary deck for portfolio presentation

---

## 12. Final polish / portfolio completion

- [ ] Run final sanity check on DQ outputs
- [ ] Run final sanity check on reconciliation output
- [ ] Verify no duplicate active rules remain in `dq.dq_rules`
- [ ] Review naming consistency across SQL, docs, and README
- [ ] Review repo structure for clarity
- [ ] Decide whether Project 2 is complete enough to feature prominently in portfolio
- [ ] Push final commits to GitHub

---
