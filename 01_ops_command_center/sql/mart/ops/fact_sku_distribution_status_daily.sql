-- mart/ops/fact_sku_distribution_status_daily.sql
-- Grain: as_of_date + store_code + sku
-- Source of truth: int.int_sku_distribution_status_dedup

create schema if not exists mart;

create or replace view mart.fact_sku_distribution_status_daily as
select
  as_of_date,
  store_code,
  sku,
  distribution_status,
  status_reason,

  -- lineage
  load_id,
  source_system,
  cadence,
  drop_date,
  ingested_at,

  -- flags
  is_missing_key,
  is_duplicate_candidate,
  dup_group_size
from int.int_sku_distribution_status_dedup;
