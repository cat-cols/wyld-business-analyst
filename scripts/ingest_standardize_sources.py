#!/usr/bin/env python3
"""Ingest + standardize multi-source drops into staging.

Reads the manifest created by `scripts/simulate_source_drops.py`:
  docs/source_drop_manifest.csv

Standardizes messy inputs into canonical staging tables:
  data/processed/staging/

Writes exceptions (bad rows / missing critical keys) to:
  data/exceptions/<domain>/<run_ts>/*.csv

No hardcoded paths: repo root is derived from this file location.
"""

from __future__ import annotations

import argparse
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pandas as pd


@dataclass
class Config:
    strict: bool = False


def get_repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def snake(s: str) -> str:
    s = str(s).strip()
    s = re.sub(r"[\s\-\/]+", "_", s)
    s = re.sub(r"[^0-9a-zA-Z_]+", "", s)
    s = re.sub(r"_+", "_", s)
    return s.lower().strip("_")


def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [snake(c) for c in df.columns]
    return df


def to_number(series: pd.Series) -> pd.Series:
    s = series.astype(str).str.replace(r"[\$,]", "", regex=True)
    s = s.replace({"nan": None, "None": None, "": None})
    return pd.to_numeric(s, errors="coerce")


def to_date(series: pd.Series) -> pd.Series:
    return pd.to_datetime(series, errors="coerce", infer_datetime_format=True).dt.date


def ensure_dirs(root: Path, run_ts: str) -> dict[str, Path]:
    staging = root / "data" / "processed" / "staging"
    exceptions = root / "data" / "exceptions"
    reports = root / "docs" / "ingestion" / run_ts

    staging.mkdir(parents=True, exist_ok=True)
    exceptions.mkdir(parents=True, exist_ok=True)
    reports.mkdir(parents=True, exist_ok=True)

    return {"staging": staging, "exceptions": exceptions, "reports": reports}


def read_any(path: Path) -> pd.DataFrame:
    suf = path.suffix.lower()
    if suf == ".csv":
        return pd.read_csv(path)
    if suf in (".xlsx", ".xls"):
        return pd.read_excel(path, sheet_name=0, engine="openpyxl")
    if suf in (".sqlite", ".db"):
        with sqlite3.connect(path) as con:
            tbls = pd.read_sql_query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name", con)["name"].tolist()
            if not tbls:
                return pd.DataFrame()
            return pd.read_sql_query(f"SELECT * FROM {tbls[0]}", con)
    raise ValueError(f"Unsupported file type: {path}")


def write_csv(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)


def dump_exceptions(df: pd.DataFrame, base: Path, domain: str, run_ts: str, name: str, reason: str) -> None:
    if len(df) == 0:
        return
    out_dir = base / domain / run_ts
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{name}__exceptions.csv"
    df2 = df.copy()
    df2.insert(0, "exception_reason", reason)
    df2.to_csv(out, index=False)


# -------------------------
# Standardizers
# -------------------------


