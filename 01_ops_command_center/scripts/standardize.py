#!/usr/bin/env python3
# scripts/standardize.py
"""
Standardize raw.* tables into standardized.* tables (clean columns, types, canonical values).

This is intentionally SQL-first to look like “real” analytics engineering.

Usage:
  export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_analytics"
  python3 scripts/standardize.py --run-id <the run you want to standardize>
If run-id not provided, it standardizes the latest-ish data by just selecting all rows.
"""

from __future__ import annotations

import argparse
import os


def _try_import_psycopg():
    try:
        import psycopg  # type: ignore
        return psycopg, "psycopg"
    except Exception:
        import psycopg2  # type: ignore
        return psycopg2, "psycopg2"


def pg_connect(dsn: str):
    mod, _ = _try_import_psycopg()
    return mod.connect(dsn)  # type: ignore


def qident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def exec_sql(con, sql: str, params=None) -> None:
    with con.cursor() as cur:
        cur.execute(sql, params)
    con.commit()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=os.getenv("PROJECT1_PG_DSN", ""))
    ap.add_argument("--raw-schema", default="raw")
    ap.add_argument("--std-schema", default="standardized")
    ap.add_argument("--run-id", default="", help="Optional filter: only standardize this run_id from raw tables where available")
    args = ap.parse_args()
    if not args.dsn.strip():
        raise SystemExit("Missing DSN. Set PROJECT1_PG_DSN or pass --dsn.")

    con = pg_connect(args.dsn)
    try:
        exec_sql(con, f"create schema if not exists {qident(args.std_schema)};")

        run_filter = ""
        if args.run_id.strip():
            # Some raw tables have run_id column; filter only where it exists.
            run_filter = " where run_id = %(run_id)s "

        # 1) sales distributor summary (header drift!)
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("sales_distributor_extract")} cascade;
            create table {qident(args.std_schema)}.{qident("sales_distributor_extract")} as
            select
              -- tolerate header drift by coalescing possible column names
              coalesce(nullif(trim("Store ID"), ''), nullif(trim("store_id"), '')) as store_id_raw,
              trim(coalesce("sku","SKU")) as sku,
              trim(coalesce("product_name","Product Name","product_name")) as product_name,
              lower(trim(coalesce("channel","Channel"))) as channel_raw,
              -- parse dates with multiple formats
              case
                when "Sale Date" ~ '^\d{{4}}-\d{{2}}-\d{{2}}$' then to_date("Sale Date",'YYYY-MM-DD')
                when "Sale Date" ~ '^\d{{2}}/\d{{2}}/\d{{4}}$' then to_date("Sale Date",'MM/DD/YYYY')
                else null
              end as sale_date,
              nullif(trim(coalesce("qty","Qty")), '')::bigint as qty,
              nullif(trim(coalesce("Unit List Price","unit_list_price")), '')::double precision as unit_list_price,
              nullif(trim(coalesce("Discount Rate","discount_rate")), '')::double precision as discount_rate,
              nullif(trim(coalesce("Unit Net Price","unit_net_price")), '')::double precision as unit_net_price,
              nullif(trim(coalesce("Gross Sales","gross_sales")), '')::double precision as gross_sales,
              nullif(trim(coalesce("Discount Amount","discount_amount")), '')::double precision as discount_amount,
              nullif(trim(coalesce("Net Sales","net_sales")), '')::double precision as net_sales,
              nullif(trim(coalesce("cogs","COGS")), '')::double precision as cogs,
              nullif(trim(coalesce("orders","Orders")), '')::bigint as orders,
              nullif(trim(coalesce("customers","Customers")), '')::bigint as customers,
              run_id,
              ingested_at::text as ingested_at,
              source_file
            from {qident(args.raw_schema)}.{qident("sales_distributor_extract")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # canonicalize store_id and channel in-place via a view-y pattern (keep it simple)
        exec_sql(
            con,
            f"""
            alter table {qident(args.std_schema)}.{qident("sales_distributor_extract")}
            add column store_id text,
            add column channel text;

            update {qident(args.std_schema)}.{qident("sales_distributor_extract")}
            set
              store_id = upper(regexp_replace(coalesce(store_id_raw,''), '[^A-Za-z0-9]', '', 'g')),
              channel =
                case
                  when channel_raw like '%retail%' then 'retail'
                  when channel_raw like '%wholesale%' then 'wholesale'
                  when channel_raw like '%distributor%' then 'distributor'
                  else null
                end
            ;
            """,
        )

        # 2) POS transactions (file-ingested)
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("pos_transactions")} cascade;
            create table {qident(args.std_schema)}.{qident("pos_transactions")} as
            select
              nullif(trim(txn_id), '')::bigint as txn_id,
              case
                when txn_ts ~ '^\d{{4}}-\d{{2}}-\d{{2}} ' then to_timestamp(txn_ts,'YYYY-MM-DD HH24:MI:SS')
                when txn_ts ~ '^\d{{2}}/\d{{2}}/\d{{4}} ' then to_timestamp(txn_ts,'MM/DD/YYYY HH24:MI')
                else null
              end as txn_ts,
              upper(regexp_replace(coalesce(store_code,''), '[^A-Za-z0-9]', '', 'g')) as store_id,
              trim(product_sku) as sku,
              nullif(trim(qty), '')::bigint as qty,
              nullif(trim(unit_price), '')::double precision as unit_price,
              nullif(trim(discount_pct), '')::double precision as discount_pct,
              nullif(trim(gross_amount), '')::double precision as gross_amount,
              nullif(trim(net_amount), '')::double precision as net_amount,
              run_id,
              ingested_at,
              source_file
            from {qident(args.raw_schema)}.{qident("pos_transactions_csv")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # 3) inventory snapshot
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("inventory_erp_snapshot")} cascade;
            create table {qident(args.std_schema)}.{qident("inventory_erp_snapshot")} as
            select
              case
                when "Snapshot Date" ~ '^\d{{4}}-\d{{2}}-\d{{2}}$' then to_date("Snapshot Date",'YYYY-MM-DD')
                when "Snapshot Date" ~ '^\d{{2}}/\d{{2}}/\d{{4}}$' then to_date("Snapshot Date",'MM/DD/YYYY')
                else null
              end as snapshot_date,
              upper(regexp_replace(coalesce("Site Code",''), '[^A-Za-z0-9]', '', 'g')) as store_id,
              trim(sku) as sku,
              nullif(trim("On Hand"), '')::bigint as on_hand,
              nullif(trim(receipts), '')::bigint as receipts,
              nullif(trim(shipments), '')::bigint as shipments,
              nullif(trim("Requested Units"), '')::bigint as requested_units,
              nullif(trim("Backordered Units"), '')::bigint as backordered_units,
              run_id,
              ingested_at,
              source_file
            from {qident(args.raw_schema)}.{qident("inventory_erp_snapshot")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # 4) WMS shipments
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("wms_shipments")} cascade;
            create table {qident(args.std_schema)}.{qident("wms_shipments")} as
            select
              case
                when ship_date ~ '^\d{{4}}-\d{{2}}-\d{{2}}$' then to_date(ship_date,'YYYY-MM-DD')
                when ship_date ~ '^\d{{2}}/\d{{2}}/\d{{4}}$' then to_date(ship_date,'MM/DD/YYYY')
                else null
              end as ship_date,
              trim(shipment_id) as shipment_id,
              upper(regexp_replace(coalesce(site_code,''), '[^A-Za-z0-9]', '', 'g')) as store_id,
              trim(sku) as sku,
              nullif(trim(units_shipped), '')::bigint as units_shipped,
              trim(carrier) as carrier,
              run_id,
              ingested_at,
              source_file
            from {qident(args.raw_schema)}.{qident("wms_shipments")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # 5) timeclock punches
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("timeclock_punches")} cascade;
            create table {qident(args.std_schema)}.{qident("timeclock_punches")} as
            select
              case
                when punch_ts ~ '^\d{{4}}-\d{{2}}-\d{{2}} ' then to_timestamp(punch_ts,'YYYY-MM-DD HH24:MI:SS')
                when punch_ts ~ '^\d{{2}}/\d{{2}}/\d{{4}} ' then to_timestamp(punch_ts,'MM/DD/YYYY HH24:MI')
                else null
              end as punch_ts,
              nullif(trim(employee_id), '')::bigint as employee_id,
              upper(regexp_replace(coalesce(site_code,''), '[^A-Za-z0-9]', '', 'g')) as store_id,
              upper(trim(action)) as action,
              run_id,
              ingested_at,
              source_file
            from {qident(args.raw_schema)}.{qident("timeclock_punches")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # 6) payroll weekly
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("labor_hours_payroll")} cascade;
            create table {qident(args.std_schema)}.{qident("labor_hours_payroll")} as
            select
              case
                when "Week Ending" ~ '^\d{{4}}-\d{{2}}-\d{{2}}$' then to_date("Week Ending",'YYYY-MM-DD')
                when "Week Ending" ~ '^\d{{2}}/\d{{2}}/\d{{4}}$' then to_date("Week Ending",'MM/DD/YYYY')
                else null
              end as week_ending,
              upper(regexp_replace(coalesce("Site Code",''), '[^A-Za-z0-9]', '', 'g')) as store_id,
              trim(department) as department,
              trim(team) as team,
              nullif(trim("Hours Worked"), '')::double precision as hours_worked,
              nullif(trim("OT Hours"), '')::double precision as ot_hours,
              nullif(trim("Employee Count"), '')::bigint as employee_count,
              nullif(trim("Labor Cost"), '')::double precision as labor_cost,
              run_id,
              ingested_at,
              source_file
            from {qident(args.raw_schema)}.{qident("labor_hours_payroll_export")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # 7) finance actuals monthly
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("finance_actuals_summary")} cascade;
            create table {qident(args.std_schema)}.{qident("finance_actuals_summary")} as
            select
              to_date("Month Start", 'YYYY-MM-DD') as month_start,
              lower(trim("Metric Name")) as metric_name_raw,
              nullif(trim("Actual Amount"), '')::double precision as actual_amount,
              trim("Currency") as currency,
              run_id,
              ingested_at,
              source_file,
              case
                when lower(trim("Metric Name")) like '%gross sales%' then 'gross_sales'
                when lower(trim("Metric Name")) like '%net sales%' then 'net_sales'
                when lower(trim("Metric Name")) like '%cogs%' or lower(trim("Metric Name")) like '%cost of goods%' then 'cogs'
                when lower(trim("Metric Name")) like '%gross margin%' then 'gross_margin'
                when lower(trim("Metric Name")) like '%labor cost%' then 'labor_cost'
                else null
              end as metric_name
            from {qident(args.raw_schema)}.{qident("finance_actuals_summary")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # 8) GL detail CSV extract (file ingested)
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.std_schema)}.{qident("gl_detail")} cascade;
            create table {qident(args.std_schema)}.{qident("gl_detail")} as
            select
              trim(period) as period,
              case
                when posting_date ~ '^\d{{4}}-\d{{2}}-\d{{2}}$' then to_date(posting_date,'YYYY-MM-DD')
                when posting_date ~ '^\d{{2}}/\d{{2}}/\d{{4}}$' then to_date(posting_date,'MM/DD/YYYY')
                else null
              end as posting_date,
              upper(regexp_replace(coalesce(location_code,''), '[^A-Za-z0-9]', '', 'g')) as store_id,
              trim(regexp_replace(coalesce(account_code,''), '[^0-9]', '', 'g')) as account_code,
              trim(account_name) as account_name,
              nullif(trim(debit_amount), '')::double precision as debit_amount,
              nullif(trim(credit_amount), '')::double precision as credit_amount,
              (nullif(trim(debit_amount), '')::double precision - nullif(trim(credit_amount), '')::double precision) as net_amount,
              run_id,
              ingested_at,
              source_file
            from {qident(args.raw_schema)}.{qident("gl_detail_csv")}
            {run_filter}
            ;
            """,
            {"run_id": args.run_id} if args.run_id.strip() else None,
        )

        # helpful indexes (not required, but nice)
        exec_sql(con, f"create index if not exists idx_std_pos_store_ts on {qident(args.std_schema)}.{qident('pos_transactions')} (store_id, txn_ts);")
        exec_sql(con, f"create index if not exists idx_std_dist_sale on {qident(args.std_schema)}.{qident('sales_distributor_extract')} (sale_date, store_id);")
        exec_sql(con, f"create index if not exists idx_std_inv_snap on {qident(args.std_schema)}.{qident('inventory_erp_snapshot')} (snapshot_date, store_id);")

        print("✅ Standardization complete (standardized.* rebuilt).")
    finally:
        con.close()


if __name__ == "__main__":
    main()