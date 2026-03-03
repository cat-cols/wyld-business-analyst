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

    a.account_status,
    a.status_reason,
    a.status_date,

    -- helpful flags
    (a.account_status = 'active') as is_active_account,
    (a.account_status in ('inactive','suspended')) as is_inactive_or_suspended,

    -- lineage
    d.as_of_date as store_as_of_date,
    d.ingested_at as store_ingested_at,
    a.ingested_at as status_ingested_at
from int.int_dispensary_latest d
left join int.int_account_status_current a
  on a.store_code = d.store_code;

