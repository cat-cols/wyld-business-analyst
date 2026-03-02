-- 01_ops_command_center/sql/staging/checks/qa_checks.sql
-- Phase 2 QA checks for raw + stg pipeline.
--
-- Goals:
-- 1) Existence checks for required raw tables + stg views
-- 2) Rowcount checks (must be > 0)
-- 3) Light quality checks on common flag columns when present
-- 4) Print results + persist a copy into qa.qa_results for later review
-- 5) Hard-fail if any FAIL-severity checks fail

-- old?
-- 1. Do row counts exist for each staging model?
-- 2. What % of rows are flagged?
-- 3. Are the keys usable (how many null keys)?
-- 4. Are there unexpected channel/team/metric values?

-- Example checks:
-- row counts per model
-- avg(flag::int) per flag
-- top 20 unknown KPI categories
-- distinct channels list

\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '=============================='
\echo ' QA CHECKS: raw + stg'
\echo '=============================='
\echo ''

-- Persistent store (so you can query results after the session)
create schema if not exists qa;

drop table if exists qa.qa_results;

create table qa.qa_results (
  check_group text,
  severity text,
  status text,
  check_name text,
  metric numeric,
  threshold numeric,
  details text,
  checked_at timestamp default now()
);

begin;

-- Temp working table for this run (dies on commit)
drop table if exists pg_temp.qa_results;

create temp table qa_results (
  check_group text not null,
  check_name  text not null,
  severity    text not null,       -- FAIL | WARN | INFO
  metric      numeric,
  threshold   numeric,
  passed      boolean not null,
  details     text
) on commit drop;

-- ------------------------------------------------------------
-- 1) Existence + rowcount checks for required objects
-- ------------------------------------------------------------
do $$
declare
  req text[];
  obj text;
  rc regclass;
  n bigint;
begin
  req := array[
    -- raw tables
    'raw.sales_distributor_extract',
    'raw.pos_transactions_csv',
    'raw.inventory_erp_snapshot',
    'raw.wms_shipments',
    'raw.timeclock_punches',
    'raw.labor_hours_payroll_export',
    'raw.finance_actuals_summary',
    'raw.gl_detail_csv',
    'raw.account_status',
    'raw.dispensary_master',
    'raw.sku_distribution_status',

    -- staging views
    'stg.stg_sales_distributor',
    'stg.stg_inventory_erp',
    'stg.stg_labor_payroll',
    'stg.stg_finance_actuals',
    'stg.stg_account_status',
    'stg.stg_dispensary_master',
    'stg.stg_sku_distribution_status',
    'stg.stg_pos_transactions',
    'stg.stg_wms_shipments',
    'stg.stg_timeclock_punches'
  ];

  foreach obj in array req loop
    rc := to_regclass(obj);

    insert into qa_results(check_group, check_name, severity, metric, threshold, passed, details)
    values ('existence', obj, 'FAIL', null, null, (rc is not null),
            case when rc is null then 'missing object' else 'ok' end);

    if rc is not null then
      execute format('select count(*) from %s', rc) into n;

      insert into qa_results(check_group, check_name, severity, metric, threshold, passed, details)
      values ('rowcount', obj, 'FAIL', n, 1, (n > 0),
              case when n > 0 then 'ok' else '0 rows' end);
    end if;
  end loop;
end $$;

-- ------------------------------------------------------------
-- 2) Quality checks for common flag columns if present
-- ------------------------------------------------------------
do $$
declare
  v_schema text;
  v_name   text;
  fq       text;
  total_n  bigint;

  missing_n bigint;
  dup_n     bigint;
  bad_amt_n bigint;
  bad_state_n bigint;
  bad_postal_n bigint;

  missing_rate numeric;
  dup_rate numeric;
  bad_amt_rate numeric;
  bad_state_rate numeric;
  bad_postal_rate numeric;

  col_exists boolean;

  -- thresholds (tune later)
  th_missing numeric := 0.10;   -- 10% missing keys -> WARN
  th_dups    numeric := 0.05;   -- 5% duplicates -> WARN
  th_bad_amt numeric := 0.03;   -- 3% bad amount -> WARN
  th_bad_state numeric := 0.01; -- 1% bad state -> WARN
  th_bad_postal numeric := 0.05;-- 5% bad postal -> WARN