def standardize_sales(df: pd.DataFrame, system: str) -> pd.DataFrame:
    df = normalize_columns(df)

    df = df.rename(
        columns={
            # keys
            "store_id": "store_id",
            "store_code": "store_id",
            "site_code": "store_id",
            "sku": "sku",
            "product_sku": "sku",
            # dates
            "sale_date": "sale_date",
            "transaction_date": "sale_date",
            "txn_date": "sale_date",
            "txn_ts": "transaction_ts",
            # qty
            "qty": "qty",
            "units_sold": "qty",
            # prices
            "unit_list_price": "unit_list_price",
            "unit_price": "unit_list_price",
            "discount_rate": "discount_rate",
            "discount_pct": "discount_rate",
            "unit_net_price": "unit_net_price",
            # amounts
            "gross_sales": "gross_sales_amount",
            "gross_amount": "gross_sales_amount",
            "discount_amount": "discount_amount",
            "net_sales": "net_sales_amount",
            "net_amount": "net_sales_amount",
            "cogs": "cogs_amount",
            # descriptors
            "product_name": "product_name",
            "channel": "channel",
            # counts
            "orders": "order_count",
            "customers": "customer_count",
            # ids
            "txn_id": "transaction_id",
        }
    )

    # derive sale_date from transaction_ts if needed
    if "sale_date" not in df.columns and "transaction_ts" in df.columns:
        df["sale_date"] = df["transaction_ts"]

    # types
    if "sale_date" in df.columns:
        df["sale_date"] = to_date(df["sale_date"])
    for c in ["qty", "unit_list_price", "discount_rate", "unit_net_price", "gross_sales_amount", "discount_amount", "net_sales_amount", "cogs_amount"]:
        if c in df.columns:
            df[c] = to_number(df[c])

    # derived fields if missing
    if "unit_net_price" not in df.columns and {"unit_list_price", "discount_rate"}.issubset(df.columns):
        df["unit_net_price"] = df["unit_list_price"] * (1 - df["discount_rate"].fillna(0))
    if "net_sales_amount" not in df.columns and {"qty", "unit_net_price"}.issubset(df.columns):
        df["net_sales_amount"] = df["qty"] * df["unit_net_price"]
    if "gross_sales_amount" not in df.columns and {"qty", "unit_list_price"}.issubset(df.columns):
        df["gross_sales_amount"] = df["qty"] * df["unit_list_price"]
    if "discount_amount" not in df.columns and {"gross_sales_amount", "net_sales_amount"}.issubset(df.columns):
        df["discount_amount"] = df["gross_sales_amount"] - df["net_sales_amount"]

    out_cols = [
        "sale_date",
        "store_id",
        "sku",
        "product_name",
        "channel",
        "qty",
        "unit_list_price",
        "discount_rate",
        "unit_net_price",
        "gross_sales_amount",
        "discount_amount",
        "net_sales_amount",
        "cogs_amount",
        "order_count",
        "customer_count",
        "transaction_id",
        "transaction_ts",
    ]
    for c in out_cols:
        if c not in df.columns:
            df[c] = pd.NA

    out = df[out_cols].copy()
    out["source_system"] = system
    return out


def standardize_inventory(df: pd.DataFrame, system: str) -> pd.DataFrame:
    df = normalize_columns(df)
    df = df.rename(
        columns={
            "snapshot_date": "snapshot_date",
            "site_code": "site_code",
            "sku": "sku",
            "on_hand": "on_hand_units",
            "receipts": "received_units",
            "shipments": "shipped_units",
            "requested_units": "requested_units",
            "backordered_units": "backordered_units",
        }
    )
    if "snapshot_date" in df.columns:
        df["snapshot_date"] = to_date(df["snapshot_date"])
    for c in ["on_hand_units", "received_units", "shipped_units", "requested_units", "backordered_units"]:
        if c in df.columns:
            df[c] = to_number(df[c])
        else:
            df[c] = pd.NA
    for c in ["snapshot_date", "site_code", "sku"]:
        if c not in df.columns:
            df[c] = pd.NA

    out = df[["snapshot_date", "site_code", "sku", "on_hand_units", "received_units", "shipped_units", "requested_units", "backordered_units"]].copy()
    out["source_system"] = system
    return out


def standardize_shipments(df: pd.DataFrame, system: str) -> pd.DataFrame:
    df = normalize_columns(df)
    df = df.rename(
        columns={
            "ship_date": "ship_date",
            "shipment_id": "shipment_id",
            "site_code": "site_code",
            "sku": "sku",
            "units_shipped": "units_shipped",
            "carrier": "carrier",
        }
    )
    if "ship_date" in df.columns:
        df["ship_date"] = to_date(df["ship_date"])
    if "units_shipped" in df.columns:
        df["units_shipped"] = to_number(df["units_shipped"])
    for c in ["ship_date", "shipment_id", "site_code", "sku", "units_shipped", "carrier"]:
        if c not in df.columns:
            df[c] = pd.NA
    out = df[["ship_date", "shipment_id", "site_code", "sku", "units_shipped", "carrier"]].copy()
    out["source_system"] = system
    return out


