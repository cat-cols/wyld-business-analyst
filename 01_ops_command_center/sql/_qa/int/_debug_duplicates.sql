\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '------------------------------'
\echo ' INT: DUPLICATE KEY TRIAGE'
\echo '------------------------------'
\echo 'These queries LIST offenders (they do not fail the run).'
\echo ''

-- dispensary duplicates
\echo ''
\echo '>> Duplicates: int.int_dispensary_latest (store_code)'
select store_code, count(*) as n
from int.int_dispensary_latest
group by 1
having count(*) > 1
order by n desc, store_code;

-- account status duplicates
\echo ''
\echo '>> Duplicates: int.int_account_status_current (store_code)'
select store_code, count(*) as n
from int.int_account_status_current
group by 1
having count(*) > 1
order by n desc, store_code;

-- sales dedup duplicates at grain
\echo ''
\echo '>> Duplicates: int.int_sales_distributor_dedup (sale_date, store_code, sku, channel)'
select sale_date, store_code, sku, channel, count(*) as n
from int.int_sales_distributor_dedup
group by 1,2,3,4
having count(*) > 1
order by n desc, sale_date desc, store_code, sku, channel;

-- punches duplicates by punch_id
\echo ''
\echo '>> Duplicates: int.int_timeclock_punches_latest (punch_id)'
select punch_id, count(*) as n
from int.int_timeclock_punches_latest
where punch_id is not null
group by 1
having count(*) > 1
order by n desc, punch_id;

-- punches duplicates by punch_key
\echo ''
\echo '>> Duplicates: int.int_timeclock_punches_latest (punch_key)'
select
  coalesce(punch_id::text, store_code || '|' || employee_id || '|' || clock_in_at::text) as punch_key,
  count(*) as n
from int.int_timeclock_punches_latest
group by 1
having count(*) > 1
order by n desc, punch_key;

-- Helpful drill-down: show sample rows for punch_key duplicates
\echo ''
\echo '>> Sample rows for duplicated punch_key (limit 200)'
with dup_keys as (
  select
    coalesce(punch_id::text, store_code || '|' || employee_id || '|' || clock_in_at::text) as punch_key
  from int.int_timeclock_punches_latest
  group by 1
  having count(*) > 1
)
select
  p.store_code,
  p.employee_id,
  p.punch_id,
  p.clock_in_at,
  p.clock_out_at,
  p.minutes_worked,
  p.drop_date,
  p.ingested_at,
  coalesce(p.punch_id::text, p.store_code || '|' || p.employee_id || '|' || p.clock_in_at::text) as punch_key
from int.int_timeclock_punches_latest p
join dup_keys d
  on d.punch_key = coalesce(p.punch_id::text, p.store_code || '|' || p.employee_id || '|' || p.clock_in_at::text)
order by p.store_code, p.employee_id, p.clock_in_at, p.ingested_at desc
limit 200;