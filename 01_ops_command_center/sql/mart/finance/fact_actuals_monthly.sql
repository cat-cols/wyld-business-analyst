-- mart/finance/fact_actuals_monthly.sql
-- Grain: period_month + kpi_category (+ currency_code)
-- Source: stg.stg_finance_actuals

create schema if not exists mart;

create or replace view mart.fact_actuals_monthly as
select
  period_month,
  kpi_category,
  currency_code,

  sum(coalesce(actual_amount,0))::numeric as actual_amount,

  count(*)::bigint as n_source_rows,
  count(*) filter (where is_unmapped_metric)::bigint as n_unmapped_rows,

  max(ingested_at) as max_ingested_at,
  max(drop_date)   as max_drop_date
from stg.stg_finance_actuals
where period_month is not null
  and kpi_category is not null
group by 1,2,3;
