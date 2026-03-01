-- int/int_dispensary_latest.sql
-- One “best” dispensary master record per store_code (latest snapshot wins)

create schema if not exists int;

create or replace view int.int_dispensary_latest as
with ranked as (
  select
    dm.*,
    row_number() over (
      partition by dm.store_code
      order by
        dm.as_of_date desc nulls last,
        (dm.is_missing_key is false) desc,
        (dm.dispensary_id is not null) desc,
        (dm.dispensary_name is not null) desc,
        dm.ingested_at desc nulls last,
        dm.drop_date desc nulls last,
        dm.load_id desc nulls last
    ) as rn
  from stg.stg_dispensary_master dm
  where dm.store_code is not null
)
select
  -- keys
  store_code,
  dispensary_id,
  dispensary_name,

  -- attributes
  state,
  city,
  postal_code,
  license_id,
  account_type,

  -- lineage (keep!)
  as_of_date,
  load_id,
  drop_date,
  ingested_at,

  -- keep useful QA flags so marts can assert they’re clean
  is_missing_key,
  is_duplicate_candidate,

  -- debugging / explainability
  rn as selected_rank
from ranked
where rn = 1;