-- mart/ops/fact_inventory_snapshot_daily.sql
-- Grain: snapshot_date + store_code + sku
-- Source of truth: int.int_inventory_snapshot_dedup

create schema if not exists mart;

create or replace view mart.fact_inventory_snapshot_daily as
select
  snapshot_date,
  site_code as store_code,
  sku,

  -- measures (keep both raw and “safe” versions)
  on_hand,
  on_hand_nonnegative as on_hand_safe,
  in_stock_flag,

  received_units,
  shipped_units,
  requested_units,
  backordered_units,

  -- flags
  is_negative_inventory,
  is_missing_key,

  -- lineage
  load_id,
  source_system,
  cadence,
  drop_date,
  ingested_at
from int.int_inventory_snapshot_dedup;
