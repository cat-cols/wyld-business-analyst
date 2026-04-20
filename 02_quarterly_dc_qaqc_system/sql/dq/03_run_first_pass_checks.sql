-- sql/dq/03_run_first_pass_checks.sql
-- Quarterly Data Collection + QA/QC System
-- Purpose: run first-pass DQ checks and persist summary + exception results

-- First-pass implementation: retail required-key summary + exception detail
with run_row as (
    insert into dq.dq_run_log (
        quarter_id,
        run_by,
        source_batch_name,
        rules_version,
        run_status
    )
    values (
        '2026Q1',
        'manual_run',
        '2026Q1_initial_load',
        'v1',
        'started'
    )
    returning run_id, quarter_id
),

retail_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'Required key present - retail sales'
      and active_flag = true
),

retail_checked as (
    select count(*) as checked_count
    from stg.stg_retail_account_sales_quarterly
),

retail_failed as (
    select
        quarter_id,
        week_end_date,
        dispensary_account_id,
        sku_id,
        case
            when quarter_id is null then 'quarter_id is null'
            when week_end_date is null then 'week_end_date is null'
            when dispensary_account_id is null then 'dispensary_account_id is null'
            when sku_id is null then 'sku_id is null'
        end as issue_value
    from stg.stg_retail_account_sales_quarterly
    where quarter_id is null
       or week_end_date is null
       or dispensary_account_id is null
       or sku_id is null
),

retail_failed_count as (
    select count(*) as failed_count
    from retail_failed
)

insert into dq.dq_results_fact (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    checked_count,
    failed_count,
    failed_pct,
    severity,
    status
)
select
    r.run_id,
    r.quarter_id,
    rr.rule_id,
    'stg.stg_retail_account_sales_quarterly',
    rc.checked_count,
    rf.failed_count,
    case
        when rc.checked_count = 0 then 0::numeric
        else rf.failed_count::numeric / rc.checked_count::numeric
    end as failed_pct,
    rr.severity,
    case
        when rf.failed_count > 0 then 'fail'
        else 'pass'
    end as status
from run_row r
cross join retail_rule rr
cross join retail_checked rc
cross join retail_failed_count rf;

-- retail issues
with latest_run as (
    select run_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
retail_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'Required key present - retail sales'
      and active_flag = true
),
retail_failed as (
    select
        quarter_id,
        week_end_date,
        dispensary_account_id,
        sku_id,
        case
            when quarter_id is null then 'quarter_id is null'
            when week_end_date is null then 'week_end_date is null'
            when dispensary_account_id is null then 'dispensary_account_id is null'
            when sku_id is null then 'sku_id is null'
        end as issue_value
    from stg.stg_retail_account_sales_quarterly
    where quarter_id is null
       or week_end_date is null
       or dispensary_account_id is null
       or sku_id is null
)
insert into dq.dq_exceptions_detail (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    record_key,
    issue_value,
    issue_description,
    assigned_team,
    remediation_status
)
select
    lr.run_id,
    '2026Q1',
    rr.rule_id,
    'stg.stg_retail_account_sales_quarterly',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(week_end_date::text, 'MISSING'),
        coalesce(dispensary_account_id, 'MISSING'),
        coalesce(sku_id, 'MISSING')
    ) as record_key,
    issue_value,
    'Required key missing in retail sales submission',
    'Sales Operations',
    'open'
from latest_run lr
cross join retail_rule rr
cross join retail_failed;

-- wholesale
with latest_run as (
    select run_id, quarter_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
wholesale_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'Required key present - wholesale sales'
      and active_flag = true
),
wholesale_checked as (
    select count(*) as checked_count
    from stg.stg_wholesale_account_sales_quarterly
),
wholesale_failed as (
    select
        quarter_id,
        week_end_date,
        wholesale_account_id,
        sku_id,
        case
            when quarter_id is null then 'quarter_id is null'
            when week_end_date is null then 'week_end_date is null'
            when wholesale_account_id is null then 'wholesale_account_id is null'
            when sku_id is null then 'sku_id is null'
        end as issue_value
    from stg.stg_wholesale_account_sales_quarterly
    where quarter_id is null
       or week_end_date is null
       or wholesale_account_id is null
       or sku_id is null
),
wholesale_failed_count as (
    select count(*) as failed_count
    from wholesale_failed
)
insert into dq.dq_results_fact (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    checked_count,
    failed_count,
    failed_pct,
    severity,
    status
)
select
    r.run_id,
    r.quarter_id,
    wr.rule_id,
    'stg.stg_wholesale_account_sales_quarterly',
    wc.checked_count,
    wf.failed_count,
    case
        when wc.checked_count = 0 then 0::numeric
        else wf.failed_count::numeric / wc.checked_count::numeric
    end,
    wr.severity,
    case
        when wf.failed_count > 0 then 'fail'
        else 'pass'
    end
