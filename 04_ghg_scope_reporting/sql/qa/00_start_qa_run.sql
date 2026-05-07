-- ============================================================
-- Start QA run
-- ============================================================

select
    md5(clock_timestamp()::text || random()::text) as run_id
\gset

insert into qa.qa_run_history (
    run_id,
    pipeline_name,
    run_started_at,
    run_status,
    notes
)
values (
    :'run_id',
    'project4_ghg_scope_reporting',
    clock_timestamp(),
    'running',
    'QA run started from sql/qa/_run_qa.sql'
);

\echo 'QA run_id: ' :run_id
