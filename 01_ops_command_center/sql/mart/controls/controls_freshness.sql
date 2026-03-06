-- 01_ops_command_center/sql/mart/controls/controls_freshness.sql
-- Freshness control: how recent is the latest date in each key mart model?
-- Robust to column name drift by selecting the first available date column from a candidate list.

create schema if not exists mart;

-- Helper: return max(date_column) for a model using the first column that exists from candidates
create or replace function mart._latest_date(
  _schema text,
  _table  text,
  _candidates text[]
) returns date
language plpgsql
as $$
declare
  col text;
  sql text;
  result date;
begin
  select c into col
  from unnest(_candidates) as c
  where exists (
    select 1
    from information_schema.columns
    where table_schema = _schema
      and table_name   = _table
      and column_name  = c
  )
  limit 1;

  if col is null then
    return null;
  end if;

  sql := format('select max(%I)::date from %I.%I', col, _schema, _table);
  execute sql into result;
  return result;
end $$;

create or replace view mart.controls_freshness as
with models as (
  -- model_schema, model_name, date candidates (ordered by preference)
  select * from (values
    ('mart','fact_sales_distributor_daily', array['sale_date','sales_date','date','day']::text[]),
    ('mart','fact_sales_pos_daily',         array['sale_date','sales_date','date','day']::text[]),
    ('mart','fact_sales_daily',             array['sale_date','sales_date','date','day']::text[]),

    ('mart','fact_labor_daily',             array['work_date','date','day']::text[]),
    ('mart','fact_inventory_snapshot_daily',array['snapshot_date','as_of_date','date','day']::text[]),

    -- KPIs (these vary a lot)
    ('mart','kpi_sales_per_labor_hour_daily', array['kpi_date','sale_date','work_date','as_of_date','date','day']::text[]),
    ('mart','kpi_instock_rate_daily',         array['as_of_date','snapshot_date','date','day']::text[]),
    ('mart','kpi_days_of_supply',             array['as_of_date','snapshot_date','date','day']::text[]),

    -- monthly finance
    ('mart','fact_actuals_monthly',         array['month_start','month','period_start','as_of_date','date']::text[])
  ) as v(model_schema, model_name, date_candidates)
),
checks as (
  select
    current_date::date as run_date,
    (model_schema || '.' || model_name)::text as model_name,
    mart._latest_date(model_schema, model_name, date_candidates) as latest_date
  from models
),
scored as (
  select
    run_date,
    model_name,
    latest_date,
    case
      when latest_date is null then null
      else (current_date::date - latest_date)::int
    end as days_lag
  from checks
)
select
  run_date,
  model_name,
  latest_date,
  days_lag,
  case
    when latest_date is null then 'Fail'
    when days_lag <= 2 then 'Pass'
    when days_lag <= 7 then 'Warning'
    else 'Fail'
  end as status
from scored
order by model_name;-- 01_ops_command_center/sql/mart/controls/controls_freshness.sql
-- Freshness control: how recent is the latest date in each key mart model?
-- Robust to column name drift by selecting the first available date column from a candidate list.

create schema if not exists mart;

-- Helper: return max(date_column) for a model using the first column that exists from candidates
create or replace function mart._latest_date(
  _schema text,
  _table  text,
  _candidates text[]
) returns date
language plpgsql
as $$
declare
  col text;
  sql text;
  result date;
begin
  select c into col
  from unnest(_candidates) as c
  where exists (
    select 1
    from information_schema.columns
    where table_schema = _schema
      and table_name   = _table
      and column_name  = c
  )
  limit 1;

  if col is null then
    return null;
  end if;

  sql := format('select max(%I)::date from %I.%I', col, _schema, _table);
  execute sql into result;
  return result;
end $$;

create or replace view mart.controls_freshness as
with models as (
  -- model_schema, model_name, date candidates (ordered by preference)
  select * from (values
    ('mart','fact_sales_distributor_daily', array['sale_date','sales_date','date','day']::text[]),
    ('mart','fact_sales_pos_daily',         array['sale_date','sales_date','date','day']::text[]),
    ('mart','fact_sales_daily',             array['sale_date','sales_date','date','day']::text[]),

    ('mart','fact_labor_daily',             array['work_date','date','day']::text[]),
    ('mart','fact_inventory_snapshot_daily',array['snapshot_date','as_of_date','date','day']::text[]),

    -- KPIs (these vary a lot)
    ('mart','kpi_sales_per_labor_hour_daily', array['kpi_date','sale_date','work_date','as_of_date','date','day']::text[]),
    ('mart','kpi_instock_rate_daily',         array['as_of_date','snapshot_date','date','day']::text[]),
    ('mart','kpi_days_of_supply',             array['as_of_date','snapshot_date','date','day']::text[]),

    -- monthly finance
    ('mart','fact_actuals_monthly',         array['month_start','month','period_start','as_of_date','date']::text[])
  ) as v(model_schema, model_name, date_candidates)
),
checks as (
  select
    current_date::date as run_date,
    (model_schema || '.' || model_name)::text as model_name,
    mart._latest_date(model_schema, model_name, date_candidates) as latest_date
  from models
),
scored as (
  select
    run_date,
    model_name,
    latest_date,
    case
      when latest_date is null then null
      else (current_date::date - latest_date)::int
    end as days_lag
  from checks
)
select
  run_date,
  model_name,
  latest_date,
  days_lag,
  case
    when latest_date is null then 'Fail'
    when days_lag <= 2 then 'Pass'
    when days_lag <= 7 then 'Warning'
    else 'Fail'
  end as status
from scored
order by model_name;