from latest_run r
cross join wholesale_rule wr
cross join wholesale_checked wc
cross join wholesale_failed_count wf;

with latest_run as (
    select run_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
wholesale_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'Required key present - wholesale sales'
      and active_flag = true
),
wholesale_failed as (
    select
        quarter_id,
        week_end_date,
        wholesale_account_id,
        sku_id,
        case
            when quarter_id is null then 'quarter_id is null'
            when week_end_date is null then 'week_end_date is null'
            when wholesale_account_id is null then 'wholesale_account_id is null'
            when sku_id is null then 'sku_id is null'
        end as issue_value
    from stg.stg_wholesale_account_sales_quarterly
    where quarter_id is null
       or week_end_date is null
       or wholesale_account_id is null
       or sku_id is null
)
insert into dq.dq_exceptions_detail (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    record_key,
    issue_value,
    issue_description,
    assigned_team,
    remediation_status
)
select
    lr.run_id,
    '2026Q1',
    wr.rule_id,
    'stg.stg_wholesale_account_sales_quarterly',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(week_end_date::text, 'MISSING'),
        coalesce(wholesale_account_id, 'MISSING'),
        coalesce(sku_id, 'MISSING')
    ),
    issue_value,
    'Required key missing in wholesale sales submission',
    'Commercial / Wholesale',
    'open'
from latest_run lr
cross join wholesale_rule wr
cross join wholesale_failed;

with latest_run as (
    select run_id, quarter_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
inventory_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'Required key present - inventory'
      and active_flag = true
),
inventory_checked as (
    select count(*) as checked_count
    from stg.stg_inventory_quarterly
),
inventory_failed as (
    select
        quarter_id,
        week_end_date,
        warehouse_id,
        sku_id,
        case
            when quarter_id is null then 'quarter_id is null'
            when week_end_date is null then 'week_end_date is null'
            when warehouse_id is null then 'warehouse_id is null'
            when sku_id is null then 'sku_id is null'
        end as issue_value
    from stg.stg_inventory_quarterly
    where quarter_id is null
       or week_end_date is null
       or warehouse_id is null
       or sku_id is null
),
inventory_failed_count as (
    select count(*) as failed_count
    from inventory_failed
)
insert into dq.dq_results_fact (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    checked_count,
    failed_count,
    failed_pct,
    severity,
    status
)
select
    r.run_id,
    r.quarter_id,
    ir.rule_id,
    'stg.stg_inventory_quarterly',
    ic.checked_count,
    ifc.failed_count,
    case
        when ic.checked_count = 0 then 0::numeric
        else ifc.failed_count::numeric / ic.checked_count::numeric
    end,
    ir.severity,
    case
        when ifc.failed_count > 0 then 'fail'
        else 'pass'
    end
from latest_run r
cross join inventory_rule ir
cross join inventory_checked ic
cross join inventory_failed_count ifc;

with latest_run as (
    select run_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
inventory_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'Required key present - inventory'
      and active_flag = true
),
inventory_failed as (
    select
        quarter_id,
        week_end_date,
        warehouse_id,
        sku_id,
        case
            when quarter_id is null then 'quarter_id is null'
            when week_end_date is null then 'week_end_date is null'
            when warehouse_id is null then 'warehouse_id is null'
            when sku_id is null then 'sku_id is null'
        end as issue_value
    from stg.stg_inventory_quarterly
    where quarter_id is null
       or week_end_date is null
       or warehouse_id is null
       or sku_id is null
)
insert into dq.dq_exceptions_detail (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    record_key,
    issue_value,
    issue_description,
    assigned_team,
    remediation_status
)
select
    lr.run_id,
    '2026Q1',
    ir.rule_id,
    'stg.stg_inventory_quarterly',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(week_end_date::text, 'MISSING'),
        coalesce(warehouse_id, 'MISSING'),
        coalesce(sku_id, 'MISSING')
    ),
    issue_value,
    'Required key missing in inventory submission',
    'Supply Chain / Inventory Control',
    'open'