begin
  for v_schema, v_name in
    select * from (values
      ('stg','stg_sales_distributor'),
      ('stg','stg_inventory_erp'),
      ('stg','stg_labor_payroll'),
      ('stg','stg_finance_actuals'),
      ('stg','stg_account_status'),
      ('stg','stg_dispensary_master'),
      ('stg','stg_sku_distribution_status')
    ) as t(s, n)
  loop
    fq := format('%I.%I', v_schema, v_name);

    if to_regclass(fq) is null then
      continue;
    end if;

    execute format('select count(*) from %s', fq) into total_n;
    if total_n = 0 then
      continue;
    end if;

    -- is_missing_key
    select exists (
      select 1 from information_schema.columns
      where table_schema = v_schema and table_name = v_name and column_name = 'is_missing_key'
    ) into col_exists;

    if col_exists then
      execute format('select count(*) filter (where is_missing_key) from %s', fq) into missing_n;
      missing_rate := missing_n::numeric / total_n::numeric;

      insert into qa_results(check_group, check_name, severity, metric, threshold, passed, details)
      values ('quality', fq || '.is_missing_key_rate', 'WARN', missing_rate, th_missing,
              (missing_rate <= th_missing),
              format('missing=%s total=%s', missing_n, total_n));
    end if;

    -- is_duplicate_candidate
    select exists (
      select 1 from information_schema.columns
      where table_schema = v_schema and table_name = v_name and column_name = 'is_duplicate_candidate'
    ) into col_exists;

    if col_exists then
      execute format('select count(*) filter (where is_duplicate_candidate) from %s', fq) into dup_n;
      dup_rate := dup_n::numeric / total_n::numeric;

      insert into qa_results(check_group, check_name, severity, metric, threshold, passed, details)
      values ('quality', fq || '.is_duplicate_candidate_rate', 'WARN', dup_rate, th_dups,
              (dup_rate <= th_dups),
              format('dups=%s total=%s', dup_n, total_n));
    end if;

    -- is_bad_amount
    select exists (
      select 1 from information_schema.columns
      where table_schema = v_schema and table_name = v_name and column_name = 'is_bad_amount'
    ) into col_exists;

    if col_exists then
      execute format('select count(*) filter (where is_bad_amount) from %s', fq) into bad_amt_n;
      bad_amt_rate := bad_amt_n::numeric / total_n::numeric;

      insert into qa_results(check_group, check_name, severity, metric, threshold, passed, details)
      values ('quality', fq || '.is_bad_amount_rate', 'WARN', bad_amt_rate, th_bad_amt,
              (bad_amt_rate <= th_bad_amt),
              format('bad_amount=%s total=%s', bad_amt_n, total_n));
    end if;

    -- is_bad_state_code
    select exists (
      select 1 from information_schema.columns
      where table_schema = v_schema and table_name = v_name and column_name = 'is_bad_state_code'
    ) into col_exists;

    if col_exists then
      execute format('select count(*) filter (where is_bad_state_code) from %s', fq) into bad_state_n;
      bad_state_rate := bad_state_n::numeric / total_n::numeric;

      insert into qa_results(check_group, check_name, severity, metric, threshold, passed, details)
      values ('quality', fq || '.is_bad_state_code_rate', 'WARN', bad_state_rate, th_bad_state,
              (bad_state_rate <= th_bad_state),
              format('bad_state=%s total=%s', bad_state_n, total_n));
    end if;

    -- is_bad_postal_code
    select exists (
      select 1 from information_schema.columns
      where table_schema = v_schema and table_name = v_name and column_name = 'is_bad_postal_code'
    ) into col_exists;

    if col_exists then
      execute format('select count(*) filter (where is_bad_postal_code) from %s', fq) into bad_postal_n;
      bad_postal_rate := bad_postal_n::numeric / total_n::numeric;

      insert into qa_results(check_group, check_name, severity, metric, threshold, passed, details)
      values ('quality', fq || '.is_bad_postal_code_rate', 'WARN', bad_postal_rate, th_bad_postal,
              (bad_postal_rate <= th_bad_postal),
              format('bad_postal=%s total=%s', bad_postal_n, total_n));
    end if;

  end loop;
end $$;

-- ------------------------------------------------------------
-- 3) Print results
-- ------------------------------------------------------------
\echo ''
\echo '--- QA RESULTS ---'
select
  check_group,
  severity,
  case when passed then 'PASS' else 'FAIL' end as status,
  check_name,
  metric,
  threshold,
  details
from qa_results
order by
  (case severity when 'FAIL' then 1 when 'WARN' then 2 else 3 end),
  passed asc,
  check_group,
  check_name;

\echo ''
\echo '--- QA SUMMARY ---'
select
  severity,
  count(*) as checks,
  sum(case when passed then 1 else 0 end) as passed,
  sum(case when passed then 0 else 1 end) as failed
from qa_results
group by severity
order by (case severity when 'FAIL' then 1 when 'WARN' then 2 else 3 end);

-- ------------------------------------------------------------
-- 4) Persist a copy of this run into qa.qa_results
-- ------------------------------------------------------------
insert into qa.qa_results(check_group, severity, status, check_name, metric, threshold, details)
select
  check_group,
  severity,
  case when passed then 'PASS' else 'FAIL' end as status,
  check_name,
  metric,
  threshold,
  details
from qa_results;

-- ------------------------------------------------------------
-- 5) Hard fail if any FAIL-severity checks failed
-- ------------------------------------------------------------
do $$
declare
  n_fail int;
begin
  select count(*) into n_fail
  from qa_results
  where severity = 'FAIL' and passed = false;

  if n_fail > 0 then
    raise exception 'QA checks failed: % FAIL-severity checks failed. See QA RESULTS above.', n_fail;
  else
    raise notice 'QA checks passed (no FAIL-severity failures).';
  end if;
end $$;

commit;