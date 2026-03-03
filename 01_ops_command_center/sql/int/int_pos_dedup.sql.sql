-- 01_ops_command_center/sql/intermediate/int_pos_dedup.sql
-- Grain: txn_id (best row per txn)

create schema if not exists int;

create or replace view int.int_pos_dedup as
with ranked as (
    select
        p.*,
        row_number() over (
            partition by p.txn_id
            order by
                p.txn_ts_parsed desc nulls last,
                p.ingested_at desc nulls last,
                p.drop_date desc nulls last,
                p.load_id desc nulls last
        ) as rn
    from stg.stg_pos_transactions p
    where p.txn_id is not null
)
select ranked.*
from ranked
where rn = 1;