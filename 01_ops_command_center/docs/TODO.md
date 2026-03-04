# Wyld Business Analyst Project TODO

- keeps the “audit” items as real checklists
- put the **execution-critical stuff** (build + QA + runners) in the right places

## Phase 1 — Simulate messy source extracts

* [ ] Re-run `scripts/simulate_source_drops.py` for a fresh 30–90 day window
* [ ] Verify drop manifest updates (`docs/source_drop_manifest.csv` or equivalent)
* [ ] Confirm “current” copies are updated under each `data/source_extracts/**/current/`

## Phase 2 — Staging layer (raw → stg)

* [ ] Run `sql/stg/00_create_schemas.sql` against `wyld_chyld`
* [ ] Load/refresh `raw.*` tables from latest source drops
* [ ] Build all `stg.stg_*` views
* [ ] Add `sql/stg/_build_stg.sql` runner
* [ ] Run Stage QA (`sql/stg/checks/qa_checks.sql`)
* [ ] Add staging “contracts” as QA queries (not-null keys, accepted values)

## Phase 3 — Conformance layer (stg → int)

### Shared entities + conformed logic

* [ ] Confirm canonical store key: `store_code` everywhere

* [ ] Ensure `int.int_dispensary_latest` + `int.int_account_status_current` are built and stable

* [ ] Implement/confirm:
  * [ ] `int/core/int_dispensary_standardized.sql`
  * [ ] `int/ops/int_coverage_conformed.sql`

* [ ] Implement/finish INT “domain wrappers” (if used, not just placeholders):
  * [ ] `int/sales/int_sales_conformed.sql`
  * [ ] `int/ops/int_inventory_conformed.sql`
  * [ ] `int/hr/int_labor_conformed.sql`

### INT orchestration + QA

* [ ] Expand `sql/int/_build_int.sql` to include **all required INT models** (core + sales + ops + hr)

* [ ] Run INT QA suite:
  * [ ] `sql/_qa/int/qa_int.sql`
  * [ ] `sql/_qa/int/qa_int_truth_uniqueness.sql`

## Phase 4 — Mart layer (facts + controls)

### Core dimensions

* [ ] Confirm marts build:
  * [ ] `mart.dim_date`
  * [ ] `mart.dim_store`
  * [ ] `mart.dim_sku`

* [ ] Implement `mart.dim_channel` **or** delete the stub if you won’t use it

### Facts

* [ ] Sales:
  * [ ] `mart.fact_sales_distributor_daily` (verify QA + joins)
  * [ ] `mart.fact_sales_pos_daily` (wire to correct POS source + columns)
  * [ ] `mart.fact_sales_daily` (unified wrapper)
  * [ ] `mart.agg_sales_store_daily`
  * [ ] `mart.fact_distribution_coverage` (from `_fact_distribution_coverage.sql`)

* [ ] Ops:
  * [ ] `mart.fact_inventory_snapshot_daily`
  * [ ] `mart.fact_shipments_daily`
  * [ ] `mart.fact_sku_distribution_status_daily`

* [ ] HR:
  * [ ] `mart.fact_labor_daily` (verify)
  * [ ] `mart.fact_timeclock_punches`
  * [ ] `mart.fact_labor_daily_employee`
  * [ ] `mart.dim_employee`

* [ ] Finance:
  * [ ] `mart.fact_actuals_monthly`

### KPIs (one canonical definition per KPI)

* [ ] Ensure there is **exactly one** canonical definition of:
  * [ ] `mart.kpi_sales_per_labor_hour_daily`

* [ ] Ops KPIs:
  * [ ] `mart.kpi_instock_rate_daily`
  * [ ] `mart.kpi_days_of_supply`

* [ ] Finance KPIs (optional, depending on data availability):
  * [ ] `mart.kpi_gross_margin_daily`
  * [ ] `mart.kpi_roi_monthly`
  * [ ] `mart.kpi_breakeven_monthly`

### Controls + Recon (Phase 4 guardrails)

* [ ] Implement controls:

  * [ ] `mart.controls_rowcounts_daily`
  * [ ] `mart.controls_missing_dim_joins`
* [ ] Implement recon:

  * [ ] `mart.recon_sales_distributor_vs_pos`
  * [ ] `mart.recon_sales_to_gl_monthly` (only if finance actuals exist)
