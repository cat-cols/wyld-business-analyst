-- int/int_dispensary_latest.sql
-- Truth selector: 1 row per store_code (prefer latest, but avoid broken records)
-- Stable dimension behavior even when your generator injects messy rows.
-- Explains itself (version_count, QA flags).
-- Doesn’t throw away lineage, which will matter when you debug facts that don’t join.

create schema if not exists int;

create or replace view int.int_dispensary_latest as
with ranked as (
  select
    dm.*,
    count(*) over (partition by dm.store_code) as version_count,
    row_number() over (
      partition by dm.store_code
      order by
        coalesce(dm.as_of_date, dm.drop_date) desc nulls last,
        (coalesce(dm.is_missing_key,false) is false) desc,
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
  -- grain + keys
  store_code,
  dispensary_id,
  dispensary_name,

  -- attributes
  state,
  city,
  postal_code,
  license_id,
  account_type,

  -- lineage
  as_of_date,
  load_id,
  source_system,
  cadence,
  drop_date,
  ingested_at,

  -- QA + explainability
  coalesce(is_missing_key,false) as is_missing_key,
  coalesce(is_duplicate_candidate,false) as is_duplicate_candidate,
  version_count
from ranked
where rn = 1;