from latest_run lr
cross join inventory_rule ir
cross join inventory_failed;

with latest_run as (
    select run_id, quarter_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
retail_dup_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'No duplicate business grain - retail sales'
      and active_flag = true
),
retail_checked as (
    select count(*) as checked_count
    from stg.stg_retail_account_sales_quarterly
),
retail_failed as (
    select
        quarter_id,
        week_end_date,
        dispensary_account_id,
        sku_id,
        count(*) as duplicate_row_count
    from stg.stg_retail_account_sales_quarterly
    group by 1,2,3,4
    having count(*) > 1
),
retail_failed_count as (
    select count(*) as failed_count
    from retail_failed
)
insert into dq.dq_results_fact (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    checked_count,
    failed_count,
    failed_pct,
    severity,
    status
)
select
    r.run_id,
    r.quarter_id,
    rr.rule_id,
    'stg.stg_retail_account_sales_quarterly',
    rc.checked_count,
    rf.failed_count,
    case
        when rc.checked_count = 0 then 0::numeric
        else rf.failed_count::numeric / rc.checked_count::numeric
    end,
    rr.severity,
    case
        when rf.failed_count > 0 then 'fail'
        else 'pass'
    end
from latest_run r
cross join retail_dup_rule rr
cross join retail_checked rc
cross join retail_failed_count rf;

with latest_run as (
    select run_id, quarter_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
wholesale_dup_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'No duplicate business grain - wholesale sales'
      and active_flag = true
),
wholesale_checked as (
    select count(*) as checked_count
    from stg.stg_wholesale_account_sales_quarterly
),
wholesale_failed as (
    select
        quarter_id,
        week_end_date,
        wholesale_account_id,
        sku_id,
        count(*) as duplicate_row_count
    from stg.stg_wholesale_account_sales_quarterly
    group by 1,2,3,4
    having count(*) > 1
),
wholesale_failed_count as (
    select count(*) as failed_count
    from wholesale_failed
)
insert into dq.dq_results_fact (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    checked_count,
    failed_count,
    failed_pct,
    severity,
    status
)
select
    r.run_id,
    r.quarter_id,
    wr.rule_id,
    'stg.stg_wholesale_account_sales_quarterly',
    wc.checked_count,
    wf.failed_count,
    case
        when wc.checked_count = 0 then 0::numeric
        else wf.failed_count::numeric / wc.checked_count::numeric
    end,
    wr.severity,
    case
        when wf.failed_count > 0 then 'fail'
        else 'pass'
    end
from latest_run r
cross join wholesale_dup_rule wr
cross join wholesale_checked wc
cross join wholesale_failed_count wf;

with latest_run as (
    select run_id, quarter_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
inventory_dup_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'No duplicate business grain - inventory'
      and active_flag = true
),
inventory_checked as (
    select count(*) as checked_count
    from stg.stg_inventory_quarterly
),
inventory_failed as (
    select
        quarter_id,
        week_end_date,
        warehouse_id,
        sku_id,
        count(*) as duplicate_row_count
    from stg.stg_inventory_quarterly
    group by 1,2,3,4
    having count(*) > 1
),
inventory_failed_count as (
    select count(*) as failed_count
    from inventory_failed
)
insert into dq.dq_results_fact (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    checked_count,
    failed_count,
    failed_pct,
    severity,
    status
)
select
    r.run_id,
    r.quarter_id,
    ir.rule_id,
    'stg.stg_inventory_quarterly',
    ic.checked_count,
    ifc.failed_count,
    case
        when ic.checked_count = 0 then 0::numeric
        else ifc.failed_count::numeric / ic.checked_count::numeric
    end,
    ir.severity,
    case
        when ifc.failed_count > 0 then 'fail'
        else 'pass'
    end
from latest_run r
cross join inventory_dup_rule ir
cross join inventory_checked ic
cross join inventory_failed_count ifc;

with latest_run as (
    select run_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
retail_dup_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'No duplicate business grain - retail sales'
      and active_flag = true
),
retail_failed as (
    select
        quarter_id,
        week_end_date,
        dispensary_account_id,
        sku_id,
        count(*) as duplicate_row_count
    from stg.stg_retail_account_sales_quarterly
    group by 1,2,3,4
    having count(*) > 1
)
insert into dq.dq_exceptions_detail (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    record_key,
    issue_value,
    issue_description,
    assigned_team,
    remediation_status
)
select
    lr.run_id,
    '2026Q1',
    rr.rule_id,
    'stg.stg_retail_account_sales_quarterly',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(week_end_date::text, 'MISSING'),
        coalesce(dispensary_account_id, 'MISSING'),
        coalesce(sku_id, 'MISSING')
    ),
    'duplicate_row_count=' || duplicate_row_count::text,
    'Duplicate retail sales business grain detected',
    'Sales Operations',
    'open'
from latest_run lr
cross join retail_dup_rule rr
cross join retail_failed;

with latest_run as (
    select run_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
wholesale_dup_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'No duplicate business grain - wholesale sales'
      and active_flag = true
),
wholesale_failed as (
    select
        quarter_id,
        week_end_date,
        wholesale_account_id,
        sku_id,
        count(*) as duplicate_row_count
    from stg.stg_wholesale_account_sales_quarterly
    group by 1,2,3,4
    having count(*) > 1
)
insert into dq.dq_exceptions_detail (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    record_key,
    issue_value,
    issue_description,
    assigned_team,
    remediation_status
)
select
    lr.run_id,
    '2026Q1',
    wr.rule_id,
    'stg.stg_wholesale_account_sales_quarterly',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(week_end_date::text, 'MISSING'),
        coalesce(wholesale_account_id, 'MISSING'),
        coalesce(sku_id, 'MISSING')
    ),
    'duplicate_row_count=' || duplicate_row_count::text,
    'Duplicate wholesale sales business grain detected',
    'Commercial / Wholesale',
    'open'
from latest_run lr
cross join wholesale_dup_rule wr
cross join wholesale_failed;

with latest_run as (
    select run_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
),
inventory_dup_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'No duplicate business grain - inventory'
      and active_flag = true
),
inventory_failed as (
    select
        quarter_id,
        week_end_date,
        warehouse_id,
        sku_id,
        count(*) as duplicate_row_count
    from stg.stg_inventory_quarterly
    group by 1,2,3,4
    having count(*) > 1
)
insert into dq.dq_exceptions_detail (
    run_id,
    quarter_id,
    rule_id,
    target_table,
    record_key,
    issue_value,
    issue_description,
    assigned_team,
    remediation_status
)
select
    lr.run_id,
    '2026Q1',
    ir.rule_id,
    'stg.stg_inventory_quarterly',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(week_end_date::text, 'MISSING'),
        coalesce(warehouse_id, 'MISSING'),
        coalesce(sku_id, 'MISSING')
    ),
    'duplicate_row_count=' || duplicate_row_count::text,
    'Duplicate inventory business grain detected',
    'Supply Chain / Inventory Control',
    'open'
from latest_run lr
cross join inventory_dup_rule ir
cross join inventory_failed;

--
update dq.dq_run_log
set run_status = 'completed'
where run_id = (
    select run_id
    from dq.dq_run_log
    where quarter_id = '2026Q1'
      and run_by = 'manual_run'
      and source_batch_name = '2026Q1_initial_load'
      and rules_version = 'v1'
    order by run_ts desc
    limit 1
);

-----------------
-- TEST INPUTS --
-----------------
-- retail
-- select * from dq.dq_run_log order by run_id desc;
-- select * from dq.dq_results_fact order by created_at desc;
-- select * from dq.dq_exceptions_detail order by created_at desc;

-- wholesale
-- inventory
