\echo 'QA: source owner certifications'

select
    source_system,
    owner_team,
    certifier_name,
    certification_status,
    certified_through,
    last_certified_at,
    notes
from qa.source_owner_certifications
order by source_system;

do $$
begin
    if exists (
        select distinct source_system
        from mart.fact_emissions
        except
        select source_system
        from qa.source_owner_certifications
    ) then
        raise exception 'QA failed: one or more source systems are missing source owner certification records';
    end if;

    if exists (
        select 1
        from qa.source_owner_certifications
        where lower(certification_status) <> 'certified'
           or certified_through < current_date
    ) then
        raise exception 'QA failed: one or more source owner certifications are missing, expired, or not certified';
    end if;
end $$;

select 'PASS: source owner certifications are present and current' as qa_result;
