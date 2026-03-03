-- int/int_timeclock_punches_latest.sql
-- One “best” version per punch. Prefers complete punches (has clock_out), then latest times, then latest ingest.

-- if a punch gets corrected by changing clock_in_at,
-- your natural key treats it as a new punch (because the key includes clock_in_at).
-- acceptable for now, but document it.

-- Timeclock exports are notorious for “multiple versions of the truth”:
-- a punch is exported once with no clock_out
-- later it’s exported again with clock_out
-- sometimes the export is corrected (clock_in edited, clock_out edited, etc.)
-- sometimes a re-export duplicates everything

-- How the truth selection works (the logic):
-- `int_timeclock_punches_latest` ranks rows per punch key and picks rn=1, preferring:
-- 1. punches that have a `clock_out` (complete beats incomplete)
-- 2. the `latest clock_out / clock_in`
-- 3. the `most recently ingested` data (latest drop/ingest/load wins)

-- Then you compute `minutes_worked` safely:
-- if missing clock_out → null
-- if clock_out < clock_in → null (bad data)
-- else → minutes difference

-- What you get:
-- A stable “clean punches” view that you can trust, and a daily rollup (`int_labor_daily`) that’s easy to join to sales.

create schema if not exists int;

create or replace view int.int_timeclock_punches_latest as
with base as (
  select
    p.*
  from stg.stg_timeclock_punches p
  where
    coalesce(p.is_missing_key,false) = false
    and p.store_code is not null
    and p.employee_id is not null
    and p.clock_in_at is not null
),
ranked as (
  select
    b.*,
    row_number() over (
      partition by
        -- Prefer a real punch_id if you have it; otherwise use a natural key
        coalesce(b.punch_id::text, b.store_code || '|' || b.employee_id || '|' || b.clock_in_at::text)
      order by
        (b.clock_out_at is not null) desc,
        b.clock_out_at desc nulls last,
        b.clock_in_at desc nulls last,
        b.ingested_at desc nulls last,
        b.drop_date desc nulls last,
        b.load_id desc nulls last
    ) as rn
  from base b
)
select
  -- punch identity
  punch_id,
  store_code,
  employee_id,

  -- times
  clock_in_at,
  clock_out_at,

  -- derived (safe-ish)
  case
    when clock_out_at is null then null
    when clock_out_at < clock_in_at then null
    else extract(epoch from (clock_out_at - clock_in_at)) / 60.0
  end as minutes_worked,

  -- lineage
  load_id,
  drop_date,
  ingested_at,

  -- QA flags
  is_missing_key,
  is_duplicate_candidate,

  rn as selected_rank
from ranked
where rn = 1;