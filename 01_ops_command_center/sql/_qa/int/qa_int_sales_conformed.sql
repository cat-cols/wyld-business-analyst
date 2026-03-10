-- 01_ops_command_center/sql/_qa/int/qa_int_sales_conformed.sql
-- Phase 5 QA for int.int_sales_conformed
-- Checks:
--   1) view exists
--   2) grain uniqueness
--   3) null keys
--   4) allowed values
--   5) basic numeric sanity
--   6) conformance coverage notices

\echo ''
\echo 'INT SALES CONFORMED CHECKS: grain + keys + allowed values + coverage'

-- -----------------------
-- Object exists + grain uniqueness (hard fail)
-- -----------------------
do $$
declare rel regclass;
declare v int;
begin
  rel := to_regclass('int.int_sales_conformed');
  if rel is null then
    raise exception 'QA FAIL: int.int_sales_conformed does not exist';
  end if;

  select count(*) into v
  from (
    select
      sale_date,
      store_code,
      sku,
      channel,
      sales_source
    from int.int_sales_conformed
    group by 1,2,3,4,5
    having count(*) > 1
  ) t;

  if v > 0 then
    raise exception
      'QA FAIL: int.int_sales_conformed has % duplicate rows at (sale_date, store_code, sku, channel, sales_source)',
      v;
  end if;
end $$;

-- -----------------------
-- Null keys (hard fail)
-- -----------------------
do $$
declare v int;
begin
  select count(*) into v
  from int.int_sales_conformed
  where sale_date is null
     or store_code is null
     or sku is null
     or channel is null
     or sales_source is null;

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_conformed has % rows with null conformed keys', v;
  end if;
end $$;

-- -----------------------
-- Allowed values (hard fail)
-- -----------------------
do $$
declare v int;
begin
  -- sales_source should only be distributor or pos
  select count(*) into v
  from int.int_sales_conformed
  where lower(sales_source) not in ('distributor', 'pos');

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_conformed has % rows with unexpected sales_source values', v;
  end if;

  -- Project 1 expected channel set
  select count(*) into v
  from int.int_sales_conformed
  where lower(channel) not in ('retail', 'wholesale', 'distributor');

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_conformed has % rows with unexpected channel values', v;
  end if;
end $$;

-- -----------------------
-- Basic ranges / reasonableness (hard fail)
-- -----------------------
do $$
declare v int;
begin
  select count(*) into v
  from int.int_sales_conformed
  where coalesce(qty, 0) < 0
     or coalesce(gross_sales, 0) < 0
     or coalesce(discount_amount, 0) < 0
     or coalesce(net_sales, 0) < 0
     or coalesce(cogs, 0) < 0
     or coalesce(orders, 0) < 0
     or coalesce(customers, 0) < 0
     or coalesce(unit_list_price, 0) < 0
     or coalesce(unit_net_price, 0) < 0;

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_conformed has % rows with negative sales metrics', v;
  end if;

  select count(*) into v
  from int.int_sales_conformed
  where discount_rate is not null
    and (discount_rate < 0 or discount_rate > 1);

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_conformed has % rows with discount_rate outside [0,1]', v;
  end if;

  select count(*) into v
  from int.int_sales_conformed
  where gross_sales is not null
    and net_sales is not null
    and gross_sales < net_sales;

  if v > 0 then
    raise exception 'QA FAIL: int.int_sales_conformed has % rows where gross_sales < net_sales', v;
  end if;
end $$;

-- -----------------------
-- Conformance coverage (hard fail for store dim, notice for labels/status)
-- -----------------------
do $$
declare v_missing_store_dim int;
declare v_missing_product_label int;
declare v_missing_account_status int;
begin
  select count(*) into v_missing_store_dim
  from int.int_sales_conformed
  where is_missing_store_dim;

  if v_missing_store_dim > 0 then
    raise exception 'QA FAIL: int.int_sales_conformed has % rows missing store conformance context', v_missing_store_dim;
  end if;

  select count(*) into v_missing_product_label
  from int.int_sales_conformed
  where is_missing_product_label;

  raise notice
    'INT NOTICE: int.int_sales_conformed rows missing product label = %',
    v_missing_product_label;

  select count(*) into v_missing_account_status
  from int.int_sales_conformed
  where account_status is null;

  raise notice
    'INT NOTICE: int.int_sales_conformed rows missing account_status = %',
    v_missing_account_status;
end $$;

\echo '✅ INT sales conformed checks passed'
