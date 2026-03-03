-- 01_ops_command_center/sql/intermediate/int_pos_daily.sql
-- Grain: txn_date + store_code + sku

create schema if not exists int;

create or replace view int.int_pos_daily as
select
    txn_date,
    store_code,
    sku,
    count(*) as line_count,
    count(distinct txn_id) as txn_count,
    sum(coalesce(qty, 0)) as units,
    sum(coalesce(gross_amount, 0)) as gross_sales,
    sum(coalesce(net_amount, 0)) as net_sales
from int.int_pos_dedup
where txn_date is not null
  and store_code is not null
  and sku is not null
group by 1,2,3;