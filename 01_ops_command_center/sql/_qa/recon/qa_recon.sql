-- 01_ops_command_center/sql/_qa/recon/qa_recon.sql
-- This asserts your thin mart wrappers match their `int` sources (counts + totals). Great for catching “oops I joined something and doubled it.”

\echo ''
\echo 'RECON CHECKS: int vs mart totals (hard fail)'

do $$
declare v int;
declare a numeric;
declare b numeric;
begin
  -- Rowcount equality: sales
  select count(*) into v
  from (
    select 1
    from (
      select count(*) as c from int.int_sales_distributor_dedup
    ) i
    cross join (
      select count(*) as c from mart.fact_sales_distributor_daily
    ) m
    where i.c <> m.c
  ) t;

  if v > 0 then
    raise exception 'QA FAIL: rowcount mismatch (int.int_sales_distributor_dedup vs mart.fact_sales_distributor_daily)';
  end if;

  -- Totals equality: net_sales
  select sum(coalesce(net_sales,0)) into a from int.int_sales_distributor_dedup;
  select sum(coalesce(net_sales,0)) into b from mart.fact_sales_distributor_daily;

  if a <> b then
    raise exception 'QA FAIL: net_sales total mismatch (int=%, mart=%)', a, b;
  end if;

  -- Totals equality: labor hours
  select sum(coalesce(hours_worked,0)) into a from int.int_labor_daily;
  select sum(coalesce(hours_worked,0)) into b from mart.fact_labor_daily;

  if a <> b then
    raise exception 'QA FAIL: hours_worked total mismatch (int=%, mart=%)', a, b;
  end if;

end $$;

\echo '✅ RECON checks passed'