def standardize_payroll(df: pd.DataFrame, system: str) -> pd.DataFrame:
    df = normalize_columns(df)
    df = df.rename(
        columns={
            "week_ending": "work_date",
            "work_date": "work_date",
            "site_code": "site_code",
            "department": "department",
            "team": "team",
            "hours_worked": "hours_worked",
            "ot_hours": "overtime_hours",
            "employee_count": "employee_count",
            "labor_cost": "labor_cost_amount",
        }
    )
    if "work_date" in df.columns:
        df["work_date"] = to_date(df["work_date"])
    for c in ["hours_worked", "overtime_hours", "employee_count", "labor_cost_amount"]:
        if c in df.columns:
            df[c] = to_number(df[c])
        else:
            df[c] = pd.NA
    for c in ["work_date", "site_code", "department", "team"]:
        if c not in df.columns:
            df[c] = pd.NA
    out = df[["work_date", "site_code", "department", "team", "hours_worked", "overtime_hours", "employee_count", "labor_cost_amount"]].copy()
    out["source_system"] = system
    return out


def standardize_timeclock(df: pd.DataFrame, system: str) -> pd.DataFrame:
    df = normalize_columns(df)
    df = df.rename(columns={"punch_ts": "punch_ts", "employee_id": "employee_id", "site_code": "site_code", "action": "action"})
    if "punch_ts" in df.columns:
        df["punch_ts"] = pd.to_datetime(df["punch_ts"], errors="coerce")
        df["punch_date"] = df["punch_ts"].dt.date
    for c in ["punch_ts", "punch_date", "employee_id", "site_code", "action"]:
        if c not in df.columns:
            df[c] = pd.NA
    out = df[["punch_ts", "punch_date", "employee_id", "site_code", "action"]].copy()
    out["source_system"] = system
    return out


def standardize_finance_actuals(df: pd.DataFrame, system: str) -> pd.DataFrame:
    df = normalize_columns(df)
    df = df.rename(columns={"month_start": "month_start", "metric_name": "metric_name", "actual_amount": "actual_amount", "currency": "currency_code", "currency_code": "currency_code"})
    if "month_start" in df.columns:
        df["month_start"] = to_date(df["month_start"])
    if "actual_amount" in df.columns:
        df["actual_amount"] = to_number(df["actual_amount"])
    for c in ["month_start", "metric_name", "actual_amount", "currency_code"]:
        if c not in df.columns:
            df[c] = pd.NA
    out = df[["month_start", "metric_name", "actual_amount", "currency_code"]].copy()
    out["source_system"] = system
    return out


