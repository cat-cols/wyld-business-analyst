-- 01_ops_command_center/sql/mart/recon/recon_sales_distributor_vs_pos.sql
-- Reconciliation: Distributor vs POS sales at store-day grain.
-- Output: 1 row per sale_date + store_code with deltas + pass/warn/fail.

create schema if not exists mart;

create or replace view mart.recon_sales_distributor_vs_pos as
with params as (
  select
    (current_date - 90)::date as start_date,
    0.010::numeric as tolerance_pct  -- 1% default; adjust as desired
),
dist as (
  select
    f.sale_date::date as sale_date,
    f.store_code,
    sum(coalesce(f.net_sales,0))::numeric   as dist_net_sales,
    sum(coalesce(f.gross_sales,0))::numeric as dist_gross_sales,
    sum(coalesce(f.qty,0))::numeric         as dist_qty
  from mart.fact_sales_distributor_daily f
  join params p on f.sale_date::date >= p.start_date
  group by 1,2
),
pos as (
  select
    f.sale_date::date as sale_date,
    f.store_code,
    sum(coalesce(f.net_sales,0))::numeric   as pos_net_sales,
    sum(coalesce(f.gross_sales,0))::numeric as pos_gross_sales,
    sum(coalesce(f.qty,0))::numeric         as pos_qty
  from mart.fact_sales_pos_daily f
  join params p on f.sale_date::date >= p.start_date
  group by 1,2
),
j as (
  select
    coalesce(d.sale_date, p.sale_date) as sale_date,
    coalesce(d.store_code, p.store_code) as store_code,

    d.dist_net_sales,
    p.pos_net_sales,
    (coalesce(p.pos_net_sales,0) - coalesce(d.dist_net_sales,0)) as delta_net_sales,

    d.dist_gross_sales,
    p.pos_gross_sales,
    (coalesce(p.pos_gross_sales,0) - coalesce(d.dist_gross_sales,0)) as delta_gross_sales,

    d.dist_qty,
    p.pos_qty,
    (coalesce(p.pos_qty,0) - coalesce(d.dist_qty,0)) as delta_qty,

    -- pct delta based on the larger magnitude of the two totals
    case
      when greatest(abs(coalesce(d.dist_net_sales,0)), abs(coalesce(p.pos_net_sales,0))) = 0 then 0
      else abs(coalesce(p.pos_net_sales,0) - coalesce(d.dist_net_sales,0))
           / nullif(greatest(abs(coalesce(d.dist_net_sales,0)), abs(coalesce(p.pos_net_sales,0))), 0)
    end as delta_pct_net_sales
  from dist d
  full outer join pos p
    on p.sale_date = d.sale_date
   and p.store_code = d.store_code
)
select
  j.sale_date,
  j.store_code,

  j.dist_net_sales,
  j.pos_net_sales,
  j.delta_net_sales,

  j.dist_gross_sales,
  j.pos_gross_sales,
  j.delta_gross_sales,

  j.dist_qty,
  j.pos_qty,
  j.delta_qty,

  j.delta_pct_net_sales,
  (select tolerance_pct from params) as tolerance_pct,

  case
    when j.sale_date is null or j.store_code is null then 'Fail'
    when j.delta_pct_net_sales <= (select tolerance_pct from params) then 'Pass'
    when j.delta_pct_net_sales <= (select tolerance_pct from params) * 2 then 'Warning'
    else 'Fail'
  end as status
from j
order by j.sale_date desc, j.store_code;

-- OLD VERSION:
-- -- 01_ops_command_center/sql/mart/recon/recon_sales_distributor_vs_pos.sql
-- -- Recon: Distributor daily vs POS daily (by store_key + day).

-- -- IMPORTANT: Edit the POS source in pos_src CTE to match your actual conformed POS table/view.
-- -- If you already have mart.fact_sales_pos_daily, swap pos_daily to read from that.

-- create schema if not exists mart;

-- create or replace view mart.recon_sales_distributor_vs_pos as
-- with params as (
--   select
--       (current_date - 90)::date as start_date
--     , 0.02::numeric             as pct_tolerance          -- 2% tolerance
--     , 100.00::numeric           as abs_tolerance          -- $100 tolerance (adjust to your scale)
-- )
-- , dist_daily as (
--   select
--       f.sale_date::date as sale_date
--     , f.store_code
--     , sum(f.net_sales)::numeric(18,2) as dist_net_sales
--   from mart.fact_sales_distributor_daily f
--   join params p on f.sale_date::date >= p.start_date
--   group by 1,2
-- )
-- , pos_src as (
--   -- ✅ CHANGE THIS to your POS conformed source.
--   -- Common candidates:
--   --   int.int_pos_dedup
--   --   stg.stg_pos_transactions
--   select
--       sold_at
--     , store_code
--     , net_sales
--   from int.int_sales_pos_dedup
-- )
-- , pos_daily as (
--   select
--       date_trunc('day', p.sold_at)::date as sale_date
--     , p.store_code
--     , sum(p.net_sales)::numeric(18,2)    as pos_net_sales
--   from pos_src p
--   join params par on date_trunc('day', p.sold_at)::date >= par.start_date
--   group by 1,2
-- )
-- , joined as (
--   select
--       coalesce(d.sale_date, p.sale_date) as sale_date
--     , coalesce(d.store_code,  p.store_code)  as store_code
--     , d.dist_net_sales
--     , p.pos_net_sales
--   from dist_daily d
--   full outer join pos_daily p
--     on d.sale_date = p.sale_date
--    and d.store_code  = p.store_code
-- )
-- select
--     j.sale_date
--   , j.store_code
--   , j.dist_net_sales
--   , j.pos_net_sales
--   , (coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0))::numeric(18,2) as diff_net_sales
--   , case
--       when greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0))) = 0 then 0
--       else
--         (abs(coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0))
--           / nullif(greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0))), 0)
--         )::numeric(18,4)
--     end as pct_diff
--   , case
--       when j.dist_net_sales is null then 'FAIL_missing_distributor'
--       when j.pos_net_sales  is null then 'FAIL_missing_pos'
--       when (
--         abs(coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0)) <= (select abs_tolerance from params)
--         or
--         (
--           greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0))) > 0
--           and
--           (abs(coalesce(j.dist_net_sales,0) - coalesce(j.pos_net_sales,0))
--             / greatest(abs(coalesce(j.dist_net_sales,0)), abs(coalesce(j.pos_net_sales,0)))
--           ) <= (select pct_tolerance from params)
--         )
--       ) then 'PASS'
--       else 'FAIL_mismatch'
--     end as status
-- from joined j
-- order by j.sale_date desc, j.store_code;