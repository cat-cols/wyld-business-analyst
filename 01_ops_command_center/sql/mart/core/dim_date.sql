-- mart/core/dim_date.sql
-- Date dimension (independent of facts)
-- Grain: 1 row per calendar date

-- Range: current_date - 3 years through current_date + 1 year
-- Adjust bounds if you want a wider/narrower window.

create schema if not exists mart;

create or replace view mart.dim_date as
with bounds as (
  select
    (current_date - interval '3 years')::date as start_date,
    (current_date + interval '1 year')::date as end_date
),
dates as (
  select
    generate_series(
      (select start_date from bounds),
      (select end_date from bounds),
      interval '1 day'
    )::date as date_day
)
select
  -- surrogate-ish key (handy in BI)
  (extract(year from date_day)::int * 10000
   + extract(month from date_day)::int * 100
   + extract(day from date_day)::int
  ) as date_key,

  date_day as date,

  extract(year from date_day)::int as year,
  extract(quarter from date_day)::int as quarter,
  extract(month from date_day)::int as month,
  to_char(date_day, 'Mon') as month_name,
  to_char(date_day, 'YYYY-MM') as year_month,

  extract(day from date_day)::int as day_of_month,
  extract(doy from date_day)::int as day_of_year,

  -- ISO week (more stable for reporting)
  extract(isoweek from date_day)::int as iso_week,
  to_char(date_day, 'IYYY-IW') as iso_year_week,

  -- day of week (Mon=1..Sun=7 in ISO)
  extract(isodow from date_day)::int as iso_day_of_week,
  to_char(date_day, 'Dy') as day_name,

  -- common flags
  (extract(isodow from date_day) in (6,7)) as is_weekend,
  (date_trunc('month', date_day) = date_day) as is_month_start,
  ((date_trunc('month', date_day) + interval '1 month - 1 day')::date = date_day) as is_month_end,
  (date_trunc('quarter', date_day) = date_day) as is_quarter_start,
  ((date_trunc('quarter', date_day) + interval '3 months - 1 day')::date = date_day) as is_quarter_end,
  (date_trunc('year', date_day) = date_day) as is_year_start,
  ((date_trunc('year', date_day) + interval '1 year - 1 day')::date = date_day) as is_year_end

from dates;