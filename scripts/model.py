#!/usr/bin/env python3
# scripts/model.py
"""
Build modeled.* tables integrating Sales, Ops, People.

Creates:
- modeled.dim_store
- modeled.dim_product
- modeled.fact_sales_distributor_daily
- modeled.fact_pos_daily
- modeled.fact_inventory_daily
- modeled.fact_labor_weekly

Usage:
  export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_analytics"
  python3 scripts/model.py
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


def exec_sql(con, sql: str) -> None:
    with con.cursor() as cur:
        cur.execute(sql)
    con.commit()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=os.getenv("PROJECT1_PG_DSN", ""))
    ap.add_argument("--std-schema", default="standardized")
    ap.add_argument("--model-schema", default="modeled")
    args = ap.parse_args()
    if not args.dsn.strip():
        raise SystemExit("Missing DSN. Set PROJECT1_PG_DSN or pass --dsn.")

    con = pg_connect(args.dsn)
    try:
        exec_sql(con, f"create schema if not exists {qident(args.model_schema)};")

        # dim_store from all standardized store_id occurrences
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.model_schema)}.{qident("dim_store")} cascade;
            create table {qident(args.model_schema)}.{qident("dim_store")} as
            with stores as (
              select store_id from {qident(args.std_schema)}.{qident("sales_distributor_extract")} where store_id is not null and store_id <> ''
              union
              select store_id from {qident(args.std_schema)}.{qident("pos_transactions")} where store_id is not null and store_id <> ''
              union
              select store_id from {qident(args.std_schema)}.{qident("inventory_erp_snapshot")} where store_id is not null and store_id <> ''
              union
              select store_id from {qident(args.std_schema)}.{qident("wms_shipments")} where store_id is not null and store_id <> ''
              union
              select store_id from {qident(args.std_schema)}.{qident("labor_hours_payroll")} where store_id is not null and store_id <> ''
            )
            select
              store_id,
              left(store_id,2) as state_code,
              'Account ' || store_id as store_name
            from stores;

            create unique index if not exists pk_dim_store on {qident(args.model_schema)}.{qident("dim_store")} (store_id);
            """,
        )

        # dim_product from sku + product_name sources
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.model_schema)}.{qident("dim_product")} cascade;
            create table {qident(args.model_schema)}.{qident("dim_product")} as
            with p as (
              select sku, max(product_name) as product_name
              from {qident(args.std_schema)}.{qident("sales_distributor_extract")}
              where sku is not null and sku <> ''
              group by sku
              union
              select sku, null::text as product_name
              from {qident(args.std_schema)}.{qident("pos_transactions")}
              where sku is not null and sku <> ''
            )
            select
              sku,
              coalesce(max(product_name), 'Unknown ' || sku) as product_name
            from p
            group by sku;

            create unique index if not exists pk_dim_product on {qident(args.model_schema)}.{qident("dim_product")} (sku);
            """,
        )

        # facts: distributor daily (already daily-ish, but we standardize it as daily grain)
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.model_schema)}.{qident("fact_sales_distributor_daily")} cascade;
            create table {qident(args.model_schema)}.{qident("fact_sales_distributor_daily")} as
            select
              sale_date as date,
              store_id,
              sku,
              channel,
              sum(qty) as qty,
              sum(gross_sales) as gross_sales,
              sum(discount_amount) as discount_amount,
              sum(net_sales) as net_sales,
              sum(cogs) as cogs,
              sum(orders) as orders,
              sum(customers) as customers
            from {qident(args.std_schema)}.{qident("sales_distributor_extract")}
            where sale_date is not null and store_id is not null and store_id <> '' and sku is not null and sku <> ''
            group by 1,2,3,4;

            create index if not exists idx_fact_dist_date_store on {qident(args.model_schema)}.{qident("fact_sales_distributor_daily")} (date, store_id);
            """,
        )

        # facts: POS daily aggregation
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.model_schema)}.{qident("fact_pos_daily")} cascade;
            create table {qident(args.model_schema)}.{qident("fact_pos_daily")} as
            select
              (txn_ts::date) as date,
              store_id,
              sku,
              sum(qty) as qty,
              sum(gross_amount) as gross_amount,
              sum(net_amount) as net_amount,
              avg(discount_pct) as avg_discount_pct,
              count(distinct txn_id) as txn_count
            from {qident(args.std_schema)}.{qident("pos_transactions")}
            where txn_ts is not null and store_id is not null and store_id <> '' and sku is not null and sku <> ''
            group by 1,2,3;

            create index if not exists idx_fact_pos_date_store on {qident(args.model_schema)}.{qident("fact_pos_daily")} (date, store_id);
            """,
        )

        # facts: inventory daily snapshot
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.model_schema)}.{qident("fact_inventory_daily")} cascade;
            create table {qident(args.model_schema)}.{qident("fact_inventory_daily")} as
            select
              snapshot_date as date,
              store_id,
              sku,
              avg(on_hand)::bigint as on_hand_avg,
              max(on_hand)::bigint as on_hand_max,
              sum(receipts) as receipts,
              sum(shipments) as shipments,
              sum(requested_units) as requested_units,
              sum(backordered_units) as backordered_units
            from {qident(args.std_schema)}.{qident("inventory_erp_snapshot")}
            where snapshot_date is not null and store_id is not null and store_id <> '' and sku is not null and sku <> ''
            group by 1,2,3;

            create index if not exists idx_fact_inv_date_store on {qident(args.model_schema)}.{qident("fact_inventory_daily")} (date, store_id);
            """,
        )

        # facts: labor weekly
        exec_sql(
            con,
            f"""
            drop table if exists {qident(args.model_schema)}.{qident("fact_labor_weekly")} cascade;
            create table {qident(args.model_schema)}.{qident("fact_labor_weekly")} as
            select
              week_ending as week_ending,
              store_id,
              department,
              sum(hours_worked) as hours_worked,
              sum(ot_hours) as ot_hours,
              sum(employee_count) as employee_count,
              sum(labor_cost) as labor_cost
            from {qident(args.std_schema)}.{qident("labor_hours_payroll")}
            where week_ending is not null and store_id is not null and store_id <> ''
            group by 1,2,3;

            create index if not exists idx_fact_labor_week_store on {qident(args.model_schema)}.{qident("fact_labor_weekly")} (week_ending, store_id);
            """,
        )

        print("✅ Modeling complete (modeled.* rebuilt).")
    finally:
        con.close()


if __name__ == "__main__":
    main()