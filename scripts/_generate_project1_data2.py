# scripts/source_drop_simulator.py
"""
Multi-source drop simulator (Project 1 realism layer) using PostgreSQL ONLY.

What it does
- Generates *messy* source drops that look like they came from multiple systems.
- Writes file drops under:
    data/source_extracts/<domain>/<system>/incoming/YYYY/MM/DD/<file>
  and refreshes:
    data/source_extracts/<domain>/<system>/current/<file>
- Also loads DB “extracts” into Postgres tables (raw schema by default).
- Writes a manifest to docs/source_drop_manifest.csv

Daily
- Sales / Distributor summary CSV
- Sales / POS transactions CSV
- Ops / ERP inventory snapshot CSV
- Ops / WMS shipments CSV
- People / Timeclock punches CSV

Weekly
- People / Payroll export XLSX

Monthly
- Finance / Actuals summary XLSX
- Finance / GL detail CSV + Postgres load

DB artifacts (Postgres loads)
- Sales / POS transactions DB export -> <schema>.<pos_table>
- Finance / GL detail DB export     -> <schema>.<gl_table>

Dependencies:
  pandas, numpy, openpyxl
  psycopg (preferred) OR psycopg2
"""

from __future__ import annotations

import argparse
import os
import uuid
from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from typing import Any, Optional

import numpy as np
import pandas as pd


# -----------------------------
# Config / Paths
# -----------------------------

@dataclass
class Config:
    start: str
    end: str
    seed: int = 42

    n_products: int = 15
    n_stores: int = 40

    # mess knobs
    pct_duplicate: float = 0.06
    pct_missing_store: float = 0.04
    pct_channel_mess: float = 0.10
    pct_trailing_space: float = 0.08
    pct_bad_date_format: float = 0.10
    pct_negative_inventory: float = 0.03


def get_repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def ensure_dirs(root: Path) -> None:
    (root / "docs").mkdir(parents=True, exist_ok=True)
    (root / "data" / "source_extracts").mkdir(parents=True, exist_ok=True)


def incoming_dir(root: Path, domain: str, system: str, drop_date: pd.Timestamp) -> Path:
    return (
        root
        / "data"
        / "source_extracts"
        / domain
        / system
        / "incoming"
        / f"{drop_date.year:04d}"
        / f"{drop_date.month:02d}"
        / f"{drop_date.day:02d}"
    )


def current_dir(root: Path, domain: str, system: str) -> Path:
    return root / "data" / "source_extracts" / domain / system / "current"


# -----------------------------
# Reference data
# -----------------------------

WYLD_PRODUCTS: list[dict[str, Any]] = [
    {"sku": "SKU0001", "product_name": "Wyld Blood Orange 1:1 THC:CBC Gummies", "base_price": 10.00, "cogs_ratio": 0.45},
    {"sku": "SKU0002", "product_name": "Wyld Boysenberry 1:1:1 THC:CBD:CBN Gummies", "base_price": 10.00, "cogs_ratio": 0.47},
    {"sku": "SKU0003", "product_name": "Wyld Elderberry 2:1 THC:CBN Gummies", "base_price": 10.50, "cogs_ratio": 0.46},
    {"sku": "SKU0004", "product_name": "Wyld Grapefruit 1:1:1 THC:CBG:CBC Gummies", "base_price": 10.50, "cogs_ratio": 0.48},
    {"sku": "SKU0005", "product_name": "Wyld Huckleberry THC Gummies", "base_price": 10.00, "cogs_ratio": 0.42},
    {"sku": "SKU0006", "product_name": "Wyld Kiwi 1:1 THC:THCv Gummies", "base_price": 10.50, "cogs_ratio": 0.49},
    {"sku": "SKU0007", "product_name": "Wyld Marionberry THC Gummies", "base_price": 10.00, "cogs_ratio": 0.42},
    {"sku": "SKU0008", "product_name": "Wyld Peach 2:1 CBD:THC Gummies", "base_price": 10.50, "cogs_ratio": 0.46},
    {"sku": "SKU0009", "product_name": "Wyld Pear 1:1 THC:CBG Gummies", "base_price": 10.50, "cogs_ratio": 0.47},
    {"sku": "SKU0010", "product_name": "Wyld Pomegranate 1:1 THC:CBD Gummies", "base_price": 10.50, "cogs_ratio": 0.46},
    {"sku": "SKU0011", "product_name": "Wyld Raspberry THC Gummies", "base_price": 10.50, "cogs_ratio": 0.42},
    {"sku": "SKU0012", "product_name": "Wyld Sour Apple THC Gummies", "base_price": 10.50, "cogs_ratio": 0.42},
    {"sku": "SKU0013", "product_name": "Wyld Sour Cherry THC Gummies", "base_price": 10.50, "cogs_ratio": 0.42},
    {"sku": "SKU0014", "product_name": "Wyld Sour Tangerine THC Gummies", "base_price": 10.50, "cogs_ratio": 0.43},
    {"sku": "SKU0015", "product_name": "Wyld Strawberry 20:1 CBD:THC Gummies", "base_price": 10.50, "cogs_ratio": 0.47},
]