def standardize_gl(df: pd.DataFrame, system: str) -> pd.DataFrame:
    df = normalize_columns(df)
    df = df.rename(columns={"period": "period", "posting_date": "posting_date", "location_code": "location_code", "account_code": "account_code", "account_name": "account_name", "debit_amount": "debit_amount", "credit_amount": "credit_amount"})
    if "posting_date" in df.columns:
        df["posting_date"] = to_date(df["posting_date"])
    for c in ["debit_amount", "credit_amount"]:
        if c in df.columns:
            df[c] = to_number(df[c])
        else:
            df[c] = pd.NA
    for c in ["period", "posting_date", "location_code", "account_code", "account_name", "debit_amount", "credit_amount"]:
        if c not in df.columns:
            df[c] = pd.NA
    out = df[["period", "posting_date", "location_code", "account_code", "account_name", "debit_amount", "credit_amount"]].copy()
    out["net_amount"] = out["debit_amount"].fillna(0) - out["credit_amount"].fillna(0)
    out["source_system"] = system
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default=None, help="Path to docs/source_drop_manifest.csv (optional)")
    ap.add_argument("--strict", action="store_true", help="Fail on ingestion errors")
    ap.add_argument("--base", default="01_ops_command_center", help="Read/write under this subfolder (use . for repo root)")
    args = ap.parse_args()

    cfg = Config(strict=bool(args.strict))
    repo = get_repo_root()
    root = repo if args.base in (".", "", None) else (repo / args.base)
    run_ts = pd.Timestamp.now().strftime("%Y%m%d_%H%M%S")
    out = ensure_dirs(root, run_ts)

    manifest_path = Path(args.manifest) if args.manifest else (root / "docs" / "source_drop_manifest.csv")
    if not manifest_path.exists():
        raise FileNotFoundError(f"Manifest not found: {manifest_path}. Run scripts/simulate_source_drops.py first.")

    manifest = pd.read_csv(manifest_path)

    # collect
    sales_frames: list[pd.DataFrame] = []
    inv_frames: list[pd.DataFrame] = []
    ship_frames: list[pd.DataFrame] = []
    payroll_frames: list[pd.DataFrame] = []
    timeclock_frames: list[pd.DataFrame] = []
    fin_frames: list[pd.DataFrame] = []
    gl_frames: list[pd.DataFrame] = []

    report_rows: list[dict[str, Any]] = []

    for r in manifest.itertuples(index=False):
        domain = str(getattr(r, "domain"))
        system = str(getattr(r, "system"))
        rel = str(getattr(r, "relative_path"))
        fp = root / rel
        if not fp.exists():
            report_rows.append({"domain": domain, "system": system, "file": rel, "status": "missing", "rows": 0})
            continue

        try:
            raw = read_any(fp)
            n = int(len(raw))

            if domain == "sales":
                std = standardize_sales(raw, system)
                std["source_file"] = fp.name
                sales_frames.append(std)

            elif domain == "ops" and system == "erp":
                std = standardize_inventory(raw, system)
                std["source_file"] = fp.name
                inv_frames.append(std)

            elif domain == "ops" and system == "wms":
                std = standardize_shipments(raw, system)
                std["source_file"] = fp.name
                ship_frames.append(std)

            elif domain == "people" and system == "payroll":
                std = standardize_payroll(raw, system)
                std["source_file"] = fp.name
                payroll_frames.append(std)

            elif domain == "people" and system == "timeclock":
                std = standardize_timeclock(raw, system)
                std["source_file"] = fp.name
                timeclock_frames.append(std)

            elif domain == "finance" and system == "erp_finance":
                std = standardize_finance_actuals(raw, system)
                std["source_file"] = fp.name
                fin_frames.append(std)

            elif domain == "finance" and system == "gl":
                std = standardize_gl(raw, system)
                std["source_file"] = fp.name
                gl_frames.append(std)

            else:
                report_rows.append({"domain": domain, "system": system, "file": rel, "status": "skipped", "rows": n})
                continue

            report_rows.append({"domain": domain, "system": system, "file": rel, "status": "ingested", "rows": n})

        except Exception as e:
            report_rows.append({"domain": domain, "system": system, "file": rel, "status": f"error:{type(e).__name__}", "rows": 0})
            if cfg.strict:
                raise

    def concat(frames: list[pd.DataFrame]) -> pd.DataFrame:
        return pd.concat(frames, ignore_index=True, sort=False) if frames else pd.DataFrame()

    sales = concat(sales_frames)
    inv = concat(inv_frames)
    ship = concat(ship_frames)
    payroll = concat(payroll_frames)
    timeclock = concat(timeclock_frames)
    fin = concat(fin_frames)
    gl = concat(gl_frames)

    # exceptions
    if len(sales):
        bad = sales[sales["sale_date"].isna() | sales["sku"].isna()]
        dump_exceptions(bad, out["exceptions"], "sales", run_ts, "stg_sales_all", "missing sale_date or sku")

    if len(inv):
        bad = inv[inv["snapshot_date"].isna() | inv["sku"].isna()]
        dump_exceptions(bad, out["exceptions"], "ops", run_ts, "stg_inventory_snapshot", "missing snapshot_date or sku")

    if len(payroll):
        bad = payroll[payroll["work_date"].isna() | payroll["site_code"].isna()]
        dump_exceptions(bad, out["exceptions"], "people", run_ts, "stg_labor_payroll", "missing work_date or site_code")

    if len(fin):
        bad = fin[fin["month_start"].isna() | fin["metric_name"].isna()]
        dump_exceptions(bad, out["exceptions"], "finance", run_ts, "stg_finance_actuals", "missing month_start or metric_name")

    # write staging
    write_csv(sales, out["staging"] / "stg_sales_all.csv")
    write_csv(inv, out["staging"] / "stg_inventory_snapshot.csv")
    write_csv(ship, out["staging"] / "stg_wms_shipments.csv")
    write_csv(payroll, out["staging"] / "stg_labor_payroll.csv")
    write_csv(timeclock, out["staging"] / "stg_timeclock_punches.csv")
    write_csv(fin, out["staging"] / "stg_finance_actuals.csv")
    write_csv(gl, out["staging"] / "stg_gl_detail.csv")

    report = pd.DataFrame(report_rows)
    report_path = out["reports"] / "ingestion_report.csv"
    report.to_csv(report_path, index=False)

    print("\n✅ Ingestion complete")
    print(f"Staging: {out['staging']}")
    print(f"Report:  {report_path}")


if __name__ == "__main__":
    main()
