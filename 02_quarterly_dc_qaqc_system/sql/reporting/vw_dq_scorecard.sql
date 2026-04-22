-- sql/reporting/vw_dq_scorecard.sql
-- Quarterly Data Collection + QA/QC System
-- Purpose: expose latest DQ scorecard results for reporting and dashboard use

create schema if not exists reporting;

create or replace view reporting.vw_dq_scorecard as
with latest_run_per_quarter as (
    select
        quarter_id,
        max(run_id) as run_id
    from dq.dq_run_log
    group by quarter_id
)
select
    rf.run_id,
    rf.quarter_id,
    rf.rule_id,
    dr.rule_name,
    dr.rule_category,
    dr.severity,
    dr.owner_team,
    rf.target_table,
    rf.checked_count,
    rf.failed_count,
    rf.failed_pct,
    rf.status,
    rf.created_at
from dq.dq_results_fact rf
join dq.dq_rules dr
  on rf.rule_id = dr.rule_id
join latest_run_per_quarter lr
  on rf.run_id = lr.run_id
 and rf.quarter_id = lr.quarter_id;