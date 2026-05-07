\echo 'QA: control view counts reconcile to fact flags'

do $$
declare
    fact_unknown_count integer;
    control_unknown_count integer;

    fact_negative_count integer;
    control_negative_count integer;

    fact_missing_factor_count integer;
    control_missing_factor_count integer;

    fact_missing_dim_count integer;
    control_missing_dim_count integer;
begin
    select count(*)
    into fact_unknown_count
    from mart.fact_emissions
    where has_unknown_activity_type;

    select count(*)
    into control_unknown_count
    from mart.controls_unknown_activity_type;

    if fact_unknown_count <> control_unknown_count then
        raise exception 'QA failed: unknown activity control count does not match fact flag count';
    end if;


    select count(*)
    into fact_negative_count
    from mart.fact_emissions
    where has_negative_activity;

    select count(*)
    into control_negative_count
    from mart.controls_negative_activity;

    if fact_negative_count <> control_negative_count then
        raise exception 'QA failed: negative activity control count does not match fact flag count';
    end if;


    select count(*)
    into fact_missing_factor_count
    from mart.fact_emissions
    where has_missing_factor_join;

    select count(*)
    into control_missing_factor_count
    from mart.controls_missing_factor_joins;

    if fact_missing_factor_count <> control_missing_factor_count then
        raise exception 'QA failed: missing factor control count does not match fact flag count';
    end if;


    select count(*)
    into fact_missing_dim_count
    from mart.fact_emissions
    where has_missing_facility_join
       or has_missing_product_line_join;

    select count(*)
    into control_missing_dim_count
    from mart.controls_missing_dim_joins;

    if fact_missing_dim_count <> control_missing_dim_count then
        raise exception 'QA failed: missing dimension control count does not match fact flag count';
    end if;
end $$;

select
    'PASS: control view counts reconcile to mart.fact_emissions flags' as qa_result;