* [ ] Add a unified dashboard view (optional but strong):

  * [ ] `mart.controls_command_center`

### Mart orchestration + QA

* [ ] Update `sql/mart/_build_mart.sql` to match real folder paths + run order
* [ ] Run mart QA suite:

  * [ ] `sql/_qa/mart/qa_mart.sql`
  * [ ] `sql/_qa/mart/qa_mart_dims.sql`
  * [ ] `sql/_qa/recon/qa_recon.sql`

## Phase 5 — Validation (SQL)

* [ ] Implement `sql/validation/reconciliation_checks.sql`
* [ ] Implement `sql/validation/semantic_model_test_queries.sql`
* [ ] Add fail-fast checks for:

  * [ ] freshness (latest drop date per source)
  * [ ] grain uniqueness per mart fact
  * [ ] recon tolerances (POS vs distributor, sales vs GL)

## Phase 6 — Power BI semantic model

* [ ] Define star schema relationships (dims → facts)
* [ ] Create measures:

  * [ ] Net Sales, Gross Sales, Units, Orders
  * [ ] Labor Hours, Sales/Labor Hour
  * [ ] In-stock %, Days of Supply
  * [ ] Gross Margin (where COGS exists)

## Phase 7 — Report page architecture

* [ ] Executive overview (KPIs + trends)
* [ ] Sales performance (store/sku/channel)
* [ ] Inventory health (instock + DOS)
* [ ] Labor efficiency (sales/labor hour, staffing trends)
* [ ] Reconciliation / data trust page (controls + recon)

## Phase 8 — Narrative tooltips (plain-English DAX)

* [ ] Tooltips explaining KPI definitions + caveats (POS vs distributor coverage, COGS availability)
* [ ] “Why is this number missing?” tooltips (missing joins, missing source drops)

## Phase 9 — Deployment (portfolio-ready)

* [ ] One-command rebuild instructions (`docs/00_getting_started.md`)
* [ ] Add screenshots of key dashboards
* [ ] Clean README: architecture diagram + data lineage + QA story
* [ ] Final “portfolio polish” commits

---

## Cross-cutting maintenance checklists

### Resolve all 0-byte SQL files (implement or delete/retire)

* [ ] INT:

  * [ ] `int_coverage_conformed`
  * [ ] `int_dispensary_standardized`
* [ ] MART Sales:

  * [ ] `fact_sales_pos_daily`
  * [ ] `fact_sales_daily`
  * [ ] `agg_sales_store_daily`
  * [ ] `_fact_distribution_coverage`
* [ ] MART Ops:

  * [ ] `fact_inventory_snapshot_daily`
  * [ ] `fact_shipments_daily`
  * [ ] `fact_sku_distribution_status_daily`
  * [ ] `kpi_instock_rate_daily`
  * [ ] `kpi_days_of_supply`
  * [ ] `kpi_sales_per_labor_hour_daily`
* [ ] MART Finance:

  * [ ] `fact_actuals_monthly`
  * [ ] `kpi_gross_margin_daily`
  * [ ] `recon_sales_to_gl_monthly`
  * [ ] `roi_`
  * [ ] `breakeven_`
* [ ] MART HR:

  * [ ] `dim_employee`
  * [ ] `fact_timeclock_punches`
  * [ ] `fact_labor_daily_employee`

### Resolve comment-only stubs (implement or remove)

* [ ] `int/sales/int_sales_conformed.sql`
* [ ] `int/ops/int_inventory_conformed.sql`
* [ ] `int/hr/int_labor_conformed.sql`
* [ ] `mart/core/dim_channel.sql`
* [ ] `mart/controls/mart_reconciliation_controls.sql`
* [ ] `validation/reconciliation_checks.sql`
* [ ] `validation/semantic_model_test_queries.sql`

### Mart “spine order” build plan (so you don’t get lost)

* [ ] Build in order:

  * [ ] `fact_sales_pos_daily`
  * [ ] `fact_sales_daily`
  * [ ] `fact_inventory_snapshot_daily`
  * [ ] `kpi_instock_rate_daily`
  * [ ] `kpi_days_of_supply`
  * [ ] then Finance + HR extras

---
