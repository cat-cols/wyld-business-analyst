\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '------------------------------'
\echo ' INT: TRUTH UNIQUENESS CHECKS'
\echo '------------------------------'

do $$
declare
  v   int;
  rel regclass;
begin
  -- 1) int.int_dispensary_latest unique on store_code
  rel := to_regclass('int.int_dispensary_latest');
  if rel is null then
    raise exception 'QA FAIL: missing relation int.int_dispensary_latest';
  end if;

  select count(*) into v from (
    select store_code
    from int.int_dispensary_latest
    group by 1
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: int.int_dispensary_latest has % duplicate store_code values', v;
  end if;


  -- 2) int.int_account_status_current unique on store_code
  rel := to_regclass('int.int_account_status_current');
  if rel is null then
    raise exception 'QA FAIL: missing relation int.int_account_status_current';
  end if;

  select count(*) into v from (
    select store_code
    from int.int_account_status_current
    group by 1
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: int.int_account_status_current has % duplicate store_code values', v;
  end if;


  -- 3) int.int_sales_distributor_dedup unique on (sale_date, store_code, sku, channel)
  rel := to_regclass('int.int_sales_distributor_dedup');
  if rel is null then
    raise exception 'QA FAIL: missing relation int.int_sales_distributor_dedup';
  end if;

  select count(*) into v from (
    select sale_date, store_code, sku, channel
    from int.int_sales_distributor_dedup
    group by 1,2,3,4
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception
      'QA FAIL: int.int_sales_distributor_dedup has % duplicate rows at (sale_date, store_code, sku, channel)', v;
  end if;


  -- 4) int.int_timeclock_punches_latest unique on punch_id (when present) OR natural key
  rel := to_regclass('int.int_timeclock_punches_latest');
  if rel is null then
    raise exception 'QA FAIL: missing relation int.int_timeclock_punches_latest';
  end if;

  -- 4a) punch_id duplicates (ignore NULL punch_id)
  select count(*) into v from (
    select punch_id
    from int.int_timeclock_punches_latest
    where punch_id is not null
    group by 1
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: int.int_timeclock_punches_latest has % duplicate punch_id values', v;
  end if;

  -- 4b) natural punch key duplicates (covers NULL punch_id rows too)
  select count(*) into v from (
    select
      coalesce(punch_id::text, store_code || '|' || employee_id || '|' || clock_in_at::text) as punch_key
    from int.int_timeclock_punches_latest
    group by 1
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: int.int_timeclock_punches_latest has % duplicate punch_key values', v;
  end if;

end $$;

\echo '✅ PASS: INT truth uniqueness'