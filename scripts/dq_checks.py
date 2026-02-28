#!/usr/bin/env python3
# scripts/dq_checks.py
"""
Run DQ checks on standardized.* and write exceptions to audit.dq_exceptions + summary to audit.dq_run_summary.

This is meant to be readable, not “perfect.” The point is:
- show repeatable rules
- show exception capture
- show run summary

Usage:
  export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_analytics"
  python3 scripts/dq_checks.py --run-id <optional>
"""

from __future__ import annotations

import argparse
import os
import uuid


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
    ap.add_argument("--std-schema", default="standardized")
    ap.add_argument("--audit-schema", default="audit")
    ap.add_argument("--run-id", default="", help="Label this dq run (defaults to new id)")
    args = ap.parse_args()
    if not args.dsn.strip():
        raise SystemExit("Missing DSN. Set PROJECT1_PG_DSN or pass --dsn.")

    run_id = args.run_id.strip() or uuid.uuid4().hex[:12]

    con = pg_connect(args.dsn)
    try:
        exec_sql(con, f"create schema if not exists {qident(args.audit_schema)};")

        # Start run log row (if exists)
        try:
            exec_sql(
                con,
                f"""
                insert into {qident(args.audit_schema)}.{qident("run_log")} (run_id, status, notes)
                values (%(run_id)s, 'running', 'dq_checks')
                on conflict (run_id) do nothing;
                """,
                {"run_id": run_id},
            )
        except Exception:
            con.rollback()

        # Clear prior summary for this run_id (safe)
        exec_sql(
            con,
            f"delete from {qident(args.audit_schema)}.{qident('dq_run_summary')} where run_id = %(run_id)s;",
            {"run_id": run_id},
        )

        # Helper: insert exceptions from a SELECT that returns (rule_name, table_name, record_key, severity, details)
        def insert_exceptions(select_sql: str) -> None:
            exec_sql(
                con,
                f"""
                insert into {qident(args.audit_schema)}.{qident("dq_exceptions")}
                  (run_id, rule_name, table_name, record_key, severity, details)
                {select_sql};
                """,
                {"run_id": run_id},
            )

        # -------------------------
        # RULES
        # -------------------------

        # 1) Missing store_id in sales distributor
        insert_exceptions(
            f"""
            select
              'missing_store_id' as rule_name,
              '{args.std_schema}.sales_distributor_extract' as table_name,
              coalesce(sku,'?') || '|' || coalesce(sale_date::text,'?') as record_key,
              'error' as severity,
              'store_id is null/blank' as details
            from {qident(args.std_schema)}.{qident("sales_distributor_extract")}
            where coalesce(store_id,'') = '';
            """
        )

        # 2) Negative on_hand in inventory
        insert_exceptions(
            f"""
            select
              'negative_on_hand' as rule_name,
              '{args.std_schema}.inventory_erp_snapshot' as table_name,
              coalesce(store_id,'?') || '|' || coalesce(sku,'?') || '|' || coalesce(snapshot_date::text,'?') as record_key,
              'error' as severity,
              'on_hand < 0' as details
            from {qident(args.std_schema)}.{qident("inventory_erp_snapshot")}
            where on_hand is not null and on_hand < 0;
            """
        )

        # 3) POS duplicate txn_id
        insert_exceptions(
            f"""
            select
              'duplicate_txn_id' as rule_name,
              '{args.std_schema}.pos_transactions' as table_name,
              txn_id::text as record_key,
              'warn' as severity,
              'txn_id appears more than once' as details
            from {qident(args.std_schema)}.{qident("pos_transactions")}
            where txn_id is not null
            group by txn_id
            having count(*) > 1;
            """
        )

        # 4) Unparseable timestamps in timeclock
        insert_exceptions(
            f"""
            select
              'bad_punch_timestamp' as rule_name,
              '{args.std_schema}.timeclock_punches' as table_name,
              coalesce(employee_id::text,'?') || '|' || coalesce(store_id,'?') as record_key,
              'warn' as severity,
              'punch_ts is null after parsing' as details
            from {qident(args.std_schema)}.{qident("timeclock_punches")}
            where punch_ts is null;
            """
        )

        # 5) Missing sku in shipments
        insert_exceptions(
            f"""
            select
              'missing_sku' as rule_name,
              '{args.std_schema}.wms_shipments' as table_name,
              coalesce(shipment_id,'?') as record_key,
              'warn' as severity,
              'sku is null/blank' as details
            from {qident(args.std_schema)}.{qident("wms_shipments")}
            where coalesce(sku,'') = '';
            """
        )

        # -------------------------
        # SUMMARY
        # -------------------------
        exec_sql(
            con,
            f"""
            insert into {qident(args.audit_schema)}.{qident("dq_run_summary")}
              (run_id, table_name, rule_name, exception_count)
            select
              run_id,
              table_name,
              rule_name,
              count(*)::bigint as exception_count
            from {qident(args.audit_schema)}.{qident("dq_exceptions")}
            where run_id = %(run_id)s
            group by run_id, table_name, rule_name;
            """,
            {"run_id": run_id},
        )

        # Mark run done
        try:
            exec_sql(
                con,
                f"""
                update {qident(args.audit_schema)}.{qident("run_log")}
                set finished_at = now(), status = 'success'
                where run_id = %(run_id)s;
                """,
                {"run_id": run_id},
            )
        except Exception:
            con.rollback()

        print(f"✅ DQ checks complete. run_id={run_id}")
        print(f"See: {args.audit_schema}.dq_exceptions and {args.audit_schema}.dq_run_summary")
    finally:
        con.close()


if __name__ == "__main__":
    main()