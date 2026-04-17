-- sql/dq/02_seed_dq_rules.sql

-- Quarterly Data Collection + QA/QC System
-- Purpose: seed the initial governed DQ rule catalog for quarterly intake validation

insert into dq.dq_rules (
    rule_name,
    rule_category,
    target_table,
    target_column,
    severity,
    threshold_pct,
    logic_description,
    business_rationale,
    owner_team,
    active_flag,
    effective_start_date
)
values

-- 1) Completeness
(
    'Required key present - retail sales',
    'completeness',
    'stg.stg_retail_account_sales_quarterly',
    'dispensary_account_id, sku_id, week_end_date',
    'critical',
    0.0000,
    'Retail sales records must contain quarter_id, week_end_date, dispensary_account_id, and sku_id.',
    'Missing required business keys prevents trusted joins, aggregation, and certified reporting.',
    'Sales Operations',
    true,
    current_date
),
(
    'Required key present - wholesale sales',
    'completeness',
    'stg.stg_wholesale_account_sales_quarterly',
    'wholesale_account_id, sku_id, week_end_date',
    'critical',
    0.0000,
    'Wholesale sales records must contain quarter_id, week_end_date, wholesale_account_id, and sku_id.',
    'Missing required business keys prevents trusted account-level and SKU-level reporting.',
    'Commercial / Wholesale',
    true,
    current_date
),

-- 2) Uniqueness
(
    'No duplicate business grain - retail sales',
    'uniqueness',
    'stg.stg_retail_account_sales_quarterly',
    'quarter_id, week_end_date, dispensary_account_id, sku_id',
    'critical',
    0.0000,
    'Retail sales data must be unique at quarter_id + week_end_date + dispensary_account_id + sku_id.',
    'Duplicate rows distort sales totals and downstream reconciliation.',
    'Sales Operations',
    true,
    current_date
),
(
    'No duplicate business grain - inventory',
    'uniqueness',
    'stg.stg_inventory_quarterly',
    'quarter_id, week_end_date, warehouse_id, sku_id',
    'critical',
    0.0000,
    'Inventory snapshots must be unique at quarter_id + week_end_date + warehouse_id + sku_id.',
    'Duplicate inventory snapshots distort on-hand balances and inventory reasonability checks.',
    'Supply Chain / Inventory Control',
    true,
    current_date
),

-- 3) Validity
(
    'Quarter dates within expected range',
    'validity',
    'stg.stg_retail_account_sales_quarterly',
    'week_end_date',
    'high',
    0.0000,
    'All weekly retail sales dates must fall within the expected reporting quarter window.',
    'Out-of-period records compromise quarter certification and comparability.',
    'Sales Operations',
    true,
    current_date
),
(
    'Weekly continuity by source - retail sales',
    'validity',
    'stg.stg_retail_account_sales_quarterly',
    'week_end_date',
    'medium',
    0.0000,
    'All expected reporting weeks must be present within the quarter for retail sales.',
    'Missing weeks create incomplete quarter reporting and misleading trends.',
    'Sales Operations',
    true,
    current_date
),
(
    'No negative quantity - inventory',
    'validity',
    'stg.stg_inventory_quarterly',
    'on_hand_units',
    'high',
    0.0000,
    'Inventory on-hand units must not be negative.',
    'Negative inventory balances indicate source errors or broken inventory logic.',
    'Supply Chain / Inventory Control',
    true,
    current_date
),
(
    'Revenue not negative unless adjustment flag exists',
    'validity',
    'stg.stg_trade_adjustments',
    'adjustment_amount',
    'high',
    0.0000,
    'Negative revenue-like adjustments must be supported by valid adjustment logic and reason codes.',
    'Unsupported negative revenue values can break revenue certification and reconciliation.',
    'Trade Marketing / Finance',
    true,
    current_date
),
(
    'Margin percent within tolerance',
    'validity',
    'stg.stg_wholesale_account_sales_quarterly',
    'gross_sales, net_sales',
    'medium',
    0.0100,
    'Implied margin or discount behavior must fall within defined business tolerance.',
    'Extreme margin outcomes may indicate pricing, discount, or source mapping issues.',
    'Commercial / Wholesale',
    true,
    current_date
),

-- 4) Timeliness
(
    'Approved template version submitted',
    'timeliness',
    'ops.intake_submission_log',
    'template_version',
    'critical',
    0.0000,
    'Each submitted quarterly file must use the approved template version for the reporting cycle.',
    'Unapproved templates cause schema drift and downstream validation failures.',
    'Finance',
    true,
    current_date
),
(
    'Submission timeliness against due date',
    'timeliness',
    'ops.intake_submission_log',
    'submitted_at, expected_by',
    'critical',
    0.0000,
    'Each expected quarterly submission must be received on or before its due date.',
    'Late submissions delay validation, reconciliation, and reporting certification.',
    'Finance',
    true,
    current_date
),

-- 5) Reconciliation
(
    'Sales vs Finance reconciliation within tolerance',
    'reconciliation',
    'cross_source.sales_finance_reconciliation',
    'net_sales, actual_amount',
    'critical',
    0.0100,
    'Quarterly sales totals must reconcile to finance actuals within the approved variance threshold.',
    'Cross-source mismatches reduce trust in certified quarterly reporting.',
    'Finance',
    true,
    current_date
);