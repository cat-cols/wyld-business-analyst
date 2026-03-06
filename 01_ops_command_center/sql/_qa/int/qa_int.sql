\echo ''
\echo 'INT CHECKS: uniqueness + null keys + ranges'

-- -----------------------
-- Uniqueness (hard fail)
-- -----------------------

do $$
declare v int;
begin
  -- int_dispensary_latest unique store_code
  select count(*) into v from (
    select store_code
    from int.int_dispensary_latest
    group by 1
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: int.int_dispensary_latest has % duplicate store_code values', v;
  end if;

  -- int_account_status_current unique store_code
  select count(*) into v from (
    select store_code
    from int.int_account_status_current
    group by 1
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: int.int_account_status_current has % duplicate store_code values', v;
  end if;

  -- sales dedup grain
  select count(*) into v from (
    select sale_date, store_code, sku, channel
    from int.int_sales_distributor_dedup
    group by 1,2,3,4
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_distributor_dedup has % duplicate rows at (sale_date, store_code, sku, channel)', v;
  end if;

  -- sku distribution status grain
  select count(*) into v from (
    select as_of_date, store_code, sku
    from int.int_sku_distribution_status_dedup
    group by 1,2,3
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: int.int_sku_distribution_status_dedup has % duplicate rows at (as_of_date, store_code, sku)', v;
  end if;
  -- punches latest uniqueness by punch key (event-based)
  select count(*) into v from (
    select
      coalesce(
        punch_id::text,
        store_code || '|' || employee_id::text || '|' || punch_ts::text || '|' || action
      ) as punch_key
    from int.int_timeclock_punches_latest
    group by 1
    having count(*) > 1
  ) t;

  -- punches latest uniqueness by punch key (legacy - kept for reference)
  -- select count(*) into v from (
  --   select
  --     coalesce(punch_id::text, store_code || '|' || employee_id || '|' || clock_in_at::text) as punch_key
  --   from int.int_timeclock_punches_latest
  --   group by 1
  --   having count(*) > 1
  -- ) t;
  if v > 0 then
    raise exception 'QA FAIL: int.int_timeclock_punches_latest has % duplicate punch_key values', v;
  end if;

  -- labor daily grain
  select count(*) into v from (
    select work_date, store_code
    from int.int_labor_daily
    group by 1,2
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: int.int_labor_daily has % duplicate rows at (work_date, store_code)', v;
  end if;

end $$;

-- Optional: employee-grain labor view if present
do $$
declare rel regclass;
declare v int;
begin
  rel := to_regclass('int.int_labor_daily_employee');
  if rel is null then
    raise notice 'SKIP: int.int_labor_daily_employee not present';
    return;
  end if;

  select count(*) into v from (
    select work_date, store_code, employee_id
    from int.int_labor_daily_employee
    group by 1,2,3
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: int.int_labor_daily_employee has % duplicate rows at (work_date, store_code, employee_id)', v;
  end if;
end $$;

-- -----------------------
-- Null keys (hard fail)
-- -----------------------

do $$
declare v int;
begin
  select count(*) into v
  from int.int_sales_distributor_dedup
  where sale_date is null or store_code is null or sku is null or channel is null;

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_distributor_dedup has % rows with null keys', v;
  end if;

  select count(*) into v
  from int.int_labor_daily
  where work_date is null or store_code is null;

  if v > 0 then
    raise exception 'QA FAIL: int.int_labor_daily has % rows with null keys', v;
  end if;
  -- missing-key checks for timeclock punches
  select count(*) into v
  from int.int_timeclock_punches_latest
  where store_code is null
     or employee_id is null
     or punch_ts is null
     or punch_date is null
     or action is null;

  if v > 0 then
    raise exception 'QA FAIL: int.int_timeclock_punches_latest has % rows with null keys', v;
  end if;
end $$;

-- -----------------------
-- Ranges / reasonableness (hard fail on obvious nonsense)
-- -----------------------

do $$
declare v int;
begin
  -- sales negatives
  select count(*) into v
  from int.int_sales_distributor_dedup
  where
    coalesce(qty,0) < 0
    or coalesce(gross_sales,0) < 0
    or coalesce(net_sales,0) < 0
    or coalesce(cogs,0) < 0;

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_distributor_dedup has % rows with negative qty/sales/cogs', v;
  end if;

  -- discount rate implied outside [0,1] (derived from amounts)
  select count(*) into v
  from int.int_sales_distributor_dedup
  where gross_sales is not null
    and gross_sales > 0
    and discount_amount is not null
    and (
      (discount_amount / gross_sales) < 0
      or (discount_amount / gross_sales) > 1.0
    );

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_distributor_dedup has % rows with implied discount rate outside [0,1]', v;
  end if;

  -- employee-day minutes sanity (<= 24 hours)
  select count(*) into v
  from int.int_labor_daily_employee
  where minutes_worked is not null
    and (minutes_worked < 0 or minutes_worked > 24*60);

  if v > 0 then
    raise exception 'QA FAIL: int.int_labor_daily_employee has % rows with minutes_worked outside [0,1440]', v;
  end if;

  -- labor daily sanity (event-based)
  select count(*) into v
  from int.int_labor_daily
  where hours_worked < 0
    or minutes_worked < 0
    or n_events < 0
    or n_shift_pairs < 0
    or n_employees < 0
    or n_unpaired_in < 0
    or n_out_events < 0
    or (n_employees > 0 and hours_worked > (24.5 * n_employees));  -- loose upper bound

  if v > 0 then
    raise exception 'QA FAIL: int.int_labor_daily has % rows with impossible labor metrics (negatives / hours too high)', v;
  end if;

end $$;

\echo '✅ INT checks passed'