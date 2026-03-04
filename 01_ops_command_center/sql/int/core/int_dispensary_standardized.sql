-- int/int_dispensary_standardized.sql
-- Conformed store/dispensary reference.
-- Grain: 1 row per store_code

-- Purpose:
-- - Provide a single, stable, joinable store reference in the INT layer
--   (before MART consumption wrappers).
-- - Combine the “best” dispensary attributes with the current account status.

-- Inputs:
-- - int.int_dispensary_latest (truth-selected dispensary attributes)
-- - int.int_account_status_current (truth-selected account status)

-- Logic: int.int_dispensary_latest + int.int_account_status_current
-- plus standardized flags (is_active_account, etc.) and lineage fields

create schema if not exists int;

create or replace view int.int_dispensary_standardized as
select
  -- grain / natural key
  d.store_code,

  -- identity
  d.dispensary_id,
  d.dispensary_name,

  -- location / business attrs
  d.state,
  d.city,
  d.postal_code,
  d.license_id,
  d.account_type,

  -- current account status (sell-to / active / inactive, etc.)
  s.account_status,
  s.status_reason as account_status_reason,
  s.status_date   as account_status_date,

  -- standardized booleans for downstream filtering
  (lower(s.account_status) = 'active') as is_active_account,
  (lower(s.account_status) in ('inactive','suspended')) as is_inactive_or_suspended,
  (lower(s.account_status) = 'pending') as is_pending_account,

  -- lineage breadcrumbs (keep both sides)
  d.as_of_date    as dispensary_as_of_date,
  d.load_id       as dispensary_load_id,
  d.source_system as dispensary_source_system,
  d.cadence       as dispensary_cadence,
  d.drop_date     as dispensary_drop_date,
  d.ingested_at   as dispensary_ingested_at,

  s.load_id       as status_load_id,
  s.source_system as status_source_system,
  s.cadence       as status_cadence,
  s.drop_date     as status_drop_date,
  s.ingested_at   as status_ingested_at,

  -- QA / explainability
  coalesce(d.is_missing_key,false) as dispensary_is_missing_key,
  coalesce(d.is_duplicate_candidate,false) as dispensary_is_duplicate_candidate,
  d.version_count as dispensary_version_count,

  s.version_count as status_version_count

from int.int_dispensary_latest d
left join int.int_account_status_current s
  on s.store_code = d.store_code
;