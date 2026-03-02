-- 01_ops_command_center/sql/intermediate/int_pos_daily.sql
-- Grain: `txn_date + store_code + sku`
-- Measures: `txn_count`, `qty_sum`, `gross_sales`, `net_sales`, avg unit price, avg discount

-- For when you’d rather go straight to daily grain (super useful for marts):

create schema if not exists int;

create or replace view int.int_pos_daily as
select
    txn_date,
    store_code,
    sku,

    count(*) as txn_line_count,
    count(distinct txn_id) as txn_count,

    sum(coalesce(qty, 0)) as qty_units,
    sum(coalesce(gross_amount, 0)) as gross_sales,
    sum(coalesce(net_amount, 0)) as net_sales,

    avg(unit_price) as avg_unit_price,
    avg(discount_pct) as avg_discount_pct,

    max(drop_date) as last_drop_date,
    max(ingested_at) as last_ingested_at
from int.int_pos_dedup
where
    txn_date is not null
    and store_code is not null
    and sku is not null
group by 1,2,3
;