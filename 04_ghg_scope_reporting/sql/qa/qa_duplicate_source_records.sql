\echo ''
\echo 'QA: duplicate source records control'

with duplicate_summary as (
    select
        source_system,
        count(distinct duplicate_business_key) as duplicate_groups,
        count(*) as duplicate_rows
    from mart.controls_duplicate_source_records
    group by source_system
)
select
    source_system,
    duplicate_groups,
    duplicate_rows
from duplicate_summary
order by source_system;

do $$
declare
    v_duplicate_rows integer;
begin
    select count(*)
    into v_duplicate_rows
    from mart.controls_duplicate_source_records;

    if v_duplicate_rows > 0 then
        raise notice 'WARNING: % source rows are part of duplicate source-record groups. Review mart.controls_duplicate_source_records before certification.', v_duplicate_rows;
    else
        raise notice 'PASS: no duplicate source records found.';
    end if;
end $$;