-- 01_ops_command_center/sql/intermediate/int_sales_distributor_dedup.sql
-- Grain: sale_date + store_code + sku + channel

create schema if not exists int;

create or replace view int.int_sales_distributor_dedup as
with ranked as (
    select
        sd.*,
        row_number() over (
            partition by sd.sale_date, sd.store_code, sd.sku, sd.channel
            order by
                coalesce(sd.is_missing_key, false) asc,
                sd.ingested_at desc nulls last,
                sd.drop_date desc nulls last,
                sd.load_id desc nulls last
        ) as rn
    from stg.stg_sales_distributor sd
    where sd.sale_date is not null
      and sd.store_code is not null
      and sd.sku is not null
      and sd.channel is not null
)
select
    -- keep all columns except rn
    ranked.*
from ranked
where rn = 1;