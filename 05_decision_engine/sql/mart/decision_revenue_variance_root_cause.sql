-- ============================================================
-- Project 5: Decision Engine
-- Object: mart.decision_revenue_variance_root_cause
--
-- Purpose:
--   Compares recent sales performance against the prior period
--   and labels the likely revenue driver:
--     - volume-driven change
--     - price-driven change
--     - new/growing business
--     - lost/declining business
--
-- Grain:
--   One row per store_code / sku / channel for the comparison window.
--
-- Business question:
--   Why did revenue change, and where is the change concentrated?
-- ============================================================

create schema if not exists mart;

create or replace view mart.decision_revenue_variance_root_cause as

with max_sales_date as (

    select
        max(sale_date) as max_sale_date
    from mart.fact_sales_daily

),

sales_window as (

    select
        s.sale_date,
        s.store_code,
        s.sku,
        s.channel,
        coalesce(s.qty, 0) as units_sold,
        coalesce(s.net_sales, 0) as net_sales
    from mart.fact_sales_daily as s
    cross join max_sales_date as m
    where s.sale_date >= m.max_sale_date - interval '55 days'
      and s.sale_date <= m.max_sale_date

),

periodized_sales as (

    select
        sale_date,
        store_code,
        sku,
        channel,
        units_sold,
        net_sales,

        case
            when sale_date >= (
                select max_sale_date - interval '27 days'
                from max_sales_date
            )
                then 'current_28_days'

            when sale_date >= (
                select max_sale_date - interval '55 days'
                from max_sales_date
            )
            and sale_date < (
                select max_sale_date - interval '27 days'
                from max_sales_date
            )
                then 'prior_28_days'

            else 'outside_window'
        end as comparison_period

    from sales_window

),

period_rollup as (

    select
        comparison_period,
        store_code,
        sku,
        channel,
        sum(units_sold) as units_sold,
        sum(net_sales) as net_sales
    from periodized_sales
    where comparison_period in ('current_28_days', 'prior_28_days')
    group by
        comparison_period,
        store_code,
        sku,
        channel

),

comparison_pivot as (

    select
        store_code,
        sku,
        channel,

        sum(case when comparison_period = 'current_28_days' then units_sold else 0 end) as current_units_sold,
        sum(case when comparison_period = 'prior_28_days' then units_sold else 0 end) as prior_units_sold,

        sum(case when comparison_period = 'current_28_days' then net_sales else 0 end) as current_net_sales,
        sum(case when comparison_period = 'prior_28_days' then net_sales else 0 end) as prior_net_sales

    from period_rollup
    group by
        store_code,
        sku,
        channel

),

variance_calc as (

    select
        store_code,
        sku,
        channel,

        current_units_sold,
        prior_units_sold,
        current_net_sales,
        prior_net_sales,

        current_net_sales - prior_net_sales as net_sales_variance,

        case
            when prior_net_sales = 0 then null
            else (current_net_sales - prior_net_sales) / nullif(prior_net_sales, 0)
        end as net_sales_variance_pct,

        case
            when current_units_sold = 0 then null
            else current_net_sales / nullif(current_units_sold, 0)
        end as current_avg_net_price,

        case
            when prior_units_sold = 0 then null
            else prior_net_sales / nullif(prior_units_sold, 0)
        end as prior_avg_net_price

    from comparison_pivot

),

driver_calc as (

    select
        *,

        -- Approximate volume effect:
        -- If prior price stayed the same, how much did revenue change
        -- because units changed?
        (
            (current_units_sold - prior_units_sold)
            *
            coalesce(prior_avg_net_price, current_avg_net_price, 0)
        ) as estimated_volume_effect,

        -- Approximate price effect:
        -- If current units stayed the same, how much did revenue change
        -- because average price changed?
        (
            (coalesce(current_avg_net_price, 0) - coalesce(prior_avg_net_price, 0))
            *
            current_units_sold
        ) as estimated_price_effect

    from variance_calc

),

labeled as (

    select
        store_code,
        sku,
        channel,

        current_units_sold,
        prior_units_sold,
        current_net_sales,
        prior_net_sales,
        net_sales_variance,
        net_sales_variance_pct,
        current_avg_net_price,
        prior_avg_net_price,
        estimated_volume_effect,
        estimated_price_effect,

        case
            when prior_net_sales = 0 and current_net_sales > 0
                then 'New / growing business'

            when prior_net_sales > 0 and current_net_sales = 0
                then 'Lost / declining business'

            when net_sales_variance < 0
             and abs(estimated_volume_effect) >= abs(estimated_price_effect)
                then 'Volume-driven decline'

            when net_sales_variance < 0
             and abs(estimated_price_effect) > abs(estimated_volume_effect)
                then 'Price-driven decline'

            when net_sales_variance > 0
             and abs(estimated_volume_effect) >= abs(estimated_price_effect)
                then 'Volume-driven growth'

            when net_sales_variance > 0
             and abs(estimated_price_effect) > abs(estimated_volume_effect)
                then 'Price-driven growth'

            else 'Stable / low movement'
        end as primary_revenue_driver,

        case
            when prior_net_sales = 0 and current_net_sales > 0
                then 'Review what changed and consider expanding distribution or support.'

            when prior_net_sales > 0 and current_net_sales = 0
                then 'Investigate lost sales, distribution gaps, account issues, or discontinued demand.'

            when net_sales_variance < 0
             and abs(estimated_volume_effect) >= abs(estimated_price_effect)
                then 'Investigate demand decline, inventory availability, account performance, or lost distribution.'

            when net_sales_variance < 0
             and abs(estimated_price_effect) > abs(estimated_volume_effect)
                then 'Review pricing, discounting, promo activity, or channel price pressure.'

            when net_sales_variance > 0
             and abs(estimated_volume_effect) >= abs(estimated_price_effect)
                then 'Protect supply and consider expanding high-performing store/SKU/channel combinations.'

            when net_sales_variance > 0
             and abs(estimated_price_effect) > abs(estimated_volume_effect)
                then 'Review whether price improvement is sustainable without hurting demand.'

            else 'Monitor; no immediate action required.'
        end as recommended_action

    from driver_calc

)

select
    store_code,
    sku,
    channel,

    current_units_sold,
    prior_units_sold,
    current_net_sales,
    prior_net_sales,
    net_sales_variance,
    net_sales_variance_pct,
    current_avg_net_price,
    prior_avg_net_price,
    estimated_volume_effect,
    estimated_price_effect,
    primary_revenue_driver,
    recommended_action,

    dense_rank() over (
        order by abs(net_sales_variance) desc
    ) as variance_impact_rank

from labeled;