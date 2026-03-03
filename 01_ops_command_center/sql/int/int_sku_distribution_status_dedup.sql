-- int/int_sku_distribution_status_dedup.sql
-- Dedup at grain: as_of_date + store_code + sku
-- Precedence rule: carried > pending > not_carried > discontinued

create schema if not exists int;

create or replace view int.int_sku_distribution_status_dedup as
with base as (
    select
        s.*
    from stg.stg_sku_distribution_status s
    where
        s.as_of_date is not null
        and s.store_code is not null
        and s.sku is not null
),
ranked as (
    select
        b.*,
        count(*) over (
            partition by b.as_of_date, b.store_code, b.sku
        ) as dup_group_size,
        row_number() over (
            partition by b.as_of_date, b.store_code, b.sku
            order by
                b.is_missing_key asc,
                b.ingested_at desc nulls last,
                b.drop_date desc nulls last,
                b.load_id desc nulls last
        ) as rn
    from base b
)
select
    -- grain
    as_of_date,
    store_code,
    sku,

    -- status fields
    distribution_status,
    status_reason,

    -- keep raw context if useful
    as_of_date_raw,
    store_code_raw,
    sku_raw,
    distribution_status_raw,

    -- flags
    is_missing_key,
    is_duplicate_candidate,

    -- lineage
    load_id,
    source_system,
    cadence,
    drop_date,
    ingested_at,

    -- debugging helper
    dup_group_size
from ranked
where rn = 1
;
