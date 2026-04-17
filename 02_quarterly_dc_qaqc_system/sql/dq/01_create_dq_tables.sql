-- sql/dq/01_create_dq_tables.sql

-- Quarterly Data Collection + QA/QC System
-- Purpose: create core DQ framework tables for governed quarterly validation

-- 1) Governed rules catalog
create table if not exists dq.dq_rules (
    rule_id               bigint generated always as identity primary key,
    rule_name             text not null,
    rule_category         text not null,
    target_table          text not null,
    target_column         text,
    severity              text not null,
    threshold_pct         numeric(8,4),
    logic_description     text not null,
    business_rationale    text,
    owner_team            text,
    active_flag           boolean not null default true,
    effective_start_date  date not null default current_date,
    effective_end_date    date,
    created_at            timestamp not null default current_timestamp,

    constraint chk_dq_rules_category
        check (rule_category in ('completeness', 'uniqueness', 'validity', 'timeliness', 'reconciliation')),

    constraint chk_dq_rules_severity
        check (severity in ('critical', 'high', 'medium', 'low'))
);


-- 2) Validation run header
create table if not exists dq.dq_run_log (
    run_id             bigint generated always as identity primary key,
    quarter_id         text not null,
    run_ts             timestamp not null default current_timestamp,
    run_by             text,
    source_batch_name  text,
    rules_version      text,
    run_status         text not null default 'started',
    created_at         timestamp not null default current_timestamp,

    constraint chk_dq_run_log_status
        check (run_status in ('started', 'completed', 'failed'))
);

-- 3) Rule-level summary results
create table if not exists dq.dq_results_fact (
    run_id          bigint not null references dq.dq_run_log(run_id),
    quarter_id      text not null,
    rule_id         bigint not null references dq.dq_rules(rule_id),
    target_table    text not null,
    checked_count   bigint not null,
    failed_count    bigint not null,
    failed_pct      numeric(8,4) not null,
    severity        text not null,
    status          text not null,
    created_at      timestamp not null default current_timestamp,

    constraint chk_dq_results_fact_status
        check (status in ('pass', 'warn', 'fail')),

    constraint chk_dq_results_fact_counts
        check (
            checked_count >= 0
            and failed_count >= 0
            and failed_count <= checked_count
        ),

    constraint chk_dq_results_fact_pct
        check (failed_pct >= 0 and failed_pct <= 1),

    constraint chk_dq_results_fact_severity
        check (severity in ('critical', 'high', 'medium', 'low'))
);

-- 4) Record-level exceptions
create table if not exists dq.dq_exceptions_detail (
    run_id               bigint not null references dq.dq_run_log(run_id),
    quarter_id           text not null,
    rule_id              bigint not null references dq.dq_rules(rule_id),
    target_table         text not null,
    record_key           text not null,
    issue_value          text,
    issue_description    text not null,
    assigned_team        text,
    remediation_status   text not null default 'open',
    comment              text,
    created_at           timestamp not null default current_timestamp,
    resolved_at          timestamp,

    constraint chk_dq_exceptions_detail_status
        check (remediation_status in ('open', 'in_progress', 'resolved', 'waived'))
);

-- 5) Cross-source reconciliation results
create table if not exists dq.recon_results (
    run_id          bigint not null references dq.dq_run_log(run_id),
    quarter_id      text not null,
    recon_name      text not null,
    left_source     text not null,
    right_source    text not null,
    metric_name     text not null,
    left_value      numeric(18,2),
    right_value     numeric(18,2),
    variance_value  numeric(18,2),
    variance_pct    numeric(8,4),
    tolerance_pct   numeric(8,4),
    status          text not null,
    created_at      timestamp not null default current_timestamp,

    constraint chk_recon_results_status
        check (status in ('pass', 'warn', 'fail'))
);

-- 6) indexes
create index if not exists ix_dq_results_fact_run_id
    on dq.dq_results_fact (run_id);

create index if not exists ix_dq_results_fact_rule_id
    on dq.dq_results_fact (rule_id);

create index if not exists ix_dq_exceptions_detail_run_id
    on dq.dq_exceptions_detail (run_id);

create index if not exists ix_dq_exceptions_detail_rule_id
    on dq.dq_exceptions_detail (rule_id);

create index if not exists ix_dq_exceptions_detail_status
    on dq.dq_exceptions_detail (remediation_status);

create index if not exists ix_recon_results_run_id
    on dq.recon_results (run_id);

-- enforce uniqueness --
-- data quality results
create unique index if not exists ux_dq_results_fact_run_rule_table
    on dq.dq_results_fact (run_id, rule_id, target_table);

-- reconciliation results
create unique index if not exists ux_recon_results_run_recon_metric
    on dq.recon_results (run_id, recon_name, metric_name);
