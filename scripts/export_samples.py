#!/usr/bin/env python3
# scripts/export_samples.py
"""
Export small CSV samples from modeled.* tables for Power BI / sharing.

Outputs under:
  data/sample/exports/

Usage:
  export PROJECT1_PG_DSN="postgresql://b@localhost:5432/wyld_analytics"
  python3 scripts/export_samples.py --days 90
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path

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


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=os.getenv("PROJECT1_PG_DSN", ""))
    ap.add_argument("--model-schema", default="modeled")
    ap.add_argument("--days", type=int, default=90)
    ap.add_argument("--base", default=".")
    args = ap.parse_args()
    if not args.dsn.strip():
        raise SystemExit("Missing DSN. Set PROJECT1_PG_DSN or pass --dsn.")

    repo = get_repo_root()
    root = repo if args.base in (".", "", None) else (repo / args.base)
    out_dir = root / "data" / "sample" / "exports"
    out_dir.mkdir(parents=True, exist_ok=True)

    con = pg_connect(args.dsn)
    try:
        tables = [
            "dim_store",
            "dim_product",
            "fact_sales_distributor_daily",
            "fact_pos_daily",
            "fact_inventory_daily",
            "fact_labor_weekly",
        ]

        for t in tables:
            if t.startswith("fact_"):
                # date filter for facts (best-effort)
                if t == "fact_labor_weekly":
                    sql = f"""
                    select * from {args.model_schema}.{t}
                    where week_ending >= (current_date - interval '{args.days} days')::date
                    order by week_ending desc
                    """
                else:
                    sql = f"""
                    select * from {args.model_schema}.{t}
                    where date >= (current_date - interval '{args.days} days')::date
                    order by date desc
                    """
            else:
                sql = f"select * from {args.model_schema}.{t}"

            df = pd.read_sql(sql, con)
            out_path = out_dir / f"{t}.csv"
            df.to_csv(out_path, index=False)
            print(f"✅ Exported {len(df):,} rows -> {out_path}")

        print("\n✅ Sample exports complete.")
    finally:
        con.close()


if __name__ == "__main__":
    main()