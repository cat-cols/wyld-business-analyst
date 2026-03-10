# Reporting Calendar — Project 1

This file documents the intended operating rhythm for refresh, validation, and executive review of the Ops Command Center.

| Frequency | Activity | Primary Assets | Purpose |
|---|---|---|---|
| Daily (simulated) | Ingest latest source drops and rebuild staging / INT / MART layers | source extracts, raw / stg / int / mart SQL | Keep operational facts and controls current |
| Daily (simulated) | Run QA + reconciliation checks | `sql/_qa/_run_qa.sql`, `validation.reconciliation_checks` | Catch drift, duplicates, missing joins, and recon deltas early |
| Weekly | Review KPI movement and trust controls | report pages, controls, recon views | Identify operational issues and data-trust concerns before executive review |
| Weekly | Publish dashboard refresh notes | semantic-model docs, refresh notes, reconciliation log | Leave an audit trail of what changed and what is still weird |
| Monthly | Executive walkthrough | `docs/executive_walkthrough.md`, KPI snapshots, reconciliations | Summarize performance, controls, caveats, and actions |
| Monthly | Finance / ops reconciliation review | `mart.recon_sales_to_gl_monthly`, `reconciliation_log.md` | Review explainable differences between modeled operational truth and finance-style actuals |

## Notes
- In a live environment, freshness expectations should be based on each source system’s SLA.
- In this portfolio project, daily / weekly / monthly cadences are simulated to mirror a more realistic reporting operation.
