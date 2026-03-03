\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '=============================='
\echo ' QA: MART DIMENSIONS (hard-fail)'
\echo ' Models: mart.dim_date, mart.dim_sku'
\echo '=============================='
\echo ''

do $$
declare
  v bigint;
  rel regclass;
begin
  -- ----------------------------
  -- Existence checks
  -- ----------------------------
  rel := to_regclass('mart.dim_date');
  if rel is null then
    raise exception 'QA FAIL: missing relation mart.dim_date';
  end if;

  rel := to_regclass('mart.dim_sku');
  if rel is null then
    raise exception 'QA FAIL: missing relation mart.dim_sku';
  end if;

  -- ----------------------------
  -- mart.dim_date
  -- ----------------------------
  select count(*) into v from mart.dim_date;
  if v = 0 then
    raise exception 'QA FAIL: mart.dim_date has 0 rows (date spine not generated)';
  end if;

  select count(*) into v from (
    select date_day
    from mart.dim_date
    group by 1
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: mart.dim_date has % duplicate date_day values', v;
  end if;

  -- ----------------------------
  -- mart.dim_sku
  -- ----------------------------
  select count(*) into v from mart.dim_sku;
  if v = 0 then
    raise exception 'QA FAIL: mart.dim_sku has 0 rows (sku universe not generated)';
  end if;

  select count(*) into v from (
    select sku
    from mart.dim_sku
    group by 1
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: mart.dim_sku has % duplicate sku values', v;
  end if;

  select count(*) into v
  from mart.dim_sku
  where sku is null;

  if v > 0 then
    raise exception 'QA FAIL: mart.dim_sku has % rows with NULL sku', v;
  end if;

end $$;

\echo '✅ PASS: mart dimension contracts'