def make_stores(n: int) -> pd.DataFrame:
    states = ["OR", "WA", "CA", "CO", "AZ", "NV", "IL", "MI"]
    rows = []
    for i in range(1, n + 1):
        st = states[(i - 1) % len(states)]
        rows.append({"store_id": f"{st}{i:03d}", "store_name": f"{st} Account {i:03d}", "state": st})
    return pd.DataFrame(rows)


def month_seasonality(month: int) -> float:
    return {1: 0.93, 2: 0.95, 3: 0.98, 4: 1.00, 5: 1.03, 6: 1.06, 7: 1.08, 8: 1.07, 9: 1.02, 10: 1.01, 11: 1.10, 12: 1.14}[month]


def weekday_factor(weekday: int, channel: str) -> float:
    if channel.lower() == "retail":
        return [0.95, 0.98, 1.00, 1.02, 1.08, 1.15, 1.12][weekday]
    if channel.lower() == "wholesale":
        return [1.10, 1.10, 1.08, 1.05, 0.95, 0.60, 0.45][weekday]
    return [0.98, 1.00, 1.02, 1.03, 1.05, 1.08, 1.07][weekday]


# -----------------------------
# Mess injectors
# -----------------------------

def maybe_duplicates(df: pd.DataFrame, rng: np.random.Generator, pct: float) -> pd.DataFrame:
    if len(df) == 0:
        return df
    n = int(round(len(df) * pct))
    n = max(5, n) if len(df) > 100 else min(3, len(df))
    if n <= 0:
        return df
    sample = df.sample(n=min(n, len(df)), random_state=int(rng.integers(1, 1_000_000)))
    return pd.concat([df, sample], ignore_index=True)


def maybe_missing(series: pd.Series, rng: np.random.Generator, pct: float) -> pd.Series:
    if len(series) == 0:
        return series
    n = int(round(len(series) * pct))
    if n <= 0:
        return series
    out = series.copy()
    idx = rng.choice(out.index.to_numpy(), size=min(n, len(out)), replace=False)
    out.loc[idx] = None
    return out


def maybe_channel_mess(series: pd.Series, rng: np.random.Generator, pct: float) -> pd.Series:
    if len(series) == 0:
        return series
    n = int(round(len(series) * pct))
    if n <= 0:
        return series
    out = series.copy()
    idx = rng.choice(out.index.to_numpy(), size=min(n, len(out)), replace=False)
    for i, ix in enumerate(idx):
        v = str(out.loc[ix])
        if i % 3 == 0:
            out.loc[ix] = v.upper()
        elif i % 3 == 1:
            out.loc[ix] = f" {v.lower()} "
        else:
            out.loc[ix] = v.title()
    return out


def maybe_trailing_spaces(series: pd.Series, rng: np.random.Generator, pct: float) -> pd.Series:
    if len(series) == 0:
        return series
    n = int(round(len(series) * pct))
    if n <= 0:
        return series
    out = series.copy()
    idx = rng.choice(out.index.to_numpy(), size=min(n, len(out)), replace=False)
    out.loc[idx] = out.loc[idx].astype(str) + "  "
    return out


def maybe_bad_date_format(series: pd.Series, rng: np.random.Generator, pct: float) -> pd.Series:
    if len(series) == 0:
        return series
    n = int(round(len(series) * pct))
    if n <= 0:
        return series
    out = series.copy()
    idx = rng.choice(out.index.to_numpy(), size=min(n, len(out)), replace=False)
    dt = pd.to_datetime(out.loc[idx], errors="coerce")
    out.loc[idx] = dt.dt.strftime("%m/%d/%Y").fillna(out.loc[idx])
    return out


# -----------------------------
# Generators (DataFrames)
# -----------------------------

