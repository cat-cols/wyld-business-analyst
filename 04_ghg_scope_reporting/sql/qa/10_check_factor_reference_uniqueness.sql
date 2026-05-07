\echo 'QA: emission factor reference uniqueness'

do $$
begin
    if exists (
        select
            factor_type,
            activity_unit,
            region,
            effective_start,
            effective_end
        from stg.stg_ghg_emission_factors
        group by
            factor_type,
            activity_unit,
            region,
            effective_start,
            effective_end
        having count(*) > 1
    ) then
        raise exception 'QA failed: duplicate emission factor reference keys found';
    end if;
end $$;

select
    'PASS: emission factor reference keys are unique' as qa_result;