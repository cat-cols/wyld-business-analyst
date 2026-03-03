-- 01_ops_command_center/sql/mart/recon/recon_sales_distributor_vs_pos.sql
-- Recon: Distributor daily vs POS daily (by store_key + day).

-- IMPORTANT: Edit the POS source in pos_src CTE to match your actual conformed POS table/view.
-- If you already have mart.fact_sales_pos_daily, swap pos_daily to read from that.

create schema if not exists mart;

create or replace view mart.recon_sales_distributor_vs_pos as
with params as (
  select
      (current_date - 90)::date as start_date
    , 0.02::numeric             as pct_tolerance          -- 2% tolerance
    , 100.00::numeric           as abs_tolerance          -- $100 tolerance (adjust to your scale)
)
, dist_daily as (
  select
      f.sales_date::date as sales_date
    , f.store_key
    , sum(f.net_sales)::numeric(18,2) as dist_net_sales
  from mart.fact_sales_distributor_daily f
  join params p on f.sales_date::date >= p.start_date
  group by 1,2
)
, pos_src as (
  -- ✅ CHANGE THIS to your POS conformed source.
  -- Common candidates:
  --   int.int_sales_pos_dedup
  --   stg.stg_sales_pos_transactions
  select
      sold_at
    , store_key
    , net_sales
  from int.int_sales_pos_dedup
)
, pos_daily as (
  select
      date_trunc('day', p.sold_at)::date as sales_date
    , p.store_key
    , sum(p.net_sales)::numeric(18,2)    as pos_net_sales
  from pos_src p
  join params par on date_trunc('day', p.sold_at)::date >= par.start_date
  group by 1,2
)
, joined as (
  select
      coalesce(d.sales_date, p.sales_date) as sales_date
    , coalesce(d.store_key,  p.store_key)  as store_key
    , d.dist_net_sales
    , p.pos_net_sales
  from dist_daily d
  full outer join pos_daily p
    on d.sales_date = p.sales_date
   and d.store_key  = p.store_key
)
select
    j.sales_date
  , j.store_key
  , j.dist_net_sales
  , j.pos_net_sales
  , (coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0))::numeric(18,2) as diff_net_sales
  , case
      when greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0))) = 0 then 0
      else
        (abs(coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0))
          / nullif(greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0))), 0)
        )::numeric(18,4)
    end as pct_diff
  , case
      when j.dist_net_sales is null then 'FAIL_missing_distributor'
      when j.pos_net_sales  is null then 'FAIL_missing_pos'
      when (
        abs(coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0)) <= (select abs_tolerance from params)
        or
        (
          greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0))) > 0
          and
          (abs(coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0))
            / greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0)))
          ) <= (select pct_tolerance from params)
        )
      ) then 'PASS'
      else 'FAIL_mismatch'
    end as status
from joined j
order by j.sales_date desc, j.store_key;