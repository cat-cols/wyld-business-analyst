-- 01_ops_command_center/sql/validation/lineage_shape_report.sql
-- Column-shape + lineage “truth table” for core keys/metrics across raw → stg → int → mart.
--
-- Creates:
--   1) validation.lineage_shape_long  (row-based; great for debugging)
--   2) validation.lineage_shape_wide  (matrix; great for quick scanning)
--
-- Notes:
-- - This does NOT parse SQL to map *exact expressions*; it reports existence + type by object.
-- - Update the "objects" list and "tracked_columns" list as your model evolves.

create schema if not exists validation;

create or replace view validation.lineage_shape_long as
with tracked_columns as (
  select unnest(array[
    -- shared keys
    'store_code','sku','employee_id','channel',

    -- sales dates/ids
    'sale_date','txn_id','txn_date','txn_ts_parsed',

    -- timeclock/labor dates/ids
    'punch_ts','punch_date','action','work_date',

    -- ops dates/ids
    'snapshot_date','as_of_date',

    -- common measures
    'qty','gross_sales','net_sales','cogs',
    'hours_worked','minutes_worked',
    'on_hand','on_hand_safe','in_stock_flag'
  ])::text as column_name
),
objects as (
  -- layer, schema, object, label, domain
  select * from (values
    -- --------------------
    -- Distributor Sales path
    -- --------------------
    ('raw','raw','sales_distributor_extract','raw.sales_distributor_extract','sales_distributor'),
    ('stg','stg','stg_sales_distributor','stg.stg_sales_distributor','sales_distributor'),
    ('int','int','int_sales_distributor_dedup','int.int_sales_distributor_dedup','sales_distributor'),
    ('mart','mart','fact_sales_distributor_daily','mart.fact_sales_distributor_daily','sales_distributor'),

    -- --------------------
    -- POS Sales path
    -- --------------------
    ('raw','raw','pos_transactions_csv','raw.pos_transactions_csv','sales_pos'),
    ('stg','stg','stg_pos_transactions','stg.stg_pos_transactions','sales_pos'),
    ('int','int','int_pos_dedup','int.int_pos_dedup','sales_pos'),
    ('int','int','int_pos_daily','int.int_pos_daily','sales_pos'),
    ('mart','mart','fact_sales_pos_daily','mart.fact_sales_pos_daily','sales_pos'),

    -- --------------------
    -- Timeclock / Labor path
    -- --------------------
    ('raw','raw','timeclock_punches','raw.timeclock_punches','labor'),
    ('stg','stg','stg_timeclock_punches','stg.stg_timeclock_punches','labor'),
    ('int','int','int_timeclock_punches_latest','int.int_timeclock_punches_latest','labor'),
    ('int','int','int_labor_daily_employee','int.int_labor_daily_employee','labor'),
    ('int','int','int_labor_daily','int.int_labor_daily','labor'),
    ('mart','mart','fact_labor_daily','mart.fact_labor_daily','labor'),
    ('mart','mart','fact_timeclock_punches','mart.fact_timeclock_punches','labor'),

    -- --------------------
    -- Inventory / Coverage path (edit raw/stg names if yours differ)
    -- --------------------
    ('int','int','int_inventory_snapshot_dedup','int.int_inventory_snapshot_dedup','inventory'),
    ('mart','mart','fact_inventory_snapshot_daily','mart.fact_inventory_snapshot_daily','inventory'),
    ('int','int','int_coverage_conformed','int.int_coverage_conformed','coverage'),
    ('mart','mart','fact_distribution_coverage','mart.fact_distribution_coverage','coverage')
  ) as v(layer, schema_name, object_name, object_label, domain)
),
cols as (
  select
    c.table_schema,
    c.table_name,
    c.column_name,
    c.data_type,
    c.ordinal_position
  from information_schema.columns c
)
select
  o.domain,
  o.layer,
  o.object_label,
  t.column_name,

  (c.column_name is not null) as exists_in_object,
  c.data_type,
  c.ordinal_position

from tracked_columns t
cross join objects o
left join cols c
  on c.table_schema = o.schema_name
 and c.table_name   = o.object_name
 and c.column_name  = t.column_name
order by
  o.domain, o.object_label, t.column_name;

-- Wide matrix version (boolean existence by object)
create or replace view validation.lineage_shape_wide as
with base as (
  select * from validation.lineage_shape_long
)
select
  domain,
  column_name,

  -- Distributor sales
  max((exists_in_object and object_label = 'raw.sales_distributor_extract')::int)::boolean as raw_sales_distributor_extract,
  max((exists_in_object and object_label = 'stg.stg_sales_distributor')::int)::boolean as stg_sales_distributor,
  max((exists_in_object and object_label = 'int.int_sales_distributor_dedup')::int)::boolean as int_sales_distributor_dedup,
  max((exists_in_object and object_label = 'mart.fact_sales_distributor_daily')::int)::boolean as mart_fact_sales_distributor_daily,

  -- POS sales
  max((exists_in_object and object_label = 'raw.pos_transactions_csv')::int)::boolean as raw_pos_transactions_csv,
  max((exists_in_object and object_label = 'stg.stg_pos_transactions')::int)::boolean as stg_pos_transactions,
  max((exists_in_object and object_label = 'int.int_pos_dedup')::int)::boolean as int_pos_dedup,
  max((exists_in_object and object_label = 'int.int_pos_daily')::int)::boolean as int_pos_daily,
  max((exists_in_object and object_label = 'mart.fact_sales_pos_daily')::int)::boolean as mart_fact_sales_pos_daily,

  -- Labor
  max((exists_in_object and object_label = 'raw.timeclock_punches')::int)::boolean as raw_timeclock_punches,
  max((exists_in_object and object_label = 'stg.stg_timeclock_punches')::int)::boolean as stg_timeclock_punches,
  max((exists_in_object and object_label = 'int.int_timeclock_punches_latest')::int)::boolean as int_timeclock_punches_latest,
  max((exists_in_object and object_label = 'int.int_labor_daily_employee')::int)::boolean as int_labor_daily_employee,
  max((exists_in_object and object_label = 'int.int_labor_daily')::int)::boolean as int_labor_daily,
  max((exists_in_object and object_label = 'mart.fact_labor_daily')::int)::boolean as mart_fact_labor_daily,
  max((exists_in_object and object_label = 'mart.fact_timeclock_punches')::int)::boolean as mart_fact_timeclock_punches,

  -- Inventory + coverage
  max((exists_in_object and object_label = 'int.int_inventory_snapshot_dedup')::int)::boolean as int_inventory_snapshot_dedup,
  max((exists_in_object and object_label = 'mart.fact_inventory_snapshot_daily')::int)::boolean as mart_fact_inventory_snapshot_daily,
  max((exists_in_object and object_label = 'int.int_coverage_conformed')::int)::boolean as int_coverage_conformed,
  max((exists_in_object and object_label = 'mart.fact_distribution_coverage')::int)::boolean as mart_fact_distribution_coverage

from base
group by 1,2
order by domain, column_name;