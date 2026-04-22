-- sql/reporting/vw_reconciliation_summary.sql
-- Quarterly Data Collection + QA/QC System
-- Purpose: expose latest reconciliation results for reporting and dashboard use

create schema if not exists reporting;

create or replace view reporting.vw_reconciliation_summary as
with latest_run_per_quarter as (
    select
        quarter_id,
        max(run_id) as run_id
    from dq.dq_run_log
    group by quarter_id
)
select
    rr.run_id,
    rr.quarter_id,
    rr.recon_name,
    rr.left_source,
    rr.right_source,
    rr.metric_name,
    rr.left_value,
    rr.right_value,
    rr.variance_value,
    rr.variance_pct,
    rr.tolerance_pct,
    rr.status,
    rr.created_at
from dq.recon_results rr
join latest_run_per_quarter lr
  on rr.run_id = lr.run_id
 and rr.quarter_id = lr.quarter_id;