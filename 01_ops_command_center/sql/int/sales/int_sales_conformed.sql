-- 01_ops_command_center/sql/int/sales/int_sales_conformed.sql
-- Phase 3 conformance wrapper for sales
-- Grain: 1 row per sale_date + store_code + sku + channel + sales_source
--
-- Purpose:
-- - Align distributor sales and POS sales to one shared business-key structure
-- - Enrich sales with conformed store/account context from INT truth tables
-- - Preserve lineage + explainability fields for downstream MART / QA use
--
-- Notes:
-- - This is an INT-layer bridge, so it should NOT depend on mart.*
-- - POS rows are force-labeled channel = 'retail'
-- - Product label is sourced from distributor sales when available

create schema if not exists int;

create or replace view int.int_sales_conformed as
with distributor as (
    select
        d.sale_date,
        d.store_code,
        d.sku,
        d.channel,
        'distributor'::text as sales_source,

        d.product_name,

        d.qty::numeric as qty,
        d.gross_sales::numeric as gross_sales,
        d.discount_amount::numeric as discount_amount,
        d.net_sales::numeric as net_sales,
        d.cogs::numeric as cogs,
        d.orders::bigint as orders,
        d.customers::bigint as customers,

        d.unit_list_price::numeric as unit_list_price,
        d.unit_net_price::numeric as unit_net_price,
        d.discount_rate::numeric as discount_rate,

        coalesce(d.dup_group_size, 1)::int as n_source_rows,
        greatest(coalesce(d.dup_group_size, 1) - 1, 0)::int as n_dup_candidate_rows,

        d.load_id,
        d.source_system,
        d.cadence,
        d.drop_date,
        d.ingested_at
    from int.int_sales_distributor_dedup d
    where d.sale_date is not null
      and d.store_code is not null
      and d.sku is not null
      and d.channel is not null
),

pos_daily as (
    select
        p.txn_date::date as sale_date,
        p.store_code,
        p.sku,
        'retail'::text as channel,
        'pos'::text as sales_source,

        null::text as product_name,

        sum(coalesce(p.qty, 0))::numeric as qty,
        sum(coalesce(p.gross_amount, 0))::numeric as gross_sales,
        (sum(coalesce(p.gross_amount, 0)) - sum(coalesce(p.net_amount, 0)))::numeric as discount_amount,
        sum(coalesce(p.net_amount, 0))::numeric as net_sales,
        null::numeric as cogs,
        count(distinct p.txn_id)::bigint as orders,
        null::bigint as customers,

        case
            when nullif(sum(coalesce(p.qty, 0))::numeric, 0) is null then null
            else sum(coalesce(p.gross_amount, 0))::numeric
                 / nullif(sum(coalesce(p.qty, 0))::numeric, 0)
        end as unit_list_price,

        case
            when nullif(sum(coalesce(p.qty, 0))::numeric, 0) is null then null
            else sum(coalesce(p.net_amount, 0))::numeric
                 / nullif(sum(coalesce(p.qty, 0))::numeric, 0)
        end as unit_net_price,

        case
            when nullif(sum(coalesce(p.gross_amount, 0))::numeric, 0) is null then null
            else (
                sum(coalesce(p.gross_amount, 0))::numeric
                - sum(coalesce(p.net_amount, 0))::numeric
            ) / nullif(sum(coalesce(p.gross_amount, 0))::numeric, 0)
        end as discount_rate,

        count(*)::int as n_source_rows,
        0::int as n_dup_candidate_rows,

        max(p.load_id) as load_id,
        max(p.source_system) as source_system,
        max(p.cadence) as cadence,
        max(p.drop_date) as drop_date,
        max(p.ingested_at) as ingested_at
    from int.int_pos_dedup p
    where p.txn_date is not null
      and p.store_code is not null
      and p.sku is not null
    group by 1,2,3,4,5
),

sales_union as (
    select * from distributor
    union all
    select * from pos_daily
),

product_ranked as (
    select
        d.sku,
        d.product_name,
        row_number() over (
            partition by d.sku
            order by
                d.sale_date desc nulls last,
                d.ingested_at desc nulls last,
                d.drop_date desc nulls last,
                d.load_id desc nulls last
        ) as rn
    from int.int_sales_distributor_dedup d
    where d.sku is not null
      and d.product_name is not null
),

product_lookup as (
    select
        sku,
        product_name
    from product_ranked
    where rn = 1
),

store_ctx as (
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
        s.status_date as account_status_date,

        (lower(s.account_status) = 'active') as is_active_account,
        (lower(s.account_status) in ('inactive', 'suspended')) as is_inactive_or_suspended
    from int.int_dispensary_latest d
    left join int.int_account_status_current s
      on s.store_code = d.store_code
)

select
    -- conformed business keys
    u.sale_date,
    u.store_code,
    u.sku,
    u.channel,
    u.sales_source,

    -- descriptive attributes
    coalesce(u.product_name, pl.product_name) as product_name,

    sc.dispensary_id,
    sc.dispensary_name,
    sc.state,
    sc.city,
    sc.postal_code,
    sc.license_id,
    sc.account_type,
    sc.account_status,
    sc.account_status_reason,
    sc.account_status_date,
    sc.is_active_account,
    sc.is_inactive_or_suspended,

    -- conformance / QA helpers
    (sc.store_code is null) as is_missing_store_dim,
    (coalesce(u.product_name, pl.product_name) is null) as is_missing_product_label,

    -- measures
    u.qty,
    u.gross_sales,
    u.discount_amount,
    u.net_sales,
    u.cogs,
    u.orders,
    u.customers,
    u.unit_list_price,
    u.unit_net_price,
    u.discount_rate,

    -- explainability
    u.n_source_rows,
    u.n_dup_candidate_rows,

    -- lineage
    u.load_id,
    u.source_system,
    u.cadence,
    u.drop_date,
    u.ingested_at

from sales_union u
left join product_lookup pl
  on pl.sku = u.sku
left join store_ctx sc
  on sc.store_code = u.store_code
;