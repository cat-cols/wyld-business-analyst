-- mart/sales/fact_sales_pos_daily.sql
-- Grain: 1 row per sale_date + store_code + sku
-- Source: stg.stg_pos_transactions (deduped per txn_id inside this view)
-- Notes:
-- - POS has no COGS in the extracts → cogs is null
-- - POS “orders” approximated as distinct txn_id

create schema if not exists mart;

create or replace view mart.fact_sales_pos_daily as
with ranked as (
  select
    p.*,
    row_number() over (
      partition by p.txn_id
      order by
        (p.txn_ts_parsed is not null) desc,
        (p.store_code is not null) desc,
        (p.sku is not null) desc,
        p.ingested_at desc nulls last,
        p.drop_date desc nulls last,
        p.load_id desc nulls last
    ) as rn
  from stg.stg_pos_transactions p
  where p.txn_id is not null
),
dedup as (
  select *
  from ranked
  where rn = 1
),
daily as (
  select
    txn_date::date as sale_date,
    store_code,
    sku,

    count(*)::bigint as n_source_rows,
    count(distinct txn_id)::bigint as orders,

    sum(coalesce(qty, 0))::numeric as qty,
    sum(coalesce(gross_amount, 0))::numeric as gross_sales,
    sum(coalesce(net_amount, 0))::numeric as net_sales,

    -- infer discount from gross vs net when possible
    (sum(coalesce(gross_amount, 0)) - sum(coalesce(net_amount, 0)))::numeric as discount_amount,

    max(ingested_at) as max_ingested_at,
    max(drop_date)   as max_drop_date
  from dedup
  where txn_date is not null
    and store_code is not null
    and sku is not null
  group by 1,2,3
)
select
  d.sale_date,
  d.store_code,
  d.sku,

  -- POS is inherently “retail”; keep it explicit for downstream slices
  'retail'::text as channel,

  -- optional label (do not rely on it as a key)
  s.product_name,

  -- measures (align to distributor fact column set)
  d.qty,
  d.gross_sales,
  d.discount_amount,
  d.net_sales,
  null::numeric as cogs,
  d.orders,
  null::bigint as customers,

  -- derived / pricing (safe divide)
  case when nullif(d.qty, 0) is null then null
       else d.gross_sales / nullif(d.qty, 0)
  end as unit_list_price_wavg,

  case when nullif(d.qty, 0) is null then null
       else d.net_sales / nullif(d.qty, 0)
  end as unit_net_price_wavg,

  case when nullif(d.gross_sales, 0) is null then null
       else d.discount_amount / nullif(d.gross_sales, 0)
  end as discount_rate_implied,

  -- explainability / lineage
  d.n_source_rows,
  null::bigint as n_dup_candidate_rows,
  d.max_ingested_at,
  d.max_drop_date

from daily d
left join mart.dim_sku s
  on s.sku = d.sku;
