-- int/int_coverage_conformed.sql
-- Conformed distribution / coverage snapshot (store x sku over time).
-- Grain: 1 row per as_of_date + store_code + sku

-- Purpose:
-- - Standardize distribution_status into a few stable buckets
-- - Provide boolean flags that are easy to aggregate (is_carried, etc.)
-- - Add effective date range helpers for “as-of” joins
-- - Add store-side flags (missing store, inactive store) to support controls

-- Inputs:
-- - int.int_sku_distribution_status_dedup (deduped snapshots)
-- - int.int_dispensary_latest (store existence)
-- - int.int_account_status_current (store active/inactive context)

-- Logic:
-- takes int.int_sku_distribution_status_dedup
-- maps distribution_status into stable buckets (carried/pending/not_carried/discontinued)
-- adds boolean helpers, effective date range helpers
-- and store context flags (is_missing_store_dim, account status)

create schema if not exists int;

create or replace view int.int_coverage_conformed as
with base as (
  select
    c.*
  from int.int_sku_distribution_status_dedup c
  where c.as_of_date is not null
    and c.store_code is not null
    and c.sku is not null
),
classified as (
  select
    -- grain
    b.as_of_date,
    b.store_code,
    b.sku,

    -- raw-ish fields
    b.distribution_status,
    b.status_reason,

    -- stable bucket (small controlled vocabulary)
    case
      when b.distribution_status in ('carried','listed','active','in_distribution','available') then 'carried'
      when b.distribution_status in ('pending','pending_launch','onboarding') then 'pending'
      when b.distribution_status in ('not_carried','not_listed','inactive') then 'not_carried'
      when b.distribution_status in ('discontinued','retired') then 'discontinued'
      when b.distribution_status is null then null
      else b.distribution_status
    end as coverage_status,

    -- boolean helpers (mutually exclusive in the ideal world)
    (b.distribution_status in ('carried','listed','active','in_distribution','available')) as is_carried,
    (b.distribution_status in ('pending','pending_launch','onboarding')) as is_pending,
    (b.distribution_status in ('not_carried','not_listed','inactive')) as is_not_carried,
    (b.distribution_status in ('discontinued','retired')) as is_discontinued,

    -- keep a little raw context (useful for debugging)
    b.as_of_date_raw,
    b.store_code_raw,
    b.sku_raw,
    b.distribution_status_raw,

    -- flags
    coalesce(b.is_missing_key,false) as is_missing_key,
    coalesce(b.is_duplicate_candidate,false) as is_duplicate_candidate,

    -- lineage
    b.load_id,
    b.source_system,
    b.cadence,
    b.drop_date,
    b.ingested_at,

    -- explainability
    b.dup_group_size
  from base b
),
ranged as (
  select
    c.*,
    count(*) over (partition by c.store_code, c.sku) as version_count,
    lead(c.as_of_date) over (partition by c.store_code, c.sku order by c.as_of_date) as next_as_of_date
  from classified c
),
store_ctx as (
  select
    r.*,
    (d.store_code is null) as is_missing_store_dim,
    s.account_status,
    s.status_date as account_status_date,
    (lower(s.account_status) = 'active') as is_active_account,
    (lower(s.account_status) in ('inactive','suspended')) as is_inactive_or_suspended
  from ranged r
  left join int.int_dispensary_latest d
    on d.store_code = r.store_code
  left join int.int_account_status_current s
    on s.store_code = r.store_code
)
select
  -- grain
  as_of_date,
  store_code,
  sku,

  -- standardized status + helpers
  coverage_status,
  distribution_status,
  status_reason,

  is_carried,
  is_pending,
  is_not_carried,
  is_discontinued,

  -- effective range helpers for as-of joins
  as_of_date as effective_start_date,
  case
    when next_as_of_date is null then null
    else (next_as_of_date - interval '1 day')::date
  end as effective_end_date,
  next_as_of_date,

  -- store context flags
  account_status,
  account_status_date,
  is_active_account,
  is_inactive_or_suspended,
  is_missing_store_dim,

  -- QA + lineage
  is_missing_key,
  is_duplicate_candidate,
  version_count,
  dup_group_size,

  load_id,
  source_system,
  cadence,
  drop_date,
  ingested_at

from store_ctx
;