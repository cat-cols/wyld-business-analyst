-- ============================================================
-- Project 4 QA persistence tables
-- ============================================================

create table if not exists qa.qa_run_history (
    run_id text primary key,
    pipeline_name text not null,
    run_started_at timestamp not null,
    run_completed_at timestamp,
    run_status text not null,
    notes text
);

create table if not exists qa.materiality_thresholds (
    control_name text primary key,
    warning_row_threshold integer,
    failure_row_threshold integer,
    warning_pct_threshold numeric(12, 6),
    failure_pct_threshold numeric(12, 6),
    severity text not null,
    notes text
);

create table if not exists qa.source_owner_certifications (
    source_system text primary key,
    owner_team text not null,
    certifier_name text,
    certification_status text not null,
    certified_through date,
    last_certified_at timestamp,
    notes text
);

create table if not exists qa.exception_resolution_log (
    exception_id text primary key,
    exception_type text not null,
    source_system text not null,
    evidence_reference text,
    activity_month date,
    facility_id text,
    product_line_id text,
    resolution_status text not null,
    owner_team text,
    resolution_notes text,
    created_at timestamp not null default clock_timestamp(),
    resolved_at timestamp
);

insert into qa.materiality_thresholds (
    control_name,
    warning_row_threshold,
    failure_row_threshold,
    warning_pct_threshold,
    failure_pct_threshold,
    severity,
    notes
)
values
    ('duplicate_source_records', 1, null, 0.010000, 0.100000, 'high', 'Warn when duplicate rows exist; fail if duplicates exceed 10% of fact rows.'),
    ('non_reportable_rows', 1, null, 0.050000, 0.200000, 'high', 'Warn when non-reportable rows exceed 5%; fail above 20%.'),
    ('missing_factor_joins', 1, null, 0.001000, 0.050000, 'critical', 'Missing factor joins affect emissions completeness.'),
    ('negative_activity_rows', 1, null, 0.001000, 0.050000, 'high', 'Negative activity rows require source review.'),
    ('unknown_activity_type_rows', 1, null, 0.001000, 0.050000, 'high', 'Unknown activity types cannot be calculated safely.'),
    ('missing_dimension_joins', 1, null, 0.001000, 0.100000, 'high', 'Missing facility/product joins reduce reporting detail.')
on conflict (control_name) do update
set
    warning_row_threshold = excluded.warning_row_threshold,
    failure_row_threshold = excluded.failure_row_threshold,
    warning_pct_threshold = excluded.warning_pct_threshold,
    failure_pct_threshold = excluded.failure_pct_threshold,
    severity = excluded.severity,
    notes = excluded.notes;

insert into qa.source_owner_certifications (
    source_system,
    owner_team,
    certifier_name,
    certification_status,
    certified_through,
    last_certified_at,
    notes
)
values
    ('electricity_bills', 'Facilities / Sustainability', 'Synthetic Source Owner', 'certified', '2026-12-31', clock_timestamp(), 'Synthetic source certified for portfolio QA demonstration.'),
    ('fuel_usage', 'Operations / Sustainability', 'Synthetic Source Owner', 'certified', '2026-12-31', clock_timestamp(), 'Synthetic source certified for portfolio QA demonstration.'),
    ('shipping_miles', 'Logistics', 'Synthetic Source Owner', 'certified', '2026-12-31', clock_timestamp(), 'Synthetic source certified for portfolio QA demonstration.'),
    ('packaging_materials', 'Procurement', 'Synthetic Source Owner', 'certified', '2026-12-31', clock_timestamp(), 'Synthetic source certified for portfolio QA demonstration.')
on conflict (source_system) do update
set
    owner_team = excluded.owner_team,
    certifier_name = excluded.certifier_name,
    certification_status = excluded.certification_status,
    certified_through = excluded.certified_through,
    last_certified_at = excluded.last_certified_at,
    notes = excluded.notes;
