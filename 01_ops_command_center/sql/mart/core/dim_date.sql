-- mart/core/dim_date.sql
-- Core date dimension derived from facts (sale_date + work_date).
-- Grain: 1 row per date

create schema if not exists mart;

create or replace view mart.dim_date as
with bounds as (
  select
    least(
      (select min(sale_date) from mart.fact_sales_distributor_daily),
      (select min(work_date) from mart.fact_labor_daily)
    ) as min_date,
    greatest(
      (select max(sale_date) from mart.fact_sales_distributor_daily),
      (select max(work_date) from mart.fact_labor_daily)
    ) as max_date
),
dates as (
  select
    generate_series(b.min_date, b.max_date, interval '1 day')::date as date_day
  from bounds b
  where b.min_date is not null and b.max_date is not null
)
select
  date_day,

  extract(isodow from date_day)::int as iso_day_of_week,   -- 1=Mon..7=Sun
  to_char(date_day, 'Day') as day_name,
  (extract(isodow from date_day) in (6,7)) as is_weekend,

  extract(day from date_day)::int as day_of_month,
  extract(month from date_day)::int as month_num,
  to_char(date_day, 'Mon') as month_name_short,
  to_char(date_day, 'Month') as month_name,
  extract(quarter from date_day)::int as quarter,
  extract(year from date_day)::int as year,

  to_char(date_day, 'YYYY-MM') as year_month,
  date_trunc('week', date_day)::date as week_start_date,
  to_char(date_day, 'IYYY-IW') as iso_year_week

from dates;
