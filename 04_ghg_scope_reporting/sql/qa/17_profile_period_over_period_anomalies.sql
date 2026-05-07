\echo 'QA profile: period-over-period emissions anomalies'

with monthly as (
    select
        source_system,
        scope,
        activity_month,
        round(sum(metric_tons_co2e) filter (where is_reportable_emissions_row), 6) as metric_tons_co2e
    from mart.fact_emissions
    group by
        source_system,
        scope,
        activity_month
),

with_lag as (
    select
        source_system,
        scope,
        activity_month,
        metric_tons_co2e,
        lag(metric_tons_co2e) over (
            partition by source_system, scope
            order by activity_month
        ) as prior_month_metric_tons_co2e
    from monthly
),

scored as (
    select
        source_system,
        scope,
        activity_month,
        metric_tons_co2e,
        prior_month_metric_tons_co2e,
        round(
            (metric_tons_co2e - prior_month_metric_tons_co2e)
            / nullif(prior_month_metric_tons_co2e, 0),
            6
        ) as mom_pct_change,
        case
            when prior_month_metric_tons_co2e is null then 'NO_PRIOR_PERIOD'
            when abs(
                (metric_tons_co2e - prior_month_metric_tons_co2e)
                / nullif(prior_month_metric_tons_co2e, 0)
            ) >= 0.50 then 'REVIEW_HIGH_VARIANCE'
            when abs(
                (metric_tons_co2e - prior_month_metric_tons_co2e)
                / nullif(prior_month_metric_tons_co2e, 0)
            ) >= 0.25 then 'WATCH_MODERATE_VARIANCE'
            else 'OK'
        end as anomaly_status
    from with_lag
)

select *
from scored
where anomaly_status <> 'OK'
order by
    source_system,
    scope,
    activity_month;

do $$
begin
    raise notice 'Period-over-period anomaly profile is informational. Review high-variance periods before certification.';
end $$;
