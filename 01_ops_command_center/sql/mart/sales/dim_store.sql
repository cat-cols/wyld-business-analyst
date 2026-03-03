-- mart.dim_store
-- mart.dim_store = `int.int_dispensary_latest` + `int.int_account_status_current`
-- Grain: 1 row per store_code (conformed store dimension)

create schema if not exists mart;

create or replace view mart.dim_store as
select
  d.store_code,

  d.dispensary_id,
  d.dispensary_name,
  d.state,
  d.city,
  d.postal_code,
  d.license_id,
  d.account_type,

  s.account_status,
  s.status_reason as account_status_reason,
  s.status_date   as account_status_date,

  -- helpful flags (standardize status values to avoid case/spacing surprises)
  (lower(s.account_status) = 'active') as is_active_account,
  (lower(s.account_status) in ('inactive','suspended')) as is_inactive_or_suspended,

  -- lineage breadcrumbs
  d.as_of_date   as dispensary_as_of_date,
  d.ingested_at  as dispensary_ingested_at,
  s.ingested_at  as status_ingested_at
from int.int_dispensary_latest d
left join int.int_account_status_current s
  on s.store_code = d.store_code;