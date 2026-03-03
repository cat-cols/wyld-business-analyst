-- mart/core/controls_dim_join_coverage.sql
-- Control: join coverage of facts -> core dimensions.
-- Grain: 1 row per fact model

create schema if not exists mart;

create or replace view mart.controls_dim_join_coverage as
with sales as (
  select
    'mart.fact_sales_distributor_daily' as fact_model,
    count(*) as n_fact_rows,

    count(*) filter (where ds.store_code is null) as n_missing_dim_store,
    count(*) filter (where dk.sku is null)        as n_missing_dim_sku,

    count(*) filter (where ds.store_code is null or dk.sku is null) as n_missing_any_dim,

    (count(*) filter (where ds.store_code is null) ::numeric / nullif(count(*),0)) as pct_missing_dim_store,
    (count(*) filter (where dk.sku is null)        ::numeric / nullif(count(*),0)) as pct_missing_dim_sku,
    (count(*) filter (where ds.store_code is null or dk.sku is null)::numeric / nullif(count(*),0)) as pct_missing_any_dim
  from mart.fact_sales_distributor_daily f
  left join mart.dim_store ds on ds.store_code = f.store_code
  left join mart.dim_sku   dk on dk.sku        = f.sku
),
labor as (
  select
    'mart.fact_labor_daily' as fact_model,
    count(*) as n_fact_rows,

    count(*) filter (where ds.store_code is null) as n_missing_dim_store,
    0::bigint as n_missing_dim_sku,

    count(*) filter (where ds.store_code is null) as n_missing_any_dim,

    (count(*) filter (where ds.store_code is null)::numeric / nullif(count(*),0)) as pct_missing_dim_store,
    null::numeric as pct_missing_dim_sku,
    (count(*) filter (where ds.store_code is null)::numeric / nullif(count(*),0)) as pct_missing_any_dim
  from mart.fact_labor_daily f
  left join mart.dim_store ds on ds.store_code = f.store_code
)
select * from sales
union all
select * from labor;