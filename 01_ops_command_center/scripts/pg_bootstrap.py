#!/usr/bin/env python3
# scripts/pg_bootstrap.py
"""
Bootstrap Postgres workspace for Project 1.

Creates schemas:
  raw, standardized, modeled, audit

Also creates a small "audit.run_log" table for pipeline runs.

Usage (recommended):
  export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_chyld"
  python3 scripts/pg_bootstrap.py

Optional: create database (requires an admin DSN to the server, usually to the "postgres" db):
  python3 scripts/pg_bootstrap.py --create-db wyld_chyld --admin-dsn "postgresql://b@localhost:5432/postgres"
"""

from __future__ import annotations

import argparse
import os
from typing import Tuple


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


def create_db_if_missing(admin_dsn: str, dbname: str) -> None:
    con = pg_connect(admin_dsn)
    con.autocommit = True  # create database cannot run inside a transaction in many setups
    try:
        with con.cursor() as cur:
            cur.execute("select 1 from pg_database where datname = %s;", (dbname,))
            exists = cur.fetchone() is not None
            if not exists:
                cur.execute(f"create database {qident(dbname)};")
                print(f"✅ Created database: {dbname}")
            else:
                print(f"ℹ️ Database already exists: {dbname}")
    finally:
        con.close()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=os.getenv("PROJECT1_PG_DSN", ""), help="Target DSN (or set PROJECT1_PG_DSN)")
    ap.add_argument("--create-db", default="", help="If set, create this database name first (requires --admin-dsn)")
    ap.add_argument("--admin-dsn", default=os.getenv("PROJECT1_PG_ADMIN_DSN", ""), help="Admin DSN (or PROJECT1_PG_ADMIN_DSN)")
    args = ap.parse_args()

    if args.create_db:
        if not args.admin_dsn.strip():
            raise SystemExit("Missing --admin-dsn (or PROJECT1_PG_ADMIN_DSN) required for --create-db.")
        create_db_if_missing(args.admin_dsn, args.create_db)

    if not args.dsn.strip():
        raise SystemExit("Missing DSN. Provide --dsn or set env PROJECT1_PG_DSN.")

    con = pg_connect(args.dsn)
    try:
        for schema in ["raw", "standardized", "modeled", "audit"]:
            exec_sql(con, f"create schema if not exists {qident(schema)};")

        exec_sql(
            con,
            f"""
            create table if not exists {qident("audit")}.{qident("run_log")} (
              run_id text primary key,
              started_at timestamptz not null default now(),
              finished_at timestamptz,
              status text,
              notes text
            );
            """,
        )

        exec_sql(
            con,
            f"""
            create table if not exists {qident("audit")}.{qident("dq_exceptions")} (
              exception_id bigserial primary key,
              detected_at timestamptz not null default now(),
              run_id text,
              rule_name text not null,
              table_name text not null,
              record_key text,
              severity text default 'warn',
              details text
            );
            """,
        )

        exec_sql(
            con,
            f"""
            create table if not exists {qident("audit")}.{qident("dq_run_summary")} (
              summary_id bigserial primary key,
              created_at timestamptz not null default now(),
              run_id text,
              table_name text,
              rule_name text,
              exception_count bigint
            );
            """,
        )

        print("✅ Postgres bootstrap complete (schemas + audit tables).")
    finally:
        con.close()


if __name__ == "__main__":
    main()