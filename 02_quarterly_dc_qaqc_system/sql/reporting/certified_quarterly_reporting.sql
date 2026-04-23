-- sql/reporting/certified_quarterly_reporting.sql
-- Quarterly Data Collection + QA/QC System
-- Purpose: expose quarter-level certification status for reporting readiness

create schema if not exists reporting;

create or replace view reporting.certified_quarterly_reporting as
with latest_run_per_quarter as (
    select
        quarter_id,
        max(run_id) as run_id
    from dq.dq_run_log
    group by quarter_id
),
latest_run_status as (
    select
        rl.quarter_id,
        rl.run_id,
        dl.run_status,
        dl.run_ts
    from latest_run_per_quarter rl
    join dq.dq_run_log dl
      on rl.run_id = dl.run_id
),
open_exception_summary as (
    select
        quarter_id,
        run_id,
        count(*) as open_exception_count,
        count(*) filter (where severity = 'critical') as open_critical_exception_count
    from reporting.vw_open_exceptions
    group by quarter_id, run_id
),
recon_summary as (
    select
        quarter_id,
        run_id,
        max(status) as reconciliation_status
    from reporting.vw_reconciliation_summary
    group by quarter_id, run_id
)
select
    lrs.quarter_id,
    lrs.run_id,
    lrs.run_status,
    lrs.run_ts,
    coalesce(oes.open_exception_count, 0) as open_exception_count,
    coalesce(oes.open_critical_exception_count, 0) as open_critical_exception_count,
    coalesce(rs.reconciliation_status, 'not_run') as reconciliation_status,
    case
        when lrs.run_status <> 'completed' then 'hold'
        when coalesce(rs.reconciliation_status, 'not_run') <> 'pass' then 'hold'
        when coalesce(oes.open_critical_exception_count, 0) > 0 then 'hold'
        else 'certified'
    end as certification_status,
    case
        when lrs.run_status <> 'completed' then 'latest dq run not completed'
        when coalesce(rs.reconciliation_status, 'not_run') <> 'pass' then 'reconciliation failed or not run'
        when coalesce(oes.open_critical_exception_count, 0) > 0 then 'open critical exceptions remain'
        else 'ready for reporting'
    end as certification_reason
from latest_run_status lrs
left join open_exception_summary oes
  on lrs.quarter_id = oes.quarter_id
 and lrs.run_id = oes.run_id
left join recon_summary rs
  on lrs.quarter_id = rs.quarter_id
 and lrs.run_id = rs.run_id;