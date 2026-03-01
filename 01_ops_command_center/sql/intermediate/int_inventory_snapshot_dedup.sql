-- 01_ops_command_center/sql/intermediate/int_inventory_snapshot_dedup.sql
-- Grain: `snapshot_date + site_code + sku`
-- Rule: pick the “best” row per grain using:

-- * prefer non-missing key
-- * prefer not negative inventory
-- * newest `ingested_at` then newest `drop_date`

create schema if not exists int;

create or replace view int.int_inventory_snapshot_dedup as
with ranked as (
    select
        i.*,
        row_number() over (
            partition by i.snapshot_date, i.site_code, i.sku
            order by
                -- keep real keys first
                (i.is_missing_key = false) desc,

                -- prefer sane inventory
                (coalesce(i.is_negative_inventory, false) = false) desc,

                -- newest load wins
                i.ingested_at desc nulls last,
                i.drop_date desc nulls last,
                i.load_id desc nulls last
        ) as rn
    from stg.stg_inventory_erp i
    where
        i.snapshot_date is not null
        and i.site_code is not null
        and i.sku is not null
)
select
    *
from ranked
where rn = 1
;