def gen_sales_distributor_day(cfg: Config, rng: np.random.Generator, d: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    channels = ["Retail", "Wholesale", "Distributor"]
    rows: list[dict[str, Any]] = []
    season = month_seasonality(int(d.month))
    wd = int(d.weekday())

    for _, s in stores.iterrows():
        for prod in WYLD_PRODUCTS[: cfg.n_products]:
            for ch in channels:
                base = 2.0 * season * weekday_factor(wd, ch) * rng.uniform(0.7, 1.3)
                prob = float(np.clip(1 / (1 + np.exp(-(base - 1.2))), 0.10, 0.95))
                if rng.random() > prob:
                    continue
                units = max(1, int(rng.poisson(max(0.2, base * 3.2))))
                unit_list = float(prod["base_price"]) * float(rng.normal(1.0, 0.03))
                ch_factor = {"Retail": 1.0, "Wholesale": 0.88, "Distributor": 0.82}[ch]
                unit_list = max(0.01, unit_list * ch_factor)
                discount_rate = float(np.clip(rng.normal(0.08, 0.035), 0, 0.35))
                unit_net = unit_list * (1 - discount_rate)

                gross = units * unit_list
                net = units * unit_net
                cogs = net * float(np.clip(prod["cogs_ratio"] + rng.normal(0, 0.015), 0.25, 0.75))

                rows.append(
                    {
                        "sale_date": d.strftime("%Y-%m-%d"),
                        "store_id": s["store_id"],
                        "sku": prod["sku"],
                        "product_name": prod["product_name"],
                        "channel": ch,
                        "qty": int(units),
                        "unit_list_price": round(unit_list, 2),
                        "discount_rate": round(discount_rate, 4),
                        "unit_net_price": round(unit_net, 2),
                        "gross_sales": round(gross, 2),
                        "discount_amount": round(gross - net, 2),
                        "net_sales": round(net, 2),
                        "cogs": round(cogs, 2),
                        "orders": int(max(1, np.ceil(units / rng.integers(2, 6)))),
                        "customers": int(max(1, np.ceil(units / rng.integers(3, 7)))),
                    }
                )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    df = maybe_duplicates(df, rng, cfg.pct_duplicate)
    df["store_id"] = maybe_missing(df["store_id"], rng, cfg.pct_missing_store)
    df["channel"] = maybe_channel_mess(df["channel"], rng, cfg.pct_channel_mess)
    df["product_name"] = maybe_trailing_spaces(df["product_name"], rng, cfg.pct_trailing_space)
    df["sale_date"] = maybe_bad_date_format(df["sale_date"], rng, cfg.pct_bad_date_format)

    # header drift
    return df.rename(
        columns={
            "sale_date": "Sale Date",
            "store_id": "Store ID",
            "gross_sales": "Gross Sales",
            "net_sales": "Net Sales",
            "discount_amount": "Discount Amount",
            "unit_list_price": "Unit List Price",
            "unit_net_price": "Unit Net Price",
            "discount_rate": "Discount Rate",
        }
    )


def gen_pos_transactions_day(cfg: Config, rng: np.random.Generator, d: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    txn_base = int(d.strftime("%Y%m%d")) * 100000

    sample_stores = stores.sample(
        n=min(len(stores), max(5, cfg.n_stores // 2)),
        random_state=int(rng.integers(1, 1_000_000)),
    )

    for _, s in sample_stores.iterrows():
        n_txn = int(rng.integers(10, 60))
        for t in range(n_txn):
            prod = WYLD_PRODUCTS[int(rng.integers(0, cfg.n_products))]
            qty = int(max(1, rng.poisson(2)))
            unit = float(prod["base_price"]) * float(rng.normal(1.0, 0.06))
            disc = float(np.clip(rng.normal(0.05, 0.05), 0, 0.4))
            gross = qty * unit
            net = gross * (1 - disc)

            rows.append(
                {
                    "txn_id": int(txn_base + t),
                    "txn_ts": (d + pd.Timedelta(minutes=int(rng.integers(0, 1440)))).strftime("%Y-%m-%d %H:%M:%S"),
                    "store_code": s["store_id"],
                    "product_sku": prod["sku"],
                    "qty": int(qty),
                    "unit_price": round(unit, 2),
                    "discount_pct": round(disc, 4),
                    "gross_amount": round(gross, 2),
                    "net_amount": round(net, 2),
                }
            )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    df = maybe_duplicates(df, rng, cfg.pct_duplicate / 2)
    df["store_code"] = maybe_missing(df["store_code"], rng, cfg.pct_missing_store / 2)

    n = int(max(1, round(len(df) * cfg.pct_bad_date_format)))
    idx = rng.choice(df.index.to_numpy(), size=min(n, len(df)), replace=False)
    ts = pd.to_datetime(df.loc[idx, "txn_ts"], errors="coerce")
    df.loc[idx, "txn_ts"] = ts.dt.strftime("%m/%d/%Y %H:%M").fillna(df.loc[idx, "txn_ts"])

    return df


def gen_inventory_snapshot_day(cfg: Config, rng: np.random.Generator, d: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    for _, s in stores.iterrows():
        for prod in WYLD_PRODUCTS[: cfg.n_products]:
            on_hand = int(max(0, rng.normal(120, 40)))
            receipts = int(max(0, rng.normal(15, 10))) if rng.random() < 0.18 else 0
            shipments = int(max(0, rng.normal(10, 8)))
            requested = int(max(shipments, shipments * rng.uniform(1.0, 1.1)))
            shipped = int(min(on_hand, requested))
            backordered = int(max(0, requested - shipped))
            end_oh = int(max(0, on_hand - shipped + receipts))

            rows.append(
                {
                    "snapshot_date": d.strftime("%Y-%m-%d"),
                    "site_code": s["store_id"],
                    "sku": prod["sku"],
                    "on_hand": end_oh,
                    "receipts": int(receipts),
                    "shipments": int(shipped),
                    "requested_units": int(requested),
                    "backordered_units": int(backordered),
                }
            )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    n = int(max(1, round(len(df) * cfg.pct_negative_inventory)))
    idx = rng.choice(df.index.to_numpy(), size=min(n, len(df)), replace=False)
    df.loc[idx, "on_hand"] = -df.loc[idx, "on_hand"].abs().clip(lower=1)

    site_idx = rng.choice(df.index.to_numpy(), size=min(20, len(df)), replace=False)
    half = len(site_idx) // 2
    df.loc[site_idx[:half], "site_code"] = df.loc[site_idx[:half], "site_code"].astype(str).str.lower()
    df.loc[site_idx[half:], "site_code"] = df.loc[site_idx[half:], "site_code"].astype(str).str.replace(
        r"([A-Z]{2})(\d+)", r"\1-\2", regex=True
    )

    return df.rename(
        columns={
            "snapshot_date": "Snapshot Date",
            "site_code": "Site Code",
            "on_hand": "On Hand",
            "requested_units": "Requested Units",
            "backordered_units": "Backordered Units",
        }
    )


def gen_wms_shipments_day(cfg: Config, rng: np.random.Generator, d: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    base_id = int(d.strftime("%Y%m%d")) * 10000
    carriers = ["UPS", "FedEx", "OnTrac", "USPS"]

    sample_stores = stores.sample(
        n=min(len(stores), max(5, cfg.n_stores // 3)),
        random_state=int(rng.integers(1, 1_000_000)),
    )

    for _, s in sample_stores.iterrows():
        for j in range(int(rng.integers(3, 15))):
            prod = WYLD_PRODUCTS[int(rng.integers(0, cfg.n_products))]
            units = int(max(1, rng.poisson(6)))
            rows.append(
                {
                    "ship_date": d.strftime("%Y-%m-%d"),
                    "shipment_id": f"SHP{base_id + j}",
                    "site_code": s["store_id"],
                    "sku": prod["sku"],
                    "units_shipped": int(units),
                    "carrier": str(rng.choice(carriers)),
                }
            )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    df = maybe_duplicates(df, rng, cfg.pct_duplicate / 3)
    df["sku"] = maybe_missing(df["sku"], rng, 0.002)
    return df


def gen_timeclock_day(cfg: Config, rng: np.random.Generator, d: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    sample_stores = stores.sample(
        n=min(len(stores), max(5, cfg.n_stores // 2)),
        random_state=int(rng.integers(1, 1_000_000)),
    )

    for _, s in sample_stores.iterrows():
        n_emp = int(max(2, rng.poisson(6)))
        for _ in range(n_emp):
            emp_id = int(rng.integers(10000, 99999))
            start = d + pd.Timedelta(hours=int(rng.integers(6, 11)), minutes=int(rng.integers(0, 60)))
            end = start + pd.Timedelta(hours=float(rng.normal(8.0, 0.8)))
            rows.append({"punch_ts": start.strftime("%Y-%m-%d %H:%M:%S"), "employee_id": emp_id, "site_code": s["store_id"], "action": "IN"})
            if rng.random() > 0.04:
                rows.append({"punch_ts": end.strftime("%Y-%m-%d %H:%M:%S"), "employee_id": emp_id, "site_code": s["store_id"], "action": "OUT"})

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    idx = rng.choice(df.index.to_numpy(), size=min(25, len(df)), replace=False)
    ts = pd.to_datetime(df.loc[idx, "punch_ts"], errors="coerce")
    df.loc[idx, "punch_ts"] = ts.dt.strftime("%m/%d/%Y %H:%M").fillna(df.loc[idx, "punch_ts"])
    return df


def gen_payroll_week(cfg: Config, rng: np.random.Generator, week_end: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    teams = ["Fulfillment", "Warehouse", "Field Sales", "FP&A", "HR", "Manufacturing", "Planning", "Corporate"]
    departments = {
        "Fulfillment": "Operations",
        "Warehouse": "Operations",
        "Field Sales": "Sales",
        "FP&A": "Finance",
        "HR": "People",
        "Manufacturing": "Operations",
        "Planning": "Supply Chain",
        "Corporate": "G&A",
    }

    rows: list[dict[str, Any]] = []
    for _, s in stores.iterrows():
        for t in teams:
            hc = int(max(1, rng.poisson(3)))
            hours = float(max(0, rng.normal(8.0 * 5 * hc, 8.0)))
            ot = float(max(0, rng.normal(0.08 * hours, 2.0))) if rng.random() < 0.25 else 0.0
            rate = float(rng.normal(28.0, 6.0))
            cost = hours * rate + ot * rate * 0.5
            rows.append(
                {
                    "week_ending": week_end.strftime("%Y-%m-%d"),
                    "site_code": s["store_id"],
                    "department": departments[t],
                    "team": t,
                    "hours_worked": round(hours, 2),
                    "ot_hours": round(ot, 2),
                    "employee_count": hc,
                    "labor_cost": round(cost, 2),
                }
            )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    idx = rng.choice(df.index.to_numpy(), size=min(20, len(df)), replace=False)
    df.loc[idx, "team"] = df.loc[idx, "team"].replace({"Fulfillment": "Fulfilment"})

    bad_idx = rng.choice(df.index.to_numpy(), size=min(5, len(df)), replace=False)
    df.loc[bad_idx, "hours_worked"] = 0
    df.loc[bad_idx, "labor_cost"] = df.loc[bad_idx, "labor_cost"].clip(lower=50)

    return df.rename(
        columns={
            "week_ending": "Week Ending",
            "site_code": "Site Code",
            "hours_worked": "Hours Worked",
            "ot_hours": "OT Hours",
            "employee_count": "Employee Count",
            "labor_cost": "Labor Cost",
        }
    )


def gen_finance_actuals_month(cfg: Config, rng: np.random.Generator, month_start: pd.Timestamp) -> pd.DataFrame:
    metric_labels = {
        "gross_sales": ["Gross Sales", "gross_sales", "GROSS_SALES"],
        "net_sales": ["Net Sales", "net_sales", "NET_SALES"],
        "cogs": ["COGS", "cogs", "Cost of Goods"],
        "gross_margin": ["Gross Margin", "gross_margin"],
        "labor_cost": ["Labor Cost", "labor_cost"],
    }

    base = {
        "gross_sales": float(rng.uniform(250000, 900000)),
        "net_sales": float(rng.uniform(220000, 820000)),
        "cogs": float(rng.uniform(90000, 360000)),
        "labor_cost": float(rng.uniform(55000, 180000)),
    }
    base["gross_margin"] = base["net_sales"] - base["cogs"]

    rows: list[dict[str, Any]] = []
    for k, v in base.items():
        drift = float(rng.normal(0.0, 0.008))
        if rng.random() < 0.20:
            drift += float(rng.choice([-0.012, 0.013]))
        rows.append(
            {
                "month_start": month_start.date().isoformat(),
                "metric_name": str(rng.choice(metric_labels[k])),
                "actual_amount": round(v * (1 + drift), 2),
                "currency_code": "USD",
            }
        )

    df = pd.DataFrame(rows)
    return df.rename(columns={"month_start": "Month Start", "metric_name": "Metric Name", "actual_amount": "Actual Amount", "currency_code": "Currency"})


def gen_gl_detail_month(cfg: Config, rng: np.random.Generator, month_start: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    period = month_start.strftime("%Y-%m")
    accounts = [("4000", "Revenue"), ("4010", "Discounts"), ("5000", "COGS"), ("6100", "Labor")]
    rows: list[dict[str, Any]] = []
    n = int(rng.integers(500, 1200))

    for _ in range(n):
        acct, name = accounts[int(rng.integers(0, len(accounts)))]
        loc = stores.iloc[int(rng.integers(0, len(stores)))]["store_id"]
        posting = month_start + pd.Timedelta(days=int(rng.integers(0, 27)))
        amt = float(max(0.0, rng.normal(500.0, 350.0)))
        if acct == "4010":
            amt = -amt
        debit = amt if amt > 0 else 0.0
        credit = -amt if amt < 0 else 0.0

        rows.append(
            {
                "period": period,
                "posting_date": posting.strftime("%Y-%m-%d"),
                "location_code": loc,
                "account_code": acct if rng.random() > 0.02 else f"{acct}-",
                "account_name": name,
                "debit_amount": round(debit, 2),
                "credit_amount": round(credit, 2),
            }
        )

    df = pd.DataFrame(rows)
    df["location_code"] = maybe_missing(df["location_code"], rng, 0.003)
    return df


# -----------------------------
# PostgreSQL helpers
# -----------------------------

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


def _pg_ident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def _infer_pg_type(s: pd.Series) -> str:
    if pd.api.types.is_bool_dtype(s):
        return "boolean"
    if pd.api.types.is_integer_dtype(s):
        return "bigint"
    if pd.api.types.is_float_dtype(s):
        return "double precision"
    if pd.api.types.is_datetime64_any_dtype(s):
        return "timestamp"
    return "text"


def _normalize_df_for_pg(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    for c in out.columns:
        if pd.api.types.is_datetime64_any_dtype(out[c]):
            out[c] = pd.to_datetime(out[c], errors="coerce").dt.strftime("%Y-%m-%d %H:%M:%S")
    out = out.where(pd.notnull(out), None)
    return out


def pg_exec(con, sql: str) -> None:
    with con.cursor() as cur:
        cur.execute(sql)
    con.commit()


def pg_ensure_schema(con, schema: str) -> None:
    pg_exec(con, f"create schema if not exists {_pg_ident(schema)};")


def pg_ensure_table(con, schema: str, table: str, df: pd.DataFrame) -> None:
    cols = [f"{_pg_ident(c)} {_infer_pg_type(df[c])}" for c in df.columns]
    ddl_cols = ", ".join(cols)
    pg_exec(
        con,
        f"""
        create table if not exists {_pg_ident(schema)}.{_pg_ident(table)} (
          {ddl_cols}
        );
        """,
    )


def pg_ensure_columns(con, schema: str, table: str, col_types: dict[str, str]) -> None:
    # Adds missing columns (safe idempotent-ish).
    for c, t in col_types.items():
        try:
            pg_exec(con, f'alter table {_pg_ident(schema)}.{_pg_ident(table)} add column {_pg_ident(c)} {t};')
        except Exception:
            con.rollback()


def pg_copy_append(con, schema: str, table: str, df: pd.DataFrame) -> None:
    if len(df) == 0:
        return

    buf = StringIO()
    df.to_csv(buf, index=False, header=False)
    buf.seek(0)

    cols = ", ".join(_pg_ident(c) for c in df.columns)
    sql = f"copy {_pg_ident(schema)}.{_pg_ident(table)} ({cols}) from stdin with (format csv)"

    with con.cursor() as cur:
        if hasattr(cur, "copy"):  # psycopg v3
            with cur.copy(sql) as copy:
                copy.write(buf.getvalue())
        else:  # psycopg2
            cur.copy_expert(sql, buf)
    con.commit()


# -----------------------------
# Main
# -----------------------------

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", default="2025-01-01")
    ap.add_argument("--end", default="2025-01-14")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--stores", type=int, default=40)
    ap.add_argument("--products", type=int, default=15)

    ap.add_argument("--base", default=".", help="Write outputs under this subfolder (use . for repo root)")

    ap.add_argument("--pg-dsn", default=os.getenv("PROJECT1_PG_DSN", ""), help="Postgres DSN (or set env PROJECT1_PG_DSN)")
    ap.add_argument("--pg-schema", default=os.getenv("PROJECT1_PG_SCHEMA", "raw"), help="Target schema (default: raw)")
    ap.add_argument("--pg-pos-table", default=os.getenv("PROJECT1_PG_POS_TABLE", "project1_pos_transactions"))
    ap.add_argument("--pg-gl-table", default=os.getenv("PROJECT1_PG_GL_TABLE", "project1_gl_detail"))
    ap.add_argument("--pg-add-metadata", choices=["1", "0"], default=os.getenv("PROJECT1_PG_ADD_METADATA", "1"))

    args = ap.parse_args()
    if not args.pg_dsn.strip():
        raise SystemExit("Missing Postgres DSN. Provide --pg-dsn or set env PROJECT1_PG_DSN.")

    cfg = Config(start=args.start, end=args.end, seed=args.seed, n_stores=args.stores, n_products=args.products)

    repo = get_repo_root()
    root = repo if args.base in (".", "", None) else (repo / args.base)
    ensure_dirs(root)

    rng = np.random.default_rng(cfg.seed)
    stores = make_stores(cfg.n_stores)

    day_range = pd.date_range(cfg.start, cfg.end, freq="D")
    week_range = pd.date_range(cfg.start, cfg.end, freq="W-SUN")
    month_range = pd.date_range(cfg.start, cfg.end, freq="MS")

    load_id = uuid.uuid4().hex[:12]
    add_meta = args.pg_add_metadata == "1"

    con = pg_connect(args.pg_dsn)
    pg_ensure_schema(con, args.pg_schema)

    manifest_rows: list[dict[str, Any]] = []

    def log(
        *,
        domain: str,
        system: str,
        cadence: str,
        drop_date: pd.Timestamp,
        file_path: Optional[Path],
        file_type: str,
        rows: int,
        notes: str,
        target: Optional[str] = None,
    ) -> None:
        rel = str(file_path.relative_to(root)) if file_path is not None else ""
        manifest_rows.append(
            {
                "domain": domain,
                "system": system,
                "cadence": cadence,
                "drop_date": drop_date.date().isoformat(),
                "file_type": file_type,
                "relative_path": rel,
                "target": target or "",
                "row_count": int(rows),
                "notes": notes,
                "load_id": load_id,
            }
        )

    # DAILY
    for d in day_range:
        # sales: distributor csv
        dist = gen_sales_distributor_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "sales", "distributor", d)
        p_cur = current_dir(root, "sales", "distributor")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "sales_distributor_extract.csv"
        f_cur = p_cur / "sales_distributor_extract.csv"
        dist.to_csv(f_in, index=False)
        dist.to_csv(f_cur, index=False)
        log(domain="sales", system="distributor", cadence="daily", drop_date=d, file_path=f_in, file_type="csv", rows=len(dist),
            notes="duplicates, missing Store ID, channel casing/whitespace, date format mix")

        # sales: pos csv
        pos = gen_pos_transactions_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "sales", "pos", d)
        p_cur = current_dir(root, "sales", "pos")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "pos_transactions.csv"
        f_cur = p_cur / "pos_transactions.csv"
        pos.to_csv(f_in, index=False)
        pos.to_csv(f_cur, index=False)
        log(domain="sales", system="pos", cadence="daily", drop_date=d, file_path=f_in, file_type="csv", rows=len(pos),
            notes="row-level POS; some bad datetime formats")

        # sales: pos DB load (postgres)
        dfp = _normalize_df_for_pg(pos)
        if add_meta:
            dfp["drop_date"] = d.date().isoformat()
            dfp["load_id"] = load_id

        pg_ensure_table(con, args.pg_schema, args.pg_pos_table, dfp)
        if add_meta:
            pg_ensure_columns(con, args.pg_schema, args.pg_pos_table, {"drop_date": "text", "load_id": "text"})
        pg_copy_append(con, args.pg_schema, args.pg_pos_table, dfp)

        log(domain="sales", system="pos", cadence="daily", drop_date=d, file_path=None, file_type="postgres", rows=len(dfp),
            notes="loaded to postgres", target=f"{args.pg_schema}.{args.pg_pos_table}")

        # ops: erp snapshot csv
        inv = gen_inventory_snapshot_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "ops", "erp", d)
        p_cur = current_dir(root, "ops", "erp")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "inventory_erp_snapshot.csv"
        f_cur = p_cur / "inventory_erp_snapshot.csv"
        inv.to_csv(f_in, index=False)
        inv.to_csv(f_cur, index=False)
        log(domain="ops", system="erp", cadence="daily", drop_date=d, file_path=f_in, file_type="csv", rows=len(inv),
            notes="negative On Hand exceptions; site code drift")

        # ops: wms shipments csv
        wms = gen_wms_shipments_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "ops", "wms", d)
        p_cur = current_dir(root, "ops", "wms")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "wms_shipments.csv"
        f_cur = p_cur / "wms_shipments.csv"
        wms.to_csv(f_in, index=False)
        wms.to_csv(f_cur, index=False)
        log(domain="ops", system="wms", cadence="daily", drop_date=d, file_path=f_in, file_type="csv", rows=len(wms),
            notes="duplicates; occasional missing sku")

        # people: timeclock csv
        tc = gen_timeclock_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "people", "timeclock", d)
        p_cur = current_dir(root, "people", "timeclock")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "timeclock_punches.csv"
        f_cur = p_cur / "timeclock_punches.csv"
        tc.to_csv(f_in, index=False)
        tc.to_csv(f_cur, index=False)
        log(domain="people", system="timeclock", cadence="daily", drop_date=d, file_path=f_in, file_type="csv", rows=len(tc),
            notes="missing OUT punches; mixed timestamp formats")

    # WEEKLY
    for we in week_range:
        payroll = gen_payroll_week(cfg, rng, we, stores)
        p_in = incoming_dir(root, "people", "payroll", we)
        p_cur = current_dir(root, "people", "payroll")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "labor_hours_payroll_export.xlsx"
        f_cur = p_cur / "labor_hours_payroll_export.xlsx"
        with pd.ExcelWriter(f_in, engine="openpyxl") as w:
            payroll.to_excel(w, index=False, sheet_name="payroll")
        with pd.ExcelWriter(f_cur, engine="openpyxl") as w:
            payroll.to_excel(w, index=False, sheet_name="payroll")
        log(domain="people", system="payroll", cadence="weekly", drop_date=we, file_path=f_in, file_type="xlsx", rows=len(payroll),
            notes="team spelling variation; zero-hour rows with cost")

    # MONTHLY
    for ms in month_range:
        fin = gen_finance_actuals_month(cfg, rng, ms)
        p_in = incoming_dir(root, "finance", "erp_finance", ms)
        p_cur = current_dir(root, "finance", "erp_finance")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "finance_actuals_summary.xlsx"
        f_cur = p_cur / "finance_actuals_summary.xlsx"
        with pd.ExcelWriter(f_in, engine="openpyxl") as w:
            fin.to_excel(w, index=False, sheet_name="actuals")
        with pd.ExcelWriter(f_cur, engine="openpyxl") as w:
            fin.to_excel(w, index=False, sheet_name="actuals")
        log(domain="finance", system="erp_finance", cadence="monthly", drop_date=ms, file_path=f_in, file_type="xlsx", rows=len(fin),
            notes="metric label variance; small drift")

        # GL: write CSV extract AND load to Postgres
        gl = gen_gl_detail_month(cfg, rng, ms, stores)
        p_in = incoming_dir(root, "finance", "gl", ms)
        p_cur = current_dir(root, "finance", "gl")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)
        f_in = p_in / "gl_detail.csv"
        f_cur = p_cur / "gl_detail.csv"
        gl.to_csv(f_in, index=False)
        gl.to_csv(f_cur, index=False)
        log(domain="finance", system="gl", cadence="monthly", drop_date=ms, file_path=f_in, file_type="csv", rows=len(gl),
            notes="GL detail extract; missing location; account code drift")

        dfg = _normalize_df_for_pg(gl)
        if add_meta:
            dfg["drop_month"] = ms.date().isoformat()
            dfg["load_id"] = load_id

        pg_ensure_table(con, args.pg_schema, args.pg_gl_table, dfg)
        if add_meta:
            pg_ensure_columns(con, args.pg_schema, args.pg_gl_table, {"drop_month": "text", "load_id": "text"})
        pg_copy_append(con, args.pg_schema, args.pg_gl_table, dfg)
        log(domain="finance", system="gl", cadence="monthly", drop_date=ms, file_path=None, file_type="postgres", rows=len(dfg),
            notes="loaded to postgres", target=f"{args.pg_schema}.{args.pg_gl_table}")

    con.close()

    manifest = pd.DataFrame(manifest_rows)
    out_manifest = root / "docs" / "source_drop_manifest.csv"
    manifest.to_csv(out_manifest, index=False)

    print("\n✅ Source drops generated.")
    print("Backend: postgres")
    print("Postgres targets:")
    print(f"  - {args.pg_schema}.{args.pg_pos_table}")
    print(f"  - {args.pg_schema}.{args.pg_gl_table}")
    print(f"Manifest: {out_manifest}")
    print(f"Rows in manifest: {len(manifest):,}")
    print(f"Load ID: {load_id}\n")


if __name__ == "__main__":
    main()