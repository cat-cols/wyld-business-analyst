create schema if not exists int;

create or replace view int.int_account_status_current as
with ranked as (
    select
        a.*,
        count(*) over (partition by a.store_code) as version_count,
        row_number() over (
            partition by a.store_code
            order by
                coalesce(a.status_date, a.drop_date) desc nulls last,
                a.ingested_at desc nulls last,
                a.drop_date desc nulls last,
                a.load_id desc nulls last
        ) as rn
    from stg.stg_account_status a
    where a.store_code is not null
)
select
    -- grain
    store_code,

    -- “current” status fields
    status_date,
    account_status,
    status_reason,

    -- lineage
    load_id,
    source_system,
    cadence,
    drop_date,
    ingested_at,

    -- debugging helper
    version_count
from ranked
where rn = 1
;