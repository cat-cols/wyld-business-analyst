-- int/int_account_status_current.sql
-- One “current” account status per store_code (latest status_date wins)

create schema if not exists int;

create or replace view int.int_account_status_current as
with ranked as (
  select
    s.*,
    row_number() over (
      partition by s.store_code
      order by
        s.status_date desc nulls last,
        (s.is_missing_key is false) desc,
        (s.account_status is not null) desc,
        (s.status_reason is not null) desc,
        s.ingested_at desc nulls last,
        s.drop_date desc nulls last,
        s.load_id desc nulls last
    ) as rn
  from stg.stg_account_status s
  where s.store_code is not null
)
select
  store_code,
  status_date,
  account_status,
  status_reason,

  load_id,
  drop_date,
  ingested_at,

  is_missing_key,
  is_duplicate_candidate,

  rn as selected_rank
from ranked
where rn = 1;