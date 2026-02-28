#!/usr/bin/env python3
# scripts/ingest_raw.py
"""
Ingest latest source drops from data/source_extracts/**/current into Postgres raw.* tables.

Loads:
- sales.distributor current CSV -> raw.sales_distributor_extract
- sales.pos current CSV         -> raw.pos_transactions_csv
- ops.erp current CSV           -> raw.inventory_erp_snapshot
- ops.wms current CSV           -> raw.wms_shipments
- people.timeclock current CSV  -> raw.timeclock_punches
- people.payroll current XLSX   -> raw.labor_hours_payroll_export
- finance.erp_finance XLSX      -> raw.finance_actuals_summary
- finance.gl current CSV        -> raw.gl_detail_csv

Also: does NOT replace the simulator’s DB-load tables (raw.project1_pos_transactions/raw.project1_gl_detail),
but you’ll now have “file ingests” in raw too, which is realistic.

Metadata columns added to every raw table:
- run_id, ingested_at, source_file, source_system, domain, drop_date

Usage:
  export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_analytics"
  python3 scripts/ingest_raw.py --run-id <optional>
"""

from __future__ import annotations

import argparse
import os
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional, Tuple

import pandas as pd


def get_repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


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


def infer_pg_type(series: pd.Series) -> str:
    if pd.api.types.is_bool_dtype(series):
        return "boolean"
    if pd.api.types.is_integer_dtype(series):
        return "bigint"
    if pd.api.types.is_float_dtype(series):
        return "double precision"
    if pd.api.types.is_datetime64_any_dtype(series):
        return "timestamp"
    return "text"


def ensure_table_for_df(con, schema: str, table: str, df: pd.DataFrame) -> None:
    cols = [f"{qident(c)} {infer_pg_type(df[c])}" for c in df.columns]
    ddl = ", ".join(cols)
    exec_sql(con, f"create table if not exists {qident(schema)}.{qident(table)} ({ddl});")


def ensure_columns(con, schema: str, table: str, col_types: Dict[str, str]) -> None:
    for c, t in col_types.items():
        try:
            exec_sql(con, f"alter table {qident(schema)}.{qident(table)} add column {qident(c)} {t};")
        except Exception:
            con.rollback()


def copy_append(con, schema: str, table: str, df: pd.DataFrame) -> None:
    if len(df) == 0:
        return

    # Psycopg COPY support differs; use COPY ... FROM STDIN with CSV text.
    from io import StringIO

    buf = StringIO()
    df.to_csv(buf, index=False, header=False)
    buf.seek(0)

    cols = ", ".join(qident(c) for c in df.columns)
    sql = f"copy {qident(schema)}.{qident(table)} ({cols}) from stdin with (format csv)"

    with con.cursor() as cur:
        if hasattr(cur, "copy"):  # psycopg v3
            with cur.copy(sql) as cp:
                cp.write(buf.getvalue())
        else:  # psycopg2
            cur.copy_expert(sql, buf)
    con.commit()


def read_csv(path: Path) -> pd.DataFrame:
    return pd.read_csv(path, dtype=str, keep_default_na=True, na_values=["", "NULL", "null"])


def read_xlsx(path: Path, sheet: Optional[str] = None) -> pd.DataFrame:
    return pd.read_excel(path, sheet_name=sheet or 0, dtype=str)


@dataclass
class SourceSpec:
    domain: str
    system: str
    filename: str
    kind: str  # csv|xlsx
    raw_table: str
    sheet: Optional[str] = None


SOURCES = [
    SourceSpec("sales", "distributor", "sales_distributor_extract.csv", "csv", "sales_distributor_extract"),
    SourceSpec("sales", "pos", "pos_transactions.csv", "csv", "pos_transactions_csv"),
    SourceSpec("ops", "erp", "inventory_erp_snapshot.csv", "csv", "inventory_erp_snapshot"),
    SourceSpec("ops", "wms", "wms_shipments.csv", "csv", "wms_shipments"),
    SourceSpec("people", "timeclock", "timeclock_punches.csv", "csv", "timeclock_punches"),
    SourceSpec("people", "payroll", "labor_hours_payroll_export.xlsx", "xlsx", "labor_hours_payroll_export", sheet="payroll"),
    SourceSpec("finance", "erp_finance", "finance_actuals_summary.xlsx", "xlsx", "finance_actuals_summary", sheet="actuals"),
    SourceSpec("finance", "gl", "gl_detail.csv", "csv", "gl_detail_csv"),
]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=os.getenv("PROJECT1_PG_DSN", ""), help="Postgres DSN (or PROJECT1_PG_DSN)")
    ap.add_argument("--schema", default=os.getenv("PROJECT1_RAW_SCHEMA", "raw"))
    ap.add_argument("--base", default=".", help="Repo root override")
    ap.add_argument("--run-id", default="", help="Optional; otherwise auto-generated")
    args = ap.parse_args()

    if not args.dsn.strip():
        raise SystemExit("Missing DSN. Provide --dsn or set env PROJECT1_PG_DSN.")

    run_id = args.run_id.strip() or uuid.uuid4().hex[:12]
    repo = get_repo_root()
    root = repo if args.base in (".", "", None) else (repo / args.base)

    con = pg_connect(args.dsn)
    try:
        exec_sql(con, f"create schema if not exists {qident(args.schema)};")

        total_loaded = 0
        for spec in SOURCES:
            cur_dir = root / "data" / "source_extracts" / spec.domain / spec.system / "current"
            fpath = cur_dir / spec.filename
            if not fpath.exists():
                print(f"⚠️ Missing source (skipping): {fpath}")
                continue

            if spec.kind == "csv":
                df = read_csv(fpath)
            else:
                df = read_xlsx(fpath, sheet=spec.sheet)

            # Add metadata (all text-ish for simplicity)
            df["run_id"] = run_id
            df["ingested_at"] = pd.Timestamp.utcnow().isoformat()
            df["source_file"] = str(fpath)
            df["source_system"] = spec.system
            df["domain"] = spec.domain
            # Use the folder date if present (incoming has it; current does not). Keep simple: store today's date.
            df["drop_date"] = pd.Timestamp.utcnow().date().isoformat()

            ensure_table_for_df(con, args.schema, spec.raw_table, df)
            ensure_columns(
                con,
                args.schema,
                spec.raw_table,
                {
                    "run_id": "text",
                    "ingested_at": "text",
                    "source_file": "text",
                    "source_system": "text",
                    "domain": "text",
                    "drop_date": "text",
                },
            )
            copy_append(con, args.schema, spec.raw_table, df)
            total_loaded += len(df)
            print(f"✅ Loaded {len(df):,} rows -> {args.schema}.{spec.raw_table}  ({spec.domain}/{spec.system})")

        print(f"\n✅ Raw ingest complete. run_id={run_id} rows_loaded={total_loaded:,}\n")
    finally:
        con.close()


if __name__ == "__main__":
    main()