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

-- Retail date-validity summary block
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
retail_date_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'Quarter dates within expected range'
      and active_flag = true
),
retail_date_checked as (
    select count(*) as checked_count
    from stg.stg_retail_account_sales_quarterly
),
retail_date_failed as (
    select
        quarter_id,
        week_end_date,
        dispensary_account_id,
        sku_id,
        'week_end_date=' || week_end_date::text as issue_value
    from stg.stg_retail_account_sales_quarterly
    where week_end_date < date '2026-01-01'
       or week_end_date > date '2026-03-31'
),
retail_date_failed_count as (
    select count(*) as failed_count
    from retail_date_failed
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
cross join retail_date_rule rr
cross join retail_date_checked rc
cross join retail_date_failed_count rf;

-- Retail date-validity exception block
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
retail_date_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'Quarter dates within expected range'
      and active_flag = true
),
retail_date_failed as (
    select
        quarter_id,
        week_end_date,
        dispensary_account_id,
        sku_id,
        'week_end_date=' || week_end_date::text as issue_value
    from stg.stg_retail_account_sales_quarterly
    where week_end_date < date '2026-01-01'
       or week_end_date > date '2026-03-31'
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
    issue_value,
    'Retail sales week_end_date falls outside expected quarter range',
    'Sales Operations',
    'open'
from latest_run lr
cross join retail_date_rule rr
cross join retail_date_failed;

-- Inventory negative-quantity summary block
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
inventory_negative_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'No negative quantity - inventory'
      and active_flag = true
),
inventory_negative_checked as (
    select count(*) as checked_count
    from stg.stg_inventory_quarterly
),
inventory_negative_failed as (
    select
        quarter_id,
        week_end_date,
        warehouse_id,
        sku_id,
        'on_hand_units=' || on_hand_units::text as issue_value
    from stg.stg_inventory_quarterly
    where on_hand_units < 0
),
inventory_negative_failed_count as (
    select count(*) as failed_count
    from inventory_negative_failed
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
cross join inventory_negative_rule ir
cross join inventory_negative_checked ic
cross join inventory_negative_failed_count ifc;

-- Inventory negative-quantity exception block
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
inventory_negative_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'No negative quantity - inventory'
      and active_flag = true
),
inventory_negative_failed as (
    select
        quarter_id,
        week_end_date,
        warehouse_id,
        sku_id,
        'on_hand_units=' || on_hand_units::text as issue_value
    from stg.stg_inventory_quarterly
    where on_hand_units < 0
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
    'Inventory on_hand_units is negative',
    'Supply Chain / Inventory Control',
    'open'
from latest_run lr
cross join inventory_negative_rule ir
cross join inventory_negative_failed;

-- Trade-adjustment reason-code summary block
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
trade_reason_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'Negative trade adjustments require valid reason code'
      and active_flag = true
),
trade_reason_checked as (
    select count(*) as checked_count
    from stg.stg_trade_adjustments
),
trade_reason_failed as (
    select
        quarter_id,
        adjustment_id,
        account_id,
        adjustment_type,
        adjustment_amount,
        reason_code,
        'adjustment_amount=' || adjustment_amount::text || ' and reason_code is null' as issue_value
    from stg.stg_trade_adjustments
    where adjustment_amount < 0
      and reason_code is null
),
trade_reason_failed_count as (
    select count(*) as failed_count
    from trade_reason_failed
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
    tr.rule_id,
    'stg.stg_trade_adjustments',
    tc.checked_count,
    tf.failed_count,
    case
        when tc.checked_count = 0 then 0::numeric
        else tf.failed_count::numeric / tc.checked_count::numeric
    end,
    tr.severity,
    case
        when tf.failed_count > 0 then 'fail'
        else 'pass'
    end
from latest_run r
cross join trade_reason_rule tr
cross join trade_reason_checked tc
cross join trade_reason_failed_count tf;


-- Trade-adjustment reason-code exception block
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
trade_reason_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'Negative trade adjustments require valid reason code'
      and active_flag = true
),
trade_reason_failed as (
    select
        quarter_id,
        adjustment_id,
        adjustment_amount,
        reason_code,
        'adjustment_amount=' || adjustment_amount::text || ' and reason_code is null' as issue_value
    from stg.stg_trade_adjustments
    where adjustment_amount < 0
      and reason_code is null
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
    tr.rule_id,
    'stg.stg_trade_adjustments',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(adjustment_id, 'MISSING')
    ),
    issue_value,
    'Negative trade adjustment is missing a required reason code',
    'Trade Marketing / Finance',
    'open'
from latest_run lr
cross join trade_reason_rule tr
cross join trade_reason_failed;

-- Trade-adjustment date validity check
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
trade_date_rule as (
    select rule_id, severity
    from dq.dq_rules
    where rule_name = 'Quarter dates within expected range - trade adjustments'
      and active_flag = true
),
trade_date_checked as (
    select count(*) as checked_count
    from stg.stg_trade_adjustments
),
trade_date_failed as (
    select
        quarter_id,
        adjustment_id,
        adjustment_date,
        'adjustment_date=' || adjustment_date::text as issue_value
    from stg.stg_trade_adjustments
    where adjustment_date < date '2026-01-01'
       or adjustment_date > date '2026-03-31'
),
trade_date_failed_count as (
    select count(*) as failed_count
    from trade_date_failed
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
    tr.rule_id,
    'stg.stg_trade_adjustments',
    tc.checked_count,
    tf.failed_count,
    case
        when tc.checked_count = 0 then 0::numeric
        else tf.failed_count::numeric / tc.checked_count::numeric
    end,
    tr.severity,
    case
        when tf.failed_count > 0 then 'fail'
        else 'pass'
    end
from latest_run r
cross join trade_date_rule tr
cross join trade_date_checked tc
cross join trade_date_failed_count tf;

--
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
trade_date_rule as (
    select rule_id
    from dq.dq_rules
    where rule_name = 'Quarter dates within expected range - trade adjustments'
      and active_flag = true
),
trade_date_failed as (
    select
        quarter_id,
        adjustment_id,
        adjustment_date,
        'adjustment_date=' || adjustment_date::text as issue_value
    from stg.stg_trade_adjustments
    where adjustment_date < date '2026-01-01'
       or adjustment_date > date '2026-03-31'
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
    tr.rule_id,
    'stg.stg_trade_adjustments',
    concat_ws(
        '|',
        coalesce(quarter_id, 'MISSING'),
        coalesce(adjustment_id, 'MISSING')
    ),
    issue_value,
    'Trade adjustment date falls outside expected quarter range',
    'Trade Marketing / Finance',
    'open'
from latest_run lr
cross join trade_date_rule tr
cross join trade_date_failed;

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
