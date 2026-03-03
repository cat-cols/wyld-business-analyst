-- 01_ops_command_center/sql/mart/controls/controls_missing_dim_joins.sql
-- Guardrail: count fact rows that fail to join to conformed dimensions.
--
-- Assumes mart.dim_store exists. dim_sku section is included but you can remove it
-- until you actually have mart.dim_sku + sku_key in facts.

create schema if not exists mart;

create or replace view mart.controls_missing_dim_joins as
with params as (
  select (current_date - 90)::date as start_date
)

-- =========================
-- Store joins
-- =========================
, sales_dist_store as (
  select
      current_date as run_date
    , 'mart.fact_sales_distributor_daily'::text as model_name
    , f.sales_date::date as grain_date
    , 'dim_store'::text  as dim_name
    , count(*)::bigint   as fact_rows
    , sum(case when ds.store_key is null then 1 else 0 end)::bigint as missing_dim_rows
  from mart.fact_sales_distributor_daily f
  join params p on f.sales_date::date >= p.start_date
  left join mart.dim_store ds
    on ds.store_key = f.store_key
  group by 1,2,3,4
)
, labor_store as (
  select
      current_date as run_date
    , 'mart.fact_labor_daily'::text as model_name
    , f.work_date::date as grain_date   -- <-- rename if needed
    , 'dim_store'::text  as dim_name
    , count(*)::bigint   as fact_rows
    , sum(case when ds.store_key is null then 1 else 0 end)::bigint as missing_dim_rows
  from mart.fact_labor_daily f
  join params p on f.work_date::date >= p.start_date
  left join mart.dim_store ds
    on ds.store_key = f.store_key
  group by 1,2,3,4
)

-- =========================
-- SKU joins (optional)
-- Uncomment when mart.dim_sku exists AND facts contain sku_key.
-- =========================
/*
, sales_dist_sku as (
  select
      current_date as run_date
    , 'mart.fact_sales_distributor_daily'::text as model_name
    , f.sales_date::date as grain_date
    , 'dim_sku'::text    as dim_name
    , count(*)::bigint   as fact_rows
    , sum(case when dk.sku_key is null then 1 else 0 end)::bigint as missing_dim_rows
  from mart.fact_sales_distributor_daily f
  join params p on f.sales_date::date >= p.start_date
  left join mart.dim_sku dk
    on dk.sku_key = f.sku_key
  group by 1,2,3,4
)
*/

select
    run_date
  , model_name
  , grain_date
  , dim_name
  , fact_rows
  , missing_dim_rows
  , case when fact_rows = 0 then 0
         else (missing_dim_rows::numeric / fact_rows::numeric)::numeric(18,4)
    end as missing_pct
  , case
      when fact_rows = 0 then 'WARN_no_rows'
      when missing_dim_rows = 0 then 'PASS'
      when (missing_dim_rows::numeric / fact_rows::numeric) <= 0.001 then 'WARN_low'  -- <= 0.1%
      else 'FAIL'
    end as status
from (
  select * from sales_dist_store
  union all
  select * from labor_store
  -- union all select * from sales_dist_sku
) x
order by model_name, dim_name, grain_date desc;