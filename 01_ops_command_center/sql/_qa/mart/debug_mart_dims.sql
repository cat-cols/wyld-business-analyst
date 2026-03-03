\set ON_ERROR_STOP on
\pset pager off

\echo ''
\echo '=============================='
\echo ' DEBUG: MART DIMENSIONS (triage)'
\echo '=============================='
\echo ''

-- ----------------------------
-- dim_date summary
-- ----------------------------
\echo ''
\echo '--- mart.dim_date summary ---'
select
  count(*) as n_rows,
  min(date_day) as min_date_day,
  max(date_day) as max_date_day
from mart.dim_date;

\echo ''
\echo '--- mart.dim_date duplicates (should be 0 rows) ---'
select
  date_day,
  count(*) as n
from mart.dim_date
group by 1
having count(*) > 1
order by n desc, date_day;

-- ----------------------------
-- dim_sku summary
-- ----------------------------
\echo ''
\echo '--- mart.dim_sku summary ---'
select
  count(*) as n_rows,
  count(*) filter (where product_name is null) as n_missing_product_name,
  round(
    100.0 * count(*) filter (where product_name is null) / nullif(count(*), 0),
    2
  ) as pct_missing_product_name
from mart.dim_sku;

\echo ''
\echo '--- mart.dim_sku null SKUs (should be 0) ---'
select count(*) as null_sku_rows
from mart.dim_sku
where sku is null;

\echo ''
\echo '--- mart.dim_sku duplicates (should be 0 rows) ---'
select
  sku,
  count(*) as n
from mart.dim_sku
group by 1
having count(*) > 1
order by n desc, sku;

\echo ''
\echo '--- sample SKUs missing product_name (limit 50) ---'
select
  sku,
  first_sale_date,
  last_sale_date,
  distribution_status_current,
  distribution_as_of_date
from mart.dim_sku
where product_name is null
order by last_sale_date desc nulls last, sku
limit 50;