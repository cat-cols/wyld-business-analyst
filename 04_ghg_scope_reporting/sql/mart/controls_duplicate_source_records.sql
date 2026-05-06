drop view if exists mart.controls_duplicate_source_records cascade;

create view mart.controls_duplicate_source_records as
with candidate_records as (

    /*
    Electricity duplicate grain:
    Same month + facility + meter + invoice + usage amount + usage unit.
    */
    select
        'electricity_bills' as source_system,
        raw_row_id::text as source_record_id,
        activity_month,
        scope,
        facility_id,
        null::text as product_line_id,
        'electricity' as activity_category,
        factor_type,
        activity_amount,
        activity_unit,
        invoice_amount_usd as cost_usd,
        invoice_number as evidence_reference,

        'activity_month + facility_id + meter_number + invoice_number + activity_amount + activity_unit'
            as duplicate_key_definition,

        md5(concat_ws(
            '|',
            'electricity_bills',
            coalesce(activity_month::text, '<null>'),
            coalesce(facility_id, '<null>'),
            coalesce(meter_number, '<null>'),
            coalesce(invoice_number, '<null>'),
            coalesce(activity_amount::text, '<null>'),
            coalesce(activity_unit, '<null>')
        )) as duplicate_business_key

    from stg.stg_ghg_electricity_bills

    union all

    /*
    Fuel duplicate grain:
    Same month + facility + fuel type + invoice + amount + unit.
    */
    select
        'fuel_usage' as source_system,
        raw_row_id::text as source_record_id,
        activity_month,
        scope,
        facility_id,
        null::text as product_line_id,
        fuel_type as activity_category,
        factor_type,
        activity_amount,
        activity_unit,
        cost_usd,
        invoice_number as evidence_reference,

        'activity_month + facility_id + fuel_type + invoice_number + activity_amount + activity_unit'
            as duplicate_key_definition,

        md5(concat_ws(
            '|',
            'fuel_usage',
            coalesce(activity_month::text, '<null>'),
            coalesce(facility_id, '<null>'),
            coalesce(fuel_type, '<null>'),
            coalesce(invoice_number, '<null>'),
            coalesce(activity_amount::text, '<null>'),
            coalesce(activity_unit, '<null>')
        )) as duplicate_business_key

    from stg.stg_ghg_fuel_usage

    union all

    /*
    Shipping duplicate grain:
    Shipment ID should be unique when present.
    If shipment ID is missing, fall back to a shipment-detail composite key.
    */
    select
        'shipping_miles' as source_system,
        raw_row_id::text as source_record_id,
        activity_month,
        scope,
        facility_id,
        product_line_id,
        shipping_mode as activity_category,
        factor_type,
        activity_amount,
        activity_unit,
        freight_cost_usd as cost_usd,
        shipment_id as evidence_reference,

        case
            when shipment_id is not null
                then 'shipment_id'
            else 'shipment_date + facility_id + destination_state + product_line_id + shipping_mode + carrier + activity_amount'
        end as duplicate_key_definition,

        case
            when shipment_id is not null then md5(concat_ws(
                '|',
                'shipping_miles',
                'shipment_id',
                shipment_id
            ))
            else md5(concat_ws(
                '|',
                'shipping_miles',
                'missing_shipment_id',
                coalesce(shipment_date::text, '<null>'),
                coalesce(facility_id, '<null>'),
                coalesce(destination_state, '<null>'),
                coalesce(product_line_id, '<null>'),
                coalesce(shipping_mode, '<null>'),
                coalesce(carrier, '<null>'),
                coalesce(activity_amount::text, '<null>')
            ))
        end as duplicate_business_key

    from stg.stg_ghg_shipping_miles

    union all

    /*
    Packaging duplicate grain:
    Same month + facility + product line + material + invoice + material weight.
    */
    select
        'packaging_materials' as source_system,
        raw_row_id::text as source_record_id,
        activity_month,
        scope,
        facility_id,
        product_line_id,
        material_type as activity_category,
        factor_type,
        activity_amount,
        activity_unit,
        cost_usd,
        invoice_number as evidence_reference,

        'activity_month + facility_id + product_line_id + material_type + invoice_number + activity_amount + activity_unit'
            as duplicate_key_definition,

        md5(concat_ws(
            '|',
            'packaging_materials',
            coalesce(activity_month::text, '<null>'),
            coalesce(facility_id, '<null>'),
            coalesce(product_line_id, '<null>'),
            coalesce(material_type, '<null>'),
            coalesce(invoice_number, '<null>'),
            coalesce(activity_amount::text, '<null>'),
            coalesce(activity_unit, '<null>')
        )) as duplicate_business_key

    from stg.stg_ghg_packaging_materials
),

duplicate_groups as (
    select
        source_system,
        duplicate_business_key,
        duplicate_key_definition,
        count(*) as duplicate_record_count,
        string_agg(source_record_id, ', ' order by source_record_id::bigint) as duplicate_source_record_ids,
        min(activity_month) as first_activity_month,
        max(activity_month) as last_activity_month,
        sum(activity_amount) as duplicate_group_activity_amount,
        sum(cost_usd) as duplicate_group_cost_usd
    from candidate_records
    group by
        source_system,
        duplicate_business_key,
        duplicate_key_definition
    having count(*) > 1
),

duplicate_detail as (
    select
        c.source_system,
        c.duplicate_key_definition,
        c.duplicate_business_key,

        g.duplicate_record_count,
        g.duplicate_source_record_ids,
        g.first_activity_month,
        g.last_activity_month,
        g.duplicate_group_activity_amount,
        g.duplicate_group_cost_usd,

        c.source_record_id,
        c.activity_month,
        c.scope,
        c.facility_id,
        c.product_line_id,
        c.activity_category,
        c.factor_type,
        c.activity_amount,
        c.activity_unit,
        c.cost_usd,
        c.evidence_reference,

        fe.activity_id,
        fe.metric_tons_co2e,
        fe.is_reportable_emissions_row,
        fe.qa_status_label

    from candidate_records c
    inner join duplicate_groups g
        on c.source_system = g.source_system
       and c.duplicate_business_key = g.duplicate_business_key

    left join mart.fact_emissions fe
        on c.source_system = fe.source_system
       and c.source_record_id = fe.source_record_id
)

select
    source_system,
    duplicate_key_definition,
    duplicate_business_key,
    duplicate_record_count,
    duplicate_source_record_ids,
    first_activity_month,
    last_activity_month,

    duplicate_group_activity_amount,
    duplicate_group_cost_usd,

    sum(metric_tons_co2e) over (
        partition by source_system, duplicate_business_key
    ) as duplicate_group_metric_tons_co2e,

    source_record_id,
    activity_id,
    activity_month,
    scope,
    facility_id,
    product_line_id,
    activity_category,
    factor_type,
    activity_amount,
    activity_unit,
    cost_usd,
    evidence_reference,
    metric_tons_co2e,
    is_reportable_emissions_row,
    qa_status_label

from duplicate_detail
order by
    source_system,
    first_activity_month,
    duplicate_business_key,
    source_record_id::bigint;