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
    and coalesce(s.is_missing_key,false) = false
),
agg as (
  select
    as_of_date,
    store_code,
    sku,

    case
      when bool_or(distribution_status = 'carried') then 'carried'
      when bool_or(distribution_status = 'pending') then 'pending'
      when bool_or(distribution_status = 'not_carried') then 'not_carried'
      when bool_or(distribution_status = 'discontinued') then 'discontinued'
      else min(distribution_status)
    end as distribution_status,

    -- keep *some* reason (you can refine later to “reason matching chosen status”)
    max(status_reason) as status_reason,

    count(*) as n_source_rows,
    count(*) filter (where coalesce(is_duplicate_candidate,false)) as n_dup_candidate_rows,
    max(ingested_at) as max_ingested_at,
    max(drop_date) as max_drop_date
  from base
  group by 1,2,3
)
select * from agg;