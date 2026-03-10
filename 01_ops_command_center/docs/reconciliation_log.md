# Reconciliation Log — Project 1

This log is the human-readable companion to `validation.reconciliation_checks` and the mart-layer reconciliation / control views.

| Refresh Date | Domain | Check | Source Object | Modeled / Compared Object | Tolerance | Current Status | Notes |
|---|---|---|---|---|---:|---|---|
| 2026-03-09 | Sales | Distributor net sales: INT vs MART (same latest common date) | `int.int_sales_distributor_dedup` | `mart.fact_sales_distributor_daily` | 0.00% | Expected Pass | Exact same-day totals should tie once the mart is rebuilt from current INT inputs. |
| 2026-03-09 | Sales | POS net sales: INT vs MART (same latest common date) | `int.int_pos_dedup` | `mart.fact_sales_pos_daily` | 0.00% | Expected Pass | Used to verify POS mart rollup logic has not drifted from deduped INT truth. |
| 2026-03-09 | People | Labor hours: INT vs MART (same latest common date) | `int.int_labor_daily` | `mart.fact_labor_daily` | 0.00% | Expected Pass | Core productivity facts should tie exactly at the day grain. |
| 2026-03-09 | Ops | Inventory on-hand: INT vs MART (same latest common date) | `int.int_inventory_snapshot_dedup` | `mart.fact_inventory_snapshot_daily` | 0.00% | Expected Pass | Snapshot totals should tie exactly after deduplication and standardization. |
| 2026-03-09 | Sales / Ops | Distributor vs POS daily comparison | `mart.fact_sales_distributor_daily` | `mart.fact_sales_pos_daily` via `mart.recon_sales_distributor_vs_pos` | review only | Investigate | This is an operational comparison, not necessarily an exact-match recon. Variance may reflect scope / coverage differences rather than broken logic. |
| 2026-03-09 | Finance | Gross sales: operational sales vs finance actuals | `mart.fact_sales_distributor_daily` / modeled operational truth | `mart.recon_sales_to_gl_monthly` / `mart.fact_actuals_monthly` | 2.00% | Known Fail | January 2025 fails are expected because finance actuals are currently simulated independently from operational truth. |
| 2026-03-09 | Finance | Net sales: operational sales vs finance actuals | `mart.fact_sales_distributor_daily` / modeled operational truth | `mart.recon_sales_to_gl_monthly` / `mart.fact_actuals_monthly` | 2.00% | Known Fail | Same root cause as gross sales: finance simulation is not yet hard-aligned to operational monthly truth. |
| 2026-03-09 | Finance | COGS: modeled vs finance actuals | modeled gross-margin inputs | `mart.recon_sales_to_gl_monthly` / `mart.fact_actuals_monthly` | 2.00% | Known Fail | A good future upgrade is to derive finance actuals from the operational facts to create a clean explainable bridge. |
| 2026-03-09 | Finance | Gross margin: modeled vs finance actuals | modeled gross-margin inputs | `mart.recon_sales_to_gl_monthly` / `mart.fact_actuals_monthly` | 2.00% | Known Fail | Fail state is currently informative rather than catastrophic; document as a simulation limitation. |
| 2026-03-09 | Controls | Freshness check by mart object | latest date in source / mart object | `mart.controls_freshness` / validation layer | n/a | Expected Warning | Static simulated data can make freshness look stale even when the pipeline is functioning correctly. |
| 2026-03-09 | Controls | Missing dimension joins | fact rows missing expected conformed dimension matches | `mart.controls_missing_dim_joins` | 0 rows preferred | Monitor | Keep surfacing this as a trust metric on the QA / diagnostics page. |

## How to Use This Log
- Update this file after major QA / reconciliation runs.
- Keep the machine-readable truth in SQL views, then summarize the current state here for humans.
- Treat **Known Fail** and **Expected Warning** states as documented exceptions, not as silent gremlins.

## Best Next Upgrade
Tie the finance actuals generator more directly to the modeled sales / margin truth. That turns the current finance recon from “known fail for explainable reasons” into “clean controlled bridge.”

---