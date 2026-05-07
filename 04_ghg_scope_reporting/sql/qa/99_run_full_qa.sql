-- ============================================================
-- Complete QA run
-- ============================================================

update qa.qa_run_history
set
    run_completed_at = clock_timestamp(),
    run_status = 'passed',
    notes = 'QA run completed successfully'
where run_id = :'run_id';

select
    run_id,
    pipeline_name,
    run_started_at,
    run_completed_at,
    run_status,
    notes
from qa.qa_run_history
where run_id = :'run_id';