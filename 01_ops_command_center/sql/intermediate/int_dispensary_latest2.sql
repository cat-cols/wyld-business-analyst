-- int/int_dispensary_latest.sql
-- One “best” dispensary master record per store_code (latest snapshot wins)

create schema if not exists int;

create or replace view int.int_dispensary_latest as
with ranked as (
    select
        d.*,
        count(*) over (partition by d.store_code) as version_count,
        row_number() over (
            partition by d.store_code
            order by
                coalesce(d.as_of_date, d.drop_date) desc nulls last,
                d.ingested_at desc nulls last,
                d.drop_date desc nulls last,
                d.load_id desc nulls last
        ) as rn
    from stg.stg_dispensary_master d
    where d.store_code is not null
)
select
    -- grain
    store_code,

    -- “best” attributes
    dispensary_id,
    dispensary_name,
    state,
    city,
    postal_code,
    license_id,
    account_type,

    -- lineage (keep these!)
    as_of_date,
    load_id,
    source_system,
    cadence,
    drop_date,
    ingested_at,

    -- debugging helpers
    version_count
from ranked
where rn = 1
;