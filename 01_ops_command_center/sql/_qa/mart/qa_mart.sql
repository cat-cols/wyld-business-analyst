-- MART CHECKS: grain + null keys + basic ranges + coverage notices
-- 01_ops_command_center/sql/_qa/mart/qa_mart.sql

\echo ''
\echo 'MART CHECKS: grain + null keys + basic ranges + coverage + controls/recon hard-fail'

-- -----------------------
-- Grain uniqueness (hard fail)
-- -----------------------
do $$
declare v int;
begin
  -- dim_store unique store_code
  select count(*) into v from (
    select store_code
    from mart.dim_store
    group by 1
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: mart.dim_store has % duplicate store_code values', v;
  end if;

  -- fact_sales grain
  select count(*) into v from (
    select sale_date, store_code, sku, channel
    from mart.fact_sales_distributor_daily
    group by 1,2,3,4
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: mart.fact_sales_distributor_daily has % duplicate rows at grain', v;
  end if;

  -- fact_labor grain
  select count(*) into v from (
    select work_date, store_code
    from mart.fact_labor_daily
    group by 1,2
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: mart.fact_labor_daily has % duplicate rows at grain', v;
  end if;

  -- KPI grain
  select count(*) into v from (
    select kpi_date, store_code
    from mart.kpi_sales_per_labor_hour_daily
    group by 1,2
    having count(*) > 1
  ) t;
  if v > 0 then
    raise exception 'QA FAIL: mart.kpi_sales_per_labor_hour_daily has % duplicate rows at grain', v;
  end if;

end $$;

-- -----------------------
-- Null keys (hard fail)
-- -----------------------
do $$
declare v int;
begin
  select count(*) into v
  from mart.fact_sales_distributor_daily
  where sale_date is null or store_code is null or sku is null or channel is null;

  if v > 0 then
    raise exception 'QA FAIL: mart.fact_sales_distributor_daily has % rows with null keys', v;
  end if;

  select count(*) into v
  from mart.fact_labor_daily
  where work_date is null or store_code is null;

  if v > 0 then
    raise exception 'QA FAIL: mart.fact_labor_daily has % rows with null keys', v;
  end if;

end $$;

-- -----------------------
-- Basic ranges (hard fail on obvious nonsense)
-- -----------------------
do $$
declare v int;
begin
  select count(*) into v
  from mart.fact_sales_distributor_daily
  where coalesce(qty,0) < 0
     or coalesce(gross_sales,0) < 0
     or coalesce(net_sales,0) < 0
     or coalesce(cogs,0) < 0;

  if v > 0 then
    raise exception 'QA FAIL: mart.fact_sales_distributor_daily has % rows with negative qty/sales/cogs', v;
  end if;

  select count(*) into v
  from mart.fact_labor_daily
  where hours_worked < 0 or n_punches < 0 or n_employees < 0;

  if v > 0 then
    raise exception 'QA FAIL: mart.fact_labor_daily has % rows with negative labor metrics', v;
  end if;

end $$;

-- -----------------------
-- Coverage notices (warn only)
-- -----------------------
do $$
declare v_sales_no_labor int;
declare v_labor_no_sales int;
begin
  select count(*) into v_sales_no_labor
  from mart.kpi_sales_per_labor_hour_daily
  where hours_worked is null;

  raise notice 'MART NOTICE: KPI rows with sales but missing labor = %', v_sales_no_labor;

  select count(*) into v_labor_no_sales
  from mart.fact_labor_daily l
  left join (
    select distinct kpi_date, store_code
    from mart.kpi_sales_per_labor_hour_daily
  ) k
    on k.kpi_date = l.work_date and k.store_code = l.store_code
  where k.store_code is null;

  raise notice 'MART NOTICE: labor days with no sales KPI row = %', v_labor_no_sales;
end $$;

-- -----------------------
-- Controls + recon (hard fail if any FAIL% rows)
-- -----------------------
do $$
declare v int;
begin
  -- 1) controls_missing_dim_joins
  select count(*) into v
  from mart.controls_missing_dim_joins
  where status ilike 'FAIL%';
  if v > 0 then
    raise exception 'QA FAIL: mart.controls_missing_dim_joins has % FAIL rows', v;
  end if;

  -- 2) controls_freshness (FAIL)
  -- statuses are PASS/WARNING/FAIL (case varies)
  select count(*) into v
  from mart.controls_freshness
  where lower(status) = 'fail';
  if v > 0 then
    raise exception 'QA FAIL: mart.controls_freshness has % FAIL rows', v;
  end if;

  -- 3) recon_sales_distributor_vs_pos (FAIL*)
  select count(*) into v
  from mart.recon_sales_distributor_vs_pos
  where status ilike 'FAIL%';
  if v > 0 then
    raise exception 'QA FAIL: mart.recon_sales_distributor_vs_pos has % FAIL rows', v;
  end if;

  -- 4) mart_reconciliation_controls (Fail)
  -- This is your consolidated control view (Pass/Warning/Fail)
  select count(*) into v
  from mart.mart_reconciliation_controls
  where lower(status) = 'fail';
  if v > 0 then
    raise exception 'QA FAIL: mart.mart_reconciliation_controls has % Fail rows', v;
  end if;

  -- 5) Optional: finance recon (only fail if the view exists AND has FAIL rows)
  -- If you haven't built finance yet, comment this block out.
  begin
    select count(*) into v
    from mart.recon_sales_to_gl_monthly
    where status ilike 'FAIL%';
    if v > 0 then
      raise exception 'QA FAIL: mart.recon_sales_to_gl_monthly has % FAIL rows', v;
    end if;
  exception when undefined_table then
    raise notice 'MART NOTICE: mart.recon_sales_to_gl_monthly not found (skipping)';
  end;

end $$;

\echo '✅ MART checks passed'