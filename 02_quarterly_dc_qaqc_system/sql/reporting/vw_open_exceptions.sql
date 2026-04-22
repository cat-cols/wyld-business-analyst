-- sql/reporting/vw_open_exceptions.sql
-- Quarterly Data Collection + QA/QC System
-- Purpose: expose latest open DQ exceptions for remediation and dashboard use

create schema if not exists reporting;

create or replace view reporting.vw_open_exceptions as
with latest_run_per_quarter as (
    select
        quarter_id,
        max(run_id) as run_id
    from dq.dq_run_log
    group by quarter_id
)
select
    ed.run_id,
    ed.quarter_id,
    ed.rule_id,
    dr.rule_name,
    dr.rule_category,
    dr.severity,
    dr.owner_team,
    ed.target_table,
    ed.record_key,
    ed.issue_value,
    ed.issue_description,
    ed.assigned_team,
    ed.remediation_status,
    ed.comment,
    ed.created_at,
    ed.resolved_at
from dq.dq_exceptions_detail ed
join dq.dq_rules dr
  on ed.rule_id = dr.rule_id
join latest_run_per_quarter lr
  on ed.run_id = lr.run_id
 and ed.quarter_id = lr.quarter_id
where ed.remediation_status = 'open';