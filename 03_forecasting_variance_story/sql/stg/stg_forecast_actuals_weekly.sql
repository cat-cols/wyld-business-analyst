-- 03_forecasting_variance_story/sql/stg/stg_forecast_actuals_weekly.sql

create or replace view stg.stg_forecast_actuals_weekly as
select
    nullif(trim(week_start_date), '')::date as week_start_date,

    upper(trim(store_code)) as store_code,
    upper(trim(state)) as state,
    trim(region) as region,

    upper(trim(sku)) as sku,
    trim(product_name) as product_name,
    lower(trim(product_family)) as product_family,

    lower(trim(channel)) as channel,

    nullif(trim(forecast_units), '')::numeric as forecast_units,
    nullif(trim(actual_units), '')::numeric as actual_units,

    nullif(trim(forecast_net_sales), '')::numeric as forecast_net_sales,
    nullif(trim(actual_net_sales), '')::numeric as actual_net_sales,

    nullif(trim(forecast_unit_price), '')::numeric as forecast_unit_price,
    nullif(trim(actual_unit_price), '')::numeric as actual_unit_price,

    case
        when lower(trim(promo_flag)) in ('true', 't', '1', 'yes', 'y') then true
        when lower(trim(promo_flag)) in ('false', 'f', '0', 'no', 'n') then false
        else null
    end as promo_flag,

    case
        when lower(trim(stockout_flag)) in ('true', 't', '1', 'yes', 'y') then true
        when lower(trim(stockout_flag)) in ('false', 'f', '0', 'no', 'n') then false
        else null
    end as stockout_flag,

    case
        when lower(trim(is_partial_actual)) in ('true', 't', '1', 'yes', 'y') then true
        when lower(trim(is_partial_actual)) in ('false', 'f', '0', 'no', 'n') then false
        else null
    end as is_partial_actual,

    lower(trim(seasonality_label)) as seasonality_label,
    lower(trim(business_event)) as business_event,
    lower(trim(plan_version)) as plan_version,

    loaded_at

from raw.forecast_actuals_weekly;