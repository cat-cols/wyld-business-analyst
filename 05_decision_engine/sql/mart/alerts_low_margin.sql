-- ============================================================
-- Project 5: Decision Engine
-- Object: mart.alerts_low_margin
--
-- Purpose:
--   Identify store / SKU / channel combinations where recent
--   gross margin is below healthy operating thresholds.
--
-- Grain:
--   One row per store_code / sku / channel for the latest
--   28-day sales window.
--
-- Business question:
--   Where is margin unhealthy, and what action should we take?
--
-- Note:
--   This view uses mart.fact_sales_daily instead of
--   mart.kpi_gross_margin_daily because the alert needs SKU-level
--   detail. KPI views may be aggregated above SKU grain.
-- ============================================================

create schema if not exists mart;

create or replace view mart.alerts_low_margin as

with max_sales_date as (

    select
        max(sale_date) as max_sale_date
    from mart.fact_sales_daily

),

recent_sales as (

    select
        s.sale_date,
        s.store_code,
        s.sku,
        s.channel,

        coalesce(s.gross_sales, 0) as gross_sales,
        coalesce(s.discount_amount, 0) as discount_amount,
        coalesce(s.net_sales, 0) as net_sales,
        coalesce(s.cogs, 0) as cogs

    from mart.fact_sales_daily as s
    cross join max_sales_date as d
    where s.sale_date >= d.max_sale_date - interval '27 days'
      and s.sale_date <= d.max_sale_date

),

alert_grain as (

    select
        store_code,
        sku,
        channel,

        count(*) as source_day_count,

        sum(gross_sales) as gross_sales,
        sum(discount_amount) as discount_amount,
        sum(net_sales) as net_sales,
        sum(cogs) as cogs,

        sum(net_sales) - sum(cogs) as gross_margin,

        case
            when sum(net_sales) = 0 then null
            else (sum(net_sales) - sum(cogs)) / nullif(sum(net_sales), 0)
        end as gross_margin_pct,

        case
            when sum(gross_sales) = 0 then null
            else sum(discount_amount) / nullif(sum(gross_sales), 0)
        end as discount_rate

    from recent_sales
    group by
        store_code,
        sku,
        channel

),

labeled_alerts as (

    select
        store_code,
        sku,
        channel,
        source_day_count,
        gross_sales,
        discount_amount,
        net_sales,
        cogs,
        gross_margin,
        gross_margin_pct,
        discount_rate,

        case
            when net_sales < 100
                then 'monitor'

            when gross_margin_pct < 0.25 and net_sales >= 500
                then 'critical'

            when gross_margin_pct < 0.30 and net_sales >= 250
                then 'high'

            when gross_margin_pct < 0.35
                then 'medium'

            else 'healthy'
        end as severity,

        case
            when net_sales < 100
                then 'Sales volume is low; monitor before taking action.'

            when gross_margin_pct < 0.25 and net_sales >= 500
                then 'Gross margin is below 25% on meaningful sales volume.'

            when gross_margin_pct < 0.30 and net_sales >= 250
                then 'Gross margin is below 30% on moderate sales volume.'

            when gross_margin_pct < 0.35
                then 'Gross margin is below the watchlist threshold.'

            else 'Margin appears healthy.'
        end as why_flagged,

        case
            when net_sales < 100
                then 'Monitor; sales volume is too low for a strong decision.'

            when gross_margin_pct < 0.25 and discount_rate >= 0.20
                then 'Review promo depth and discounting strategy.'

            when gross_margin_pct < 0.25
                then 'Investigate pricing, COGS, or product margin erosion.'

            when gross_margin_pct < 0.30 and discount_rate >= 0.15
                then 'Check whether discounts are reducing margin below target.'

            when gross_margin_pct < 0.35
                then 'Add to margin watchlist and compare against trend.'

            else 'No immediate action required.'
        end as recommended_action

    from alert_grain

)

select
    store_code,
    sku,
    channel,
    source_day_count,
    gross_sales,
    discount_amount,
    net_sales,
    cogs,
    gross_margin,
    gross_margin_pct,
    discount_rate,
    severity,
    why_flagged,
    recommended_action,

    dense_rank() over (
        order by
            case
                when severity = 'critical' then 1
                when severity = 'high' then 2
                when severity = 'medium' then 3
                when severity = 'monitor' then 4
                else 5
            end,
            net_sales desc
    ) as alert_priority_rank

from labeled_alerts
where severity in ('critical', 'high', 'medium', 'monitor');