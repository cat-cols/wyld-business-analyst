#!/usr/bin/env python3
# scripts/source_drop_simulator.py
"""
Multi-source drop simulator (Project 1 realism layer) using PostgreSQL ONLY.

What this version fixes vs prior:
1) Stable typing in Postgres: tables are created with explicit schemas (not inferred from pandas).
2) Integration keys: each raw table gets normalized join keys (e.g., store_code_norm, sku_norm),
   and parsed date/timestamp columns (e.g., txn_ts_parsed).
3) Full raw landing zone: ALL sources land in Postgres raw tables (not only POS + GL),
   while still writing messy files into data/source_extracts/... for realism.

Cadences / drops written to disk:
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

Postgres raw loads (all sources):
- raw.sales_distributor
- raw.pos_transactions
- raw.inventory_erp_snapshot
- raw.wms_shipments
- raw.timeclock_punches
- raw.payroll_weekly
- raw.finance_actuals_summary
- raw.gl_detail_csv

Writes drops under:
  data/source_extracts/<domain>/<system>/incoming/YYYY/MM/DD/<file>
And updates the latest copy under:
  data/source_extracts/<domain>/<system>/current/<file>

Also writes a manifest to:
  docs/source_drop_manifest.csv

No hardcoded paths: repo root is derived from this file location.

Dependencies:
  pandas, numpy, openpyxl
  psycopg (preferred) OR psycopg2
"""

from __future__ import annotations

import argparse
import os
import re
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
    # country = ["United States", "Canada"]
    rows = []
    for i in range(1, n + 1):
        st = states[(i - 1) % len(states)]
        rows.append({"store_id": f"{st}{i:03d}", "store_name": f"{st} Account {i:03d}", "state": st, "country": "US"})
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

def gen_account_status_day(cfg: Config, rng: np.random.Generator, d: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    statuses = ["Active", "Inactive", "Suspended", "Pending"]
    reasons = {
        "Active": ["In good standing", "Onboarding complete", "Reactivated"],
        "Inactive": ["No recent orders", "Closed location", "Seasonal"],
        "Suspended": ["Compliance hold", "Payment issue", "Contract dispute"],
        "Pending": ["Onboarding", "Awaiting documents", "Credit review"],
    }

    rows: list[dict[str, Any]] = []
    for _, s in stores.iterrows():
        p = rng.random()
        if p < 0.78:
            st = "Active"
        elif p < 0.90:
            st = "Inactive"
        elif p < 0.96:
            st = "Pending"
        else:
            st = "Suspended"

        rows.append(
            {
                "status_date": d.strftime("%Y-%m-%d"),
                "store_code": s["store_id"],
                "account_status": st,
                "status_reason": str(rng.choice(reasons[st])),
            }
        )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    # inject mess similar to your other sources
    df = maybe_duplicates(df, rng, cfg.pct_duplicate / 2)
    df["store_code"] = maybe_missing(df["store_code"], rng, cfg.pct_missing_store / 2)
    df["account_status"] = maybe_channel_mess(df["account_status"], rng, 0.08)  # casing/whitespace
    df["status_reason"] = maybe_trailing_spaces(df["status_reason"], rng, 0.06)
    df["status_date"] = maybe_bad_date_format(df["status_date"], rng, cfg.pct_bad_date_format / 2)

    # optional header drift (keeps it realistic)
    return df.rename(
        columns={
            "status_date": "Status Date",
            "store_code": "Store Code",
            "account_status": "Account Status",
            "status_reason": "Status Reason",
        }
    )

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

    # header drift (mess)
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

def gen_finance_actuals_month_from_truth(
    rng: np.random.Generator,
    month_start: pd.Timestamp,
    sales_monthly: pd.DataFrame,
    labor_monthly: pd.DataFrame,
) -> pd.DataFrame:
    metric_labels = {
        "gross_sales": ["Gross Sales", "gross_sales", "GROSS_SALES"],
        "net_sales": ["Net Sales", "net_sales", "NET_SALES"],
        "cogs": ["COGS", "cogs", "Cost of Goods"],
        "gross_margin": ["Gross Margin", "gross_margin"],
        "labor_cost": ["Labor Cost", "labor_cost"],
    }

    sm = sales_monthly.loc[sales_monthly["period_month"] == month_start].copy()
    lm = labor_monthly.loc[labor_monthly["period_month"] == month_start].copy()

    gross_sales = float(sm["gross_sales"].sum())
    net_sales = float(sm["net_sales"].sum())
    cogs = float(sm["cogs"].sum())
    labor_cost = float(lm["labor_cost"].sum()) if not lm.empty else 0.0

    # apply small finance drift / close adjustments
    def drift(v: float, std: float = 0.006, extra_prob: float = 0.15) -> float:
        d = float(rng.normal(0.0, std))
        if rng.random() < extra_prob:
            d += float(rng.choice([-0.01, 0.01]))
        return round(v * (1 + d), 2)

    finance_base = {
        "gross_sales": drift(gross_sales),
        "net_sales": drift(net_sales),
        "cogs": drift(cogs),
        "labor_cost": drift(labor_cost),
    }
    finance_base["gross_margin"] = round(finance_base["net_sales"] - finance_base["cogs"], 2)

    rows = []
    for k, v in finance_base.items():
        rows.append(
            {
                "Month Start": month_start.date().isoformat(),
                "Metric Name": str(rng.choice(metric_labels[k])),
                "Actual Amount": v,
                "Currency": "USD",
            }
        )

    return pd.DataFrame(rows)

# def gen_finance_actuals_month(cfg: Config, rng: np.random.Generator, month_start: pd.Timestamp) -> pd.DataFrame:
#     metric_labels = {
#         "gross_sales": ["Gross Sales", "gross_sales", "GROSS_SALES"],
#         "net_sales": ["Net Sales", "net_sales", "NET_SALES"],
#         "cogs": ["COGS", "cogs", "Cost of Goods"],
#         "gross_margin": ["Gross Margin", "gross_margin"],
#         "labor_cost": ["Labor Cost", "labor_cost"],
#     }

#     base = {
#         "gross_sales": float(rng.uniform(250000, 900000)),
#         "net_sales": float(rng.uniform(220000, 820000)),
#         "cogs": float(rng.uniform(90000, 360000)),
#         "labor_cost": float(rng.uniform(55000, 180000)),
#     }
#     base["gross_margin"] = base["net_sales"] - base["cogs"]

#     rows: list[dict[str, Any]] = []
#     for k, v in base.items():
#         drift = float(rng.normal(0.0, 0.008))
#         if rng.random() < 0.20:
#             drift += float(rng.choice([-0.012, 0.013]))
#         rows.append(
#             {
#                 "month_start": month_start.date().isoformat(),
#                 "metric_name": str(rng.choice(metric_labels[k])),
#                 "actual_amount": round(v * (1 + drift), 2),
#                 "currency_code": "USD",
#             }
#         )

#     df = pd.DataFrame(rows)
#     return df.rename(columns={"month_start": "Month Start", "metric_name": "Metric Name", "actual_amount": "Actual Amount", "currency_code": "Currency"})


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

def gen_dispensary_master_day(
    cfg: Config,
    rng: np.random.Generator,
    d: pd.Timestamp,
    stores: pd.DataFrame
) -> pd.DataFrame:
    """
    Dispensary master snapshot (reference system).
    One row per store/account, with stable identifiers + some realistic drift/mess.
    Output is *messy* (header drift), like your other file drops.
    """

    # lightweight city pool by state
    cities = {
        "OR": ["Portland", "Eugene", "Salem", "Bend", "Gresham"],
        "WA": ["Seattle", "Tacoma", "Spokane", "Vancouver", "Olympia"],
        "CA": ["Los Angeles", "San Diego", "San Jose", "Sacramento", "Oakland"],
        "CO": ["Denver", "Boulder", "Aurora", "Fort Collins", "Colorado Springs"],
        "AZ": ["Phoenix", "Tucson", "Mesa", "Tempe", "Scottsdale"],
        "NV": ["Las Vegas", "Reno", "Henderson", "Sparks", "Carson City"],
        "IL": ["Chicago", "Aurora", "Naperville", "Joliet", "Evanston"],
        "MI": ["Detroit", "Grand Rapids", "Ann Arbor", "Lansing", "Flint"],
    }

    acct_types = ["Sell-To", "Not Sell-To", "Prospect", "House", "Key Account"]

    rows: list[dict[str, Any]] = []
    for i, s in enumerate(stores.itertuples(index=False), start=1):
        state = getattr(s, "state", None) or str(getattr(s, "store_id"))[:2]
        city = str(rng.choice(cities.get(state, ["Unknown"])))

        # stable-ish ids
        dispensary_id = f"DSP{i:05d}"
        store_code = getattr(s, "store_id")

        # make plausible postal
        postal = f"{int(rng.integers(97000, 99950)):05d}" if state in ("OR", "WA") else f"{int(rng.integers(10000, 99950)):05d}"

        # license formats vary by state (fake but plausible)
        license_id = f"{state}-LIC-{int(rng.integers(100000, 999999))}"

        name = getattr(s, "store_name", None) or f"{state} Dispensary {i:03d}"
        acct_type = str(rng.choice(acct_types))

        rows.append(
            {
                "as_of_date": d.strftime("%Y-%m-%d"),
                "dispensary_id": dispensary_id,
                "store_code": store_code,
                "dispensary_name": name,
                "state": state,
                "city": city,
                "postal_code": postal,
                "license_id": license_id,
                "account_type": acct_type,
            }
        )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    # ---- inject mess (like your other sources) ----
    df = maybe_duplicates(df, rng, cfg.pct_duplicate / 3)

    # occasional missing keys
    df["dispensary_id"] = maybe_missing(df["dispensary_id"], rng, 0.01)
    df["store_code"] = maybe_missing(df["store_code"], rng, cfg.pct_missing_store / 3)

    # casing/whitespace drift
    df["dispensary_name"] = maybe_trailing_spaces(df["dispensary_name"], rng, 0.06)
    df["city"] = maybe_channel_mess(df["city"], rng, 0.08)          # reuses your casing/whitespace injector
    df["account_type"] = maybe_channel_mess(df["account_type"], rng, 0.10)

    # date format mix
    df["as_of_date"] = maybe_bad_date_format(df["as_of_date"], rng, cfg.pct_bad_date_format / 3)

    # slight postal mess (ZIP+4 sometimes)
    idx = rng.choice(df.index.to_numpy(), size=min(10, len(df)), replace=False)
    df.loc[idx, "postal_code"] = df.loc[idx, "postal_code"].astype(str) + "-" + rng.integers(1000, 9999, size=len(idx)).astype(str)

    # optional header drift to look like a messy extract
    return df.rename(
        columns={
            "as_of_date": "As Of Date",
            "dispensary_id": "Dispensary ID",
            "store_code": "Store Code",
            "dispensary_name": "Dispensary Name",
            "state": "State",
            "city": "City",
            "postal_code": "Postal Code",
            "license_id": "License ID",
            "account_type": "Account Type",
        }
    )

def gen_sku_distribution_status_day(cfg: Config, rng: np.random.Generator, d: pd.Timestamp, stores: pd.DataFrame) -> pd.DataFrame:
    """
    Daily snapshot: for each store and SKU, whether that SKU is carried / not_carried / pending / discontinued.

    Returns a MESSY dataframe with header drift:
      As Of Date, Store Code, SKU, Distribution Status, Status Reason
    """
    statuses = ["Carried", "Not Carried", "Pending", "Discontinued"]
    reasons = {
        "Carried": ["Active assortment", "Top seller", "Seasonal promo", "Core lineup"],
        "Not Carried": ["Not authorized", "No demand", "Out of scope", "Limited shelf space"],
        "Pending": ["Onboarding", "Awaiting PO", "Awaiting compliance docs", "License verification"],
        "Discontinued": ["Discontinued SKU", "Replaced by new SKU", "Quality issue", "Low margin"],
    }

    rows: list[dict[str, Any]] = []

    # store-level "assortment intensity" so not every store carries everything
    store_intensity = {}
    for _, s in stores.iterrows():
        # Most stores carry a decent chunk; some are sparse.
        store_intensity[s["store_id"]] = float(np.clip(rng.normal(0.70, 0.18), 0.15, 0.95))

    for _, s in stores.iterrows():
        store_code = s["store_id"]
        intensity = store_intensity[store_code]

        for prod in WYLD_PRODUCTS[: cfg.n_products]:
            sku = prod["sku"]

            # probability of "carried" depends on store intensity + tiny sku wiggle
            p_carried = float(np.clip(intensity + rng.normal(0.0, 0.06), 0.05, 0.98))
            r = rng.random()

            if r < p_carried:
                st = "Carried"
            else:
                # non-carried states get split
                r2 = rng.random()
                if r2 < 0.55:
                    st = "Not Carried"
                elif r2 < 0.80:
                    st = "Pending"
                else:
                    st = "Discontinued"

            rows.append(
                {
                    "as_of_date": d.strftime("%Y-%m-%d"),
                    "store_code": store_code,
                    "sku": sku,
                    "distribution_status": st,
                    "status_reason": str(rng.choice(reasons[st])),
                }
            )

    df = pd.DataFrame(rows)
    if len(df) == 0:
        return df

    # --- inject mess ---
    df = maybe_duplicates(df, rng, cfg.pct_duplicate / 2)
    df["store_code"] = maybe_missing(df["store_code"], rng, cfg.pct_missing_store / 2)
    df["sku"] = maybe_missing(df["sku"], rng, 0.01)
    df["distribution_status"] = maybe_channel_mess(df["distribution_status"], rng, 0.10)  # casing/whitespace drift
    df["status_reason"] = maybe_trailing_spaces(df["status_reason"], rng, 0.08)
    df["as_of_date"] = maybe_bad_date_format(df["as_of_date"], rng, cfg.pct_bad_date_format / 2)

    # header drift (realistic upstream export)
    return df.rename(
        columns={
            "as_of_date": "As Of Date",
            "store_code": "Store Code",
            "sku": "SKU",
            "distribution_status": "Distribution Status",
            "status_reason": "Status Reason",
        }
    )


# -----------------------------
# Postgres helpers
# -----------------------------

def pg_drop_table(con, schema: str, table: str) -> None:
    pg_exec(con, f"drop table if exists {_pg_ident(schema)}.{_pg_ident(table)};")

def _try_import_psycopg():
    """
    Returns (module, kind) where kind is "psycopg" or "psycopg2".
    Raises ImportError if neither is available.
    """
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


def pg_exec(con, sql: str, params: Optional[tuple[Any, ...]] = None) -> None:
    with con.cursor() as cur:
        cur.execute(sql, params or None)
    con.commit()


def pg_ensure_schema(con, schema: str) -> None:
    pg_exec(con, f"create schema if not exists {_pg_ident(schema)};")


def pg_table_exists(con, schema: str, table: str) -> bool:
    q = """
    select 1
    from information_schema.tables
    where table_schema = %s and table_name = %s
    limit 1;
    """
    with con.cursor() as cur:
        cur.execute(q, (schema, table))
        return cur.fetchone() is not None


def pg_truncate(con, schema: str, table: str) -> None:
    pg_exec(con, f"truncate table {_pg_ident(schema)}.{_pg_ident(table)};")


def pg_ensure_table(con, schema: str, table: str, ddl_cols: list[str]) -> None:
    ddl = ", ".join(ddl_cols)
    sql = f"create table if not exists {_pg_ident(schema)}.{_pg_ident(table)} ({ddl});"
    pg_exec(con, sql)


def pg_copy_append(con, schema: str, table: str, df: pd.DataFrame) -> None:
    """
    Append via COPY FROM STDIN using CSV.

    Supports:
      - psycopg (v3): cur.copy(sql) context manager
      - psycopg2: cur.copy_expert(sql, file)
    """
    if len(df) == 0:
        return

    # COPY wants columns in target order; ensure stable.
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
# Normalization / standardization
# -----------------------------

def _norm_code(x: Any) -> Optional[str]:
    if x is None:
        return None
    s = str(x).strip()
    if s == "" or s.lower() in ("nan", "none"):
        return None
    s = s.upper()
    # remove spaces, normalize "OR-001" -> "OR001"
    s = re.sub(r"\s+", "", s)
    s = s.replace("-", "")
    return s


def _norm_channel(x: Any) -> Optional[str]:
    if x is None:
        return None
    s = str(x).strip().lower()
    if s == "" or s in ("nan", "none"):
        return None
    # keep just key buckets
    if "retail" in s:
        return "retail"
    if "wholesale" in s:
        return "wholesale"
    if "distrib" in s:
        return "distributor"
    return s


def _parse_date_any(x: Any) -> Optional[str]:
    if x is None:
        return None
    s = str(x).strip()
    if s == "" or s.lower() in ("nan", "none"):
        return None
    dt = pd.to_datetime(s, errors="coerce")
    if pd.isna(dt):
        return None
    return dt.date().isoformat()


def _parse_ts_any(x: Any) -> Optional[str]:
    if x is None:
        return None
    s = str(x).strip()
    if s == "" or s.lower() in ("nan", "none"):
        return None
    dt = pd.to_datetime(s, errors="coerce")
    if pd.isna(dt):
        return None
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def _to_int_or_none(x: Any) -> Optional[int]:
    try:
        if x is None or (isinstance(x, float) and np.isnan(x)):
            return None
        s = str(x).strip()
        if s == "" or s.lower() in ("nan", "none"):
            return None
        return int(float(s))
    except Exception:
        return None


def _to_float_or_none(x: Any) -> Optional[float]:
    try:
        if x is None or (isinstance(x, float) and np.isnan(x)):
            return None
        s = str(x).strip()
        if s == "" or s.lower() in ("nan", "none"):
            return None
        return float(s)
    except Exception:
        return None


def _ensure_cols(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    out = df.copy()
    for c in cols:
        if c not in out.columns:
            out[c] = None
    return out

def standardize_sku_distribution_status(df_mess: pd.DataFrame) -> pd.DataFrame:
    """
    Standardizes the messy SKU distribution status snapshot into stable raw landing columns:
      as_of_date_raw, as_of_date,
      store_code_raw, store_code_norm,
      sku_raw, sku_norm,
      distribution_status_raw, distribution_status_norm,
      status_reason_raw, status_reason_norm
    """
    rename = {
        "As Of Date": "as_of_date_raw",
        "Store Code": "store_code_raw",
        "SKU": "sku_raw",
        "Distribution Status": "distribution_status_raw",
        "Status Reason": "status_reason_raw",
        # tolerate already-clean headers too
        "as_of_date": "as_of_date_raw",
        "store_code": "store_code_raw",
        "sku": "sku_raw",
        "distribution_status": "distribution_status_raw",
        "status_reason": "status_reason_raw",
    }

    df = df_mess.rename(columns={k: v for k, v in rename.items() if k in df_mess.columns}).copy()
    df = _ensure_cols(
        df,
        [
            "as_of_date_raw",
            "store_code_raw",
            "sku_raw",
            "distribution_status_raw",
            "status_reason_raw",
        ],
    )

    def _norm_distribution_status(x: Any) -> Optional[str]:
        if x is None:
            return None
        s = str(x).strip().lower()
        if s == "" or s in ("nan", "none"):
            return None

        # IMPORTANT ordering: handle "not" before "carried"/"active"
        if "not" in s or "no " in s or "none" in s:
            return "not_carried"
        if "discont" in s or "de-list" in s or "delist" in s:
            return "discontinued"
        if "pend" in s or "await" in s or "onboard" in s:
            return "pending"
        if "carry" in s or "active" in s or "in dist" in s or "in_distribution" in s:
            return "carried"

        # fall back: keep a safe normalized token
        return s.replace(" ", "_")

    out = pd.DataFrame(
        {
            "as_of_date_raw": df["as_of_date_raw"],
            "as_of_date": df["as_of_date_raw"].map(_parse_date_any),

            "store_code_raw": df["store_code_raw"],
            "store_code_norm": df["store_code_raw"].map(_norm_code),

            "sku_raw": df["sku_raw"],
            "sku_norm": df["sku_raw"].map(_norm_code),

            "distribution_status_raw": df["distribution_status_raw"],
            "distribution_status_norm": df["distribution_status_raw"].map(_norm_distribution_status),

            "status_reason_raw": df["status_reason_raw"],
            "status_reason_norm": df["status_reason_raw"].map(lambda x: str(x).strip().lower() if x is not None else None),
        }
    )
    return out

def standardize_sales_distributor(df_mess: pd.DataFrame) -> pd.DataFrame:
    # Handle header drift from generator
    rename = {
        "Sale Date": "sale_date_raw",
        "Store ID": "store_id_raw",
        "Gross Sales": "gross_sales_raw",
        "Net Sales": "net_sales_raw",
        "Discount Amount": "discount_amount_raw",
        "Unit List Price": "unit_list_price_raw",
        "Unit Net Price": "unit_net_price_raw",
        "Discount Rate": "discount_rate_raw",
        # unchanged fields
        "sku": "sku",
        "product_name": "product_name_raw",
        "channel": "channel_raw",
        "qty": "qty_raw",
        "cogs": "cogs_raw",
        "orders": "orders_raw",
        "customers": "customers_raw",
    }
    df = df_mess.rename(columns=rename).copy()
    df = _ensure_cols(
        df,
        [
            "sale_date_raw",
            "store_id_raw",
            "sku",
            "product_name_raw",
            "channel_raw",
            "qty_raw",
            "unit_list_price_raw",
            "discount_rate_raw",
            "unit_net_price_raw",
            "gross_sales_raw",
            "discount_amount_raw",
            "net_sales_raw",
            "cogs_raw",
            "orders_raw",
            "customers_raw",
        ],
    )

    out = pd.DataFrame(
        {
            "sale_date_raw": df["sale_date_raw"],
            "sale_date": df["sale_date_raw"].map(_parse_date_any),
            "store_id_raw": df["store_id_raw"],
            "store_id_norm": df["store_id_raw"].map(_norm_code),
            "sku": df["sku"].map(_norm_code),
            "product_name_raw": df["product_name_raw"],
            "product_name_norm": df["product_name_raw"].map(lambda x: str(x).strip() if x is not None else None),
            "channel_raw": df["channel_raw"],
            "channel_norm": df["channel_raw"].map(_norm_channel),
            "qty_raw": df["qty_raw"],
            "qty": df["qty_raw"].map(_to_int_or_none),
            "unit_list_price_raw": df["unit_list_price_raw"],
            "unit_list_price": df["unit_list_price_raw"].map(_to_float_or_none),
            "discount_rate_raw": df["discount_rate_raw"],
            "discount_rate": df["discount_rate_raw"].map(_to_float_or_none),
            "unit_net_price_raw": df["unit_net_price_raw"],
            "unit_net_price": df["unit_net_price_raw"].map(_to_float_or_none),
            "gross_sales_raw": df["gross_sales_raw"],
            "gross_sales": df["gross_sales_raw"].map(_to_float_or_none),
            "discount_amount_raw": df["discount_amount_raw"],
            "discount_amount": df["discount_amount_raw"].map(_to_float_or_none),
            "net_sales_raw": df["net_sales_raw"],
            "net_sales": df["net_sales_raw"].map(_to_float_or_none),
            "cogs_raw": df["cogs_raw"],
            "cogs": df["cogs_raw"].map(_to_float_or_none),
            "orders_raw": df["orders_raw"],
            "orders": df["orders_raw"].map(_to_int_or_none),
            "customers_raw": df["customers_raw"],
            "customers": df["customers_raw"].map(_to_int_or_none),
        }
    )
    return out


def standardize_pos(df_raw: pd.DataFrame) -> pd.DataFrame:
    df = _ensure_cols(
        df_raw,
        ["txn_id", "txn_ts", "store_code", "product_sku", "qty", "unit_price", "discount_pct", "gross_amount", "net_amount"],
    )

    out = pd.DataFrame(
        {
            "txn_id": df["txn_id"].map(_to_int_or_none),
            "txn_ts_raw": df["txn_ts"],
            "txn_ts_parsed": df["txn_ts"].map(_parse_ts_any),
            "txn_date": df["txn_ts"].map(lambda x: (_parse_date_any(x) if x is not None else None)),
            "store_code_raw": df["store_code"],
            "store_code_norm": df["store_code"].map(_norm_code),
            "product_sku_raw": df["product_sku"],
            "product_sku_norm": df["product_sku"].map(_norm_code),
            "qty_raw": df["qty"],
            "qty": df["qty"].map(_to_int_or_none),
            "unit_price_raw": df["unit_price"],
            "unit_price": df["unit_price"].map(_to_float_or_none),
            "discount_pct_raw": df["discount_pct"],
            "discount_pct": df["discount_pct"].map(_to_float_or_none),
            "gross_amount_raw": df["gross_amount"],
            "gross_amount": df["gross_amount"].map(_to_float_or_none),
            "net_amount_raw": df["net_amount"],
            "net_amount": df["net_amount"].map(_to_float_or_none),
        }
    )
    return out


def standardize_inventory_snapshot(df_mess: pd.DataFrame) -> pd.DataFrame:
    rename = {
        "Snapshot Date": "snapshot_date_raw",
        "Site Code": "site_code_raw",
        "On Hand": "on_hand_raw",
        "Requested Units": "requested_units_raw",
        "Backordered Units": "backordered_units_raw",
        "sku": "sku",
        "receipts": "receipts_raw",
        "shipments": "shipments_raw",
    }
    df = df_mess.rename(columns=rename).copy()
    df = _ensure_cols(
        df,
        [
            "snapshot_date_raw",
            "site_code_raw",
            "sku",
            "on_hand_raw",
            "receipts_raw",
            "shipments_raw",
            "requested_units_raw",
            "backordered_units_raw",
        ],
    )

    out = pd.DataFrame(
        {
            "snapshot_date_raw": df["snapshot_date_raw"],
            "snapshot_date": df["snapshot_date_raw"].map(_parse_date_any),
            "site_code_raw": df["site_code_raw"],
            "site_code_norm": df["site_code_raw"].map(_norm_code),
            "sku": df["sku"].map(_norm_code),
            "on_hand_raw": df["on_hand_raw"],
            "on_hand": df["on_hand_raw"].map(_to_int_or_none),
            "receipts_raw": df["receipts_raw"],
            "receipts": df["receipts_raw"].map(_to_int_or_none),
            "shipments_raw": df["shipments_raw"],
            "shipments": df["shipments_raw"].map(_to_int_or_none),
            "requested_units_raw": df["requested_units_raw"],
            "requested_units": df["requested_units_raw"].map(_to_int_or_none),
            "backordered_units_raw": df["backordered_units_raw"],
            "backordered_units": df["backordered_units_raw"].map(_to_int_or_none),
        }
    )
    return out


def standardize_wms(df_raw: pd.DataFrame) -> pd.DataFrame:
    df = _ensure_cols(df_raw, ["ship_date", "shipment_id", "site_code", "sku", "units_shipped", "carrier"])
    out = pd.DataFrame(
        {
            "ship_date_raw": df["ship_date"],
            "ship_date": df["ship_date"].map(_parse_date_any),
            "shipment_id_raw": df["shipment_id"],
            "shipment_id_norm": df["shipment_id"].map(lambda x: str(x).strip() if x is not None else None),
            "site_code_raw": df["site_code"],
            "site_code_norm": df["site_code"].map(_norm_code),
            "sku_raw": df["sku"],
            "sku_norm": df["sku"].map(_norm_code),
            "units_shipped_raw": df["units_shipped"],
            "units_shipped": df["units_shipped"].map(_to_int_or_none),
            "carrier_raw": df["carrier"],
            "carrier_norm": df["carrier"].map(lambda x: str(x).strip().upper() if x is not None else None),
        }
    )
    return out


def standardize_timeclock(df_raw: pd.DataFrame) -> pd.DataFrame:
    df = _ensure_cols(df_raw, ["punch_ts", "employee_id", "site_code", "action"])
    out = pd.DataFrame(
        {
            "punch_ts_raw": df["punch_ts"],
            "punch_ts_parsed": df["punch_ts"].map(_parse_ts_any),
            "punch_date": df["punch_ts"].map(_parse_date_any),
            "employee_id_raw": df["employee_id"],
            "employee_id": df["employee_id"].map(_to_int_or_none),
            "site_code_raw": df["site_code"],
            "site_code_norm": df["site_code"].map(_norm_code),
            "action_raw": df["action"],
            "action_norm": df["action"].map(lambda x: str(x).strip().upper() if x is not None else None),
        }
    )
    return out


def standardize_payroll(df_mess: pd.DataFrame) -> pd.DataFrame:
    rename = {
        "Week Ending": "week_ending_raw",
        "Site Code": "site_code_raw",
        "department": "department_raw",
        "team": "team_raw",
        "Hours Worked": "hours_worked_raw",
        "OT Hours": "ot_hours_raw",
        "Employee Count": "employee_count_raw",
        "Labor Cost": "labor_cost_raw",
    }
    df = df_mess.rename(columns=rename).copy()
    df = _ensure_cols(
        df,
        [
            "week_ending_raw",
            "site_code_raw",
            "department_raw",
            "team_raw",
            "hours_worked_raw",
            "ot_hours_raw",
            "employee_count_raw",
            "labor_cost_raw",
        ],
    )

    out = pd.DataFrame(
        {
            "week_ending_raw": df["week_ending_raw"],
            "week_ending": df["week_ending_raw"].map(_parse_date_any),
            "site_code_raw": df["site_code_raw"],
            "site_code_norm": df["site_code_raw"].map(_norm_code),
            "department_raw": df["department_raw"],
            "department_norm": df["department_raw"].map(lambda x: str(x).strip().lower() if x is not None else None),
            "team_raw": df["team_raw"],
            "team_norm": df["team_raw"].map(lambda x: str(x).strip().lower() if x is not None else None),
            "hours_worked_raw": df["hours_worked_raw"],
            "hours_worked": df["hours_worked_raw"].map(_to_float_or_none),
            "ot_hours_raw": df["ot_hours_raw"],
            "ot_hours": df["ot_hours_raw"].map(_to_float_or_none),
            "employee_count_raw": df["employee_count_raw"],
            "employee_count": df["employee_count_raw"].map(_to_int_or_none),
            "labor_cost_raw": df["labor_cost_raw"],
            "labor_cost": df["labor_cost_raw"].map(_to_float_or_none),
        }
    )
    return out


def standardize_finance_actuals(df_mess: pd.DataFrame) -> pd.DataFrame:
    rename = {
        "Month Start": "month_start_raw",
        "Metric Name": "metric_name_raw",
        "Actual Amount": "actual_amount_raw",
        "Currency": "currency_code_raw",
    }
    df = df_mess.rename(columns=rename).copy()
    df = _ensure_cols(df, ["month_start_raw", "metric_name_raw", "actual_amount_raw", "currency_code_raw"])

    out = pd.DataFrame(
        {
            "month_start_raw": df["month_start_raw"],
            "month_start": df["month_start_raw"].map(_parse_date_any),
            "metric_name_raw": df["metric_name_raw"],
            "metric_name_norm": df["metric_name_raw"].map(lambda x: str(x).strip().lower() if x is not None else None),
            "actual_amount_raw": df["actual_amount_raw"],
            "actual_amount": df["actual_amount_raw"].map(_to_float_or_none),
            "currency_code_raw": df["currency_code_raw"],
            "currency_code_norm": df["currency_code_raw"].map(lambda x: str(x).strip().upper() if x is not None else None),
        }
    )
    return out


def standardize_gl(df_raw: pd.DataFrame) -> pd.DataFrame:
    df = _ensure_cols(
        df_raw,
        ["period", "posting_date", "location_code", "account_code", "account_name", "debit_amount", "credit_amount"],
    )
    out = pd.DataFrame(
        {
            "period_raw": df["period"],
            "period_norm": df["period"].map(lambda x: str(x).strip() if x is not None else None),
            "posting_date_raw": df["posting_date"],
            "posting_date": df["posting_date"].map(_parse_date_any),
            "location_code_raw": df["location_code"],
            "location_code_norm": df["location_code"].map(_norm_code),
            "account_code_raw": df["account_code"],
            "account_code_norm": df["account_code"].map(lambda x: str(x).strip().replace("-", "") if x is not None else None),
            "account_name_raw": df["account_name"],
            "account_name_norm": df["account_name"].map(lambda x: str(x).strip().lower() if x is not None else None),
            "debit_amount_raw": df["debit_amount"],
            "debit_amount": df["debit_amount"].map(_to_float_or_none),
            "credit_amount_raw": df["credit_amount"],
            "credit_amount": df["credit_amount"].map(_to_float_or_none),
        }
    )
    return out

def standardize_account_status(df_mess: pd.DataFrame) -> pd.DataFrame:
    # accept either header-drifted columns OR non-drifted (more robust)
    rename = {
        "Status Date": "status_date_raw",
        "status_date": "status_date_raw",
        "Store Code": "store_code_raw",
        "store_code": "store_code_raw",
        "Account Status": "account_status_raw",
        "account_status": "account_status_raw",
        "Status Reason": "status_reason_raw",
        "status_reason": "status_reason_raw",
    }
    df = df_mess.rename(columns=rename).copy()
    df = _ensure_cols(df, ["status_date_raw", "store_code_raw", "account_status_raw", "status_reason_raw"])

    def _norm_status(x: Any) -> Optional[str]:
        if x is None:
            return None
        s = str(x).strip().lower()
        if s == "" or s in ("nan", "none"):
            return None

        # IMPORTANT: check inactive before active
        if "inactive" in s:
            return "inactive"
        if "suspend" in s:
            return "suspended"
        if "pending" in s:
            return "pending"
        if "active" in s:
            return "active"
        return s

    out = pd.DataFrame(
        {
            "status_date_raw": df["status_date_raw"],
            "status_date": df["status_date_raw"].map(_parse_date_any),

            "store_code_raw": df["store_code_raw"],
            "store_code_norm": df["store_code_raw"].map(_norm_code),

            "account_status_raw": df["account_status_raw"],
            "account_status_norm": df["account_status_raw"].map(_norm_status),

            "status_reason_raw": df["status_reason_raw"],
            "status_reason_norm": df["status_reason_raw"].map(lambda x: str(x).strip().lower() if x is not None else None),
        }
    )
    return out

def standardize_dispensary_master(df_mess: pd.DataFrame) -> pd.DataFrame:
    rename = {
        "As Of Date": "as_of_date_raw",
        "Dispensary ID": "dispensary_id_raw",
        "Store Code": "store_code_raw",
        "Dispensary Name": "dispensary_name_raw",
        "State": "state_raw",
        "City": "city_raw",
        "Postal Code": "postal_code_raw",
        "License ID": "license_id_raw",
        "Account Type": "account_type_raw",
    }
    df = df_mess.rename(columns=rename).copy()
    df = _ensure_cols(
        df,
        [
            "as_of_date_raw",
            "dispensary_id_raw",
            "store_code_raw",
            "dispensary_name_raw",
            "state_raw",
            "city_raw",
            "postal_code_raw",
            "license_id_raw",
            "account_type_raw",
        ],
    )

    def _norm_postal(x: Any) -> Optional[str]:
        if x is None:
            return None
        s = str(x).strip()
        if s == "" or s.lower() in ("nan", "none"):
            return None
        s = re.sub(r"\s+", "", s)
        return s

    def _norm_state(x: Any) -> Optional[str]:
        if x is None:
            return None
        s = str(x).strip().upper()
        if s == "" or s.lower() in ("nan", "none"):
            return None
        return s[:2]

    out = pd.DataFrame(
        {
            "as_of_date_raw": df["as_of_date_raw"],
            "as_of_date": df["as_of_date_raw"].map(_parse_date_any),

            "dispensary_id_raw": df["dispensary_id_raw"],
            "dispensary_id_norm": df["dispensary_id_raw"].map(_norm_code),

            "store_code_raw": df["store_code_raw"],
            "store_code_norm": df["store_code_raw"].map(_norm_code),

            "dispensary_name_raw": df["dispensary_name_raw"],
            "dispensary_name_norm": df["dispensary_name_raw"].map(lambda x: str(x).strip() if x is not None else None),

            "state_raw": df["state_raw"],
            "state_norm": df["state_raw"].map(_norm_state),

            "city_raw": df["city_raw"],
            "city_norm": df["city_raw"].map(lambda x: str(x).strip().lower() if x is not None else None),

            "postal_code_raw": df["postal_code_raw"],
            "postal_code_norm": df["postal_code_raw"].map(_norm_postal),

            "license_id_raw": df["license_id_raw"],
            "license_id_norm": df["license_id_raw"].map(lambda x: str(x).strip().upper() if x is not None else None),

            "account_type_raw": df["account_type_raw"],
            "account_type_norm": df["account_type_raw"].map(lambda x: str(x).strip().lower() if x is not None else None),
        }
    )
    return out

def add_ingestion_metadata(df: pd.DataFrame, *, load_id: str, source_system: str, cadence: str, drop_date: pd.Timestamp) -> pd.DataFrame:
    out = df.copy()
    out["load_id"] = load_id
    out["source_system"] = source_system
    out["cadence"] = cadence
    out["drop_date"] = drop_date.date().isoformat()
    out["ingested_at"] = pd.Timestamp.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    return out


def df_for_copy(df: pd.DataFrame) -> pd.DataFrame:
    # COPY-friendly: NaN -> None, keep strings as-is
    out = df.copy()
    out = out.where(pd.notnull(out), None)
    return out


# -----------------------------
# Explicit Postgres schemas (stable types)
# -----------------------------

DDL_TABLES: dict[str, list[str]] = {
    "project1_sales_distributor": [
        "sale_date_raw text",
        "sale_date date",
        "store_id_raw text",
        "store_id_norm text",
        "sku text",
        "product_name_raw text",
        "product_name_norm text",
        "channel_raw text",
        "channel_norm text",
        "qty_raw text",
        "qty integer",
        "unit_list_price_raw text",
        "unit_list_price double precision",
        "discount_rate_raw text",
        "discount_rate double precision",
        "unit_net_price_raw text",
        "unit_net_price double precision",
        "gross_sales_raw text",
        "gross_sales double precision",
        "discount_amount_raw text",
        "discount_amount double precision",
        "net_sales_raw text",
        "net_sales double precision",
        "cogs_raw text",
        "cogs double precision",
        "orders_raw text",
        "orders integer",
        "customers_raw text",
        "customers integer",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
    "project1_pos_transactions": [
        "txn_id bigint",
        "txn_ts_raw text",
        "txn_ts_parsed timestamp",
        "txn_date date",
        "store_code_raw text",
        "store_code_norm text",
        "product_sku_raw text",
        "product_sku_norm text",
        "qty_raw text",
        "qty integer",
        "unit_price_raw text",
        "unit_price double precision",
        "discount_pct_raw text",
        "discount_pct double precision",
        "gross_amount_raw text",
        "gross_amount double precision",
        "net_amount_raw text",
        "net_amount double precision",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
    "project1_inventory_snapshot": [
        "snapshot_date_raw text",
        "snapshot_date date",
        "site_code_raw text",
        "site_code_norm text",
        "sku text",
        "on_hand_raw text",
        "on_hand integer",
        "receipts_raw text",
        "receipts integer",
        "shipments_raw text",
        "shipments integer",
        "requested_units_raw text",
        "requested_units integer",
        "backordered_units_raw text",
        "backordered_units integer",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
    "project1_wms_shipments": [
        "ship_date_raw text",
        "ship_date date",
        "shipment_id_raw text",
        "shipment_id_norm text",
        "site_code_raw text",
        "site_code_norm text",
        "sku_raw text",
        "sku_norm text",
        "units_shipped_raw text",
        "units_shipped integer",
        "carrier_raw text",
        "carrier_norm text",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
    "project1_timeclock_punches": [
        "punch_ts_raw text",
        "punch_ts_parsed timestamp",
        "punch_date date",
        "employee_id_raw text",
        "employee_id integer",
        "site_code_raw text",
        "site_code_norm text",
        "action_raw text",
        "action_norm text",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
    "project1_payroll_weekly": [
        "week_ending_raw text",
        "week_ending date",
        "site_code_raw text",
        "site_code_norm text",
        "department_raw text",
        "department_norm text",
        "team_raw text",
        "team_norm text",
        "hours_worked_raw text",
        "hours_worked double precision",
        "ot_hours_raw text",
        "ot_hours double precision",
        "employee_count_raw text",
        "employee_count integer",
        "labor_cost_raw text",
        "labor_cost double precision",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
    "project1_finance_actuals": [
        "month_start_raw text",
        "month_start date",
        "metric_name_raw text",
        "metric_name_norm text",
        "actual_amount_raw text",
        "actual_amount double precision",
        "currency_code_raw text",
        "currency_code_norm text",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
    "project1_gl_detail": [
        "period_raw text",
        "period_norm text",
        "posting_date_raw text",
        "posting_date date",
        "location_code_raw text",
        "location_code_norm text",
        "account_code_raw text",
        "account_code_norm text",
        "account_name_raw text",
        "account_name_norm text",
        "debit_amount_raw text",
        "debit_amount double precision",
        "credit_amount_raw text",
        "credit_amount double precision",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
        "project1_account_status": [
        "status_date_raw text",
        "status_date date",
        "store_code_raw text",
        "store_code_norm text",
        "account_status_raw text",
        "account_status_norm text",
        "status_reason_raw text",
        "status_reason_norm text",
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
        "project1_dispensary_master": [
        # snapshot date (optional but consistent)
        "as_of_date_raw text",
        "as_of_date date",

        # keys
        "dispensary_id_raw text",
        "dispensary_id_norm text",
        "store_code_raw text",
        "store_code_norm text",

        # identity
        "dispensary_name_raw text",
        "dispensary_name_norm text",

        # location
        "state_raw text",
        "state_norm text",
        "city_raw text",
        "city_norm text",
        "postal_code_raw text",
        "postal_code_norm text",

        # optional business attrs
        "license_id_raw text",
        "license_id_norm text",
        "account_type_raw text",
        "account_type_norm text",

        # ingestion metadata
        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
        "project1_sku_distribution_status": [
        "as_of_date_raw text",
        "as_of_date date",

        "store_code_raw text",
        "store_code_norm text",

        "sku_raw text",
        "sku_norm text",

        "distribution_status_raw text",
        "distribution_status_norm text",

        "status_reason_raw text",
        "status_reason_norm text",

        "load_id text",
        "source_system text",
        "cadence text",
        "drop_date date",
        "ingested_at timestamp",
    ],
}


def pg_prepare_tables(con, schema: str, tables: list[str]) -> None:
    pg_ensure_schema(con, schema)
    for t in tables:
        if t not in DDL_TABLES:
            raise SystemExit(f"Internal error: missing DDL for table: {t}")
        pg_ensure_table(con, schema, t, DDL_TABLES[t])


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

    ap.add_argument("--base", default="01_ops_command_center", help="Write outputs under this subfolder (use . for repo root)")

    ap.add_argument("--pg-dsn", default=os.getenv("PROJECT1_PG_DSN", ""), help="Postgres DSN (or set env PROJECT1_PG_DSN)")
    ap.add_argument("--pg-schema", default=os.getenv("PROJECT1_PG_SCHEMA", "raw"), help="Target schema (default: raw)")

    ap.add_argument(
        "--pg-ddl-mode",
        choices=["keep", "drop_and_create"],
        default=os.getenv("PROJECT1_PG_DDL_MODE", "keep"),
        help="Whether to keep existing raw tables or drop+recreate them to match the stable DDL",
    )

    ap.add_argument(
        "--pg-load-mode",
        choices=["append", "truncate_then_append"],
        default=os.getenv("PROJECT1_PG_LOAD_MODE", "append"),
        help="How to load each run into the target tables",
    )

    # Default raw table names (aligned to your existing raw schema naming)
    ap.add_argument("--t-account-status", default=os.getenv("PROJECT1_T_ACCOUNT_STATUS", "account_status"), help="Raw account status table name (default: account_status)",)
    ap.add_argument("--t-dispensary-master", default=os.getenv("PROJECT1_T_DISPENSARY_MASTER", "dispensary_master"))
    ap.add_argument("--t-sales-distributor", default=os.getenv("PROJECT1_T_SALES_DISTRIBUTOR", "sales_distributor_extract"))
    ap.add_argument("--t-pos",              default=os.getenv("PROJECT1_T_POS",              "pos_transactions_csv"))
    ap.add_argument("--t-inventory",        default=os.getenv("PROJECT1_T_INVENTORY",        "inventory_erp_snapshot"))
    ap.add_argument("--t-wms",              default=os.getenv("PROJECT1_T_WMS",              "wms_shipments"))
    ap.add_argument("--t-timeclock",        default=os.getenv("PROJECT1_T_TIMECLOCK",        "timeclock_punches"))
    ap.add_argument("--t-payroll",          default=os.getenv("PROJECT1_T_PAYROLL",          "labor_hours_payroll_export"))
    ap.add_argument("--t-finance-actuals",  default=os.getenv("PROJECT1_T_FIN_ACTUALS",      "finance_actuals_summary"))
    ap.add_argument("--t-gl",               default=os.getenv("PROJECT1_T_GL",               "gl_detail_csv"))
    ap.add_argument("--t-sku-distribution-status", default=os.getenv("PROJECT1_T_SKU_DISTRIBUTION_STATUS", "sku_distribution_status"),help="Raw SKU distribution status table name",)

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

    # Postgres
    con = pg_connect(args.pg_dsn)

    # Map chosen table names to canonical DDL definitions:
    # We’ll create the *named* tables using the canonical DDL list by temporarily binding names.
    # To keep it simple: require users to keep defaults OR accept that custom names use same DDL.
    selected_tables = [
        args.t_sales_distributor,
        args.t_pos,
        args.t_inventory,
        args.t_wms,
        args.t_timeclock,
        args.t_payroll,
        args.t_finance_actuals,
        args.t_gl,
        args.t_account_status,
        args.t_dispensary_master,
        args.t_sku_distribution_status,
    ]

    # Build DDL on the fly for custom table names by copying canonical DDL
    # (We key DDL_TABLES by canonical names; here we just ensure each selected table exists.)
    pg_ensure_schema(con, args.pg_schema)
    canonical_map = {
        args.t_sales_distributor: "project1_sales_distributor",
        args.t_pos: "project1_pos_transactions",
        args.t_inventory: "project1_inventory_snapshot",
        args.t_wms: "project1_wms_shipments",
        args.t_timeclock: "project1_timeclock_punches",
        args.t_payroll: "project1_payroll_weekly",
        args.t_finance_actuals: "project1_finance_actuals",
        args.t_gl: "project1_gl_detail",
        args.t_account_status: "project1_account_status",
        args.t_dispensary_master: "project1_dispensary_master",
        args.t_sku_distribution_status: "project1_sku_distribution_status",
            }
    for actual_name, canonical in canonical_map.items():
        if args.pg_ddl_mode == "drop_and_create":
            pg_drop_table(con, args.pg_schema, actual_name)
        pg_ensure_table(con, args.pg_schema, actual_name, DDL_TABLES[canonical])

    if args.pg_load_mode == "truncate_then_append":
        for t in selected_tables:
            if pg_table_exists(con, args.pg_schema, t):
                pg_truncate(con, args.pg_schema, t)

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

    # -------------------------
    # DAILY
    # -------------------------
    for d in day_range:
        # sales: distributor CSV
        dist_mess = gen_sales_distributor_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "sales", "distributor", d)
        p_cur = current_dir(root, "sales", "distributor")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "sales_distributor_extract.csv"
        f_cur = p_cur / "sales_distributor_extract.csv"
        dist_mess.to_csv(f_in, index=False)
        dist_mess.to_csv(f_cur, index=False)
        log(
            domain="sales",
            system="distributor",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(dist_mess),
            notes="messy headers + duplicates + missing Store ID + channel casing/whitespace + date format mix",
        )

        # sales: distributor -> Postgres raw
        dist_std = standardize_sales_distributor(dist_mess)
        dist_std = add_ingestion_metadata(dist_std, load_id=load_id, source_system="sales_distributor", cadence="daily", drop_date=d)
        dist_std = df_for_copy(dist_std)
        pg_copy_append(con, args.pg_schema, args.t_sales_distributor, dist_std)
        log(
            domain="sales",
            system="distributor",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(dist_std),
            notes="loaded standardized + normalized keys into postgres",
            target=f"{args.pg_schema}.{args.t_sales_distributor}",
        )

        # reference: account status CSV + Postgres raw
        acct_mess = gen_account_status_day(cfg, rng, d, stores)

        p_in = incoming_dir(root, "reference", "crm", d)
        p_cur = current_dir(root, "reference", "crm")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "account_status.csv"
        f_cur = p_cur / "account_status.csv"
        acct_mess.to_csv(f_in, index=False)
        acct_mess.to_csv(f_cur, index=False)

        log(
            domain="reference",
            system="crm",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(acct_mess),
            notes="account status master; casing/whitespace drift; occasional missing store_code; mixed date formats",
        )

        acct_std = standardize_account_status(acct_mess)
        acct_std = add_ingestion_metadata(acct_std, load_id=load_id, source_system="reference_account_status", cadence="daily", drop_date=d)
        acct_std = df_for_copy(acct_std)

        pg_copy_append(con, args.pg_schema, args.t_account_status, acct_std)

        log(
            domain="reference",
            system="crm",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(acct_std),
            notes="loaded standardized account_status into postgres",
            target=f"{args.pg_schema}.{args.t_account_status}",
        )

        # reference: dispensary master CSV + Postgres raw
        disp_mess = gen_dispensary_master_day(cfg, rng, d, stores)

        p_in = incoming_dir(root, "reference", "dispensary_master", d)
        p_cur = current_dir(root, "reference", "dispensary_master")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "dispensary_master.csv"
        f_cur = p_cur / "dispensary_master.csv"
        disp_mess.to_csv(f_in, index=False)
        disp_mess.to_csv(f_cur, index=False)

        log(
            domain="reference",
            system="dispensary_master",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(disp_mess),
            notes="dispensary master snapshot; messy casing/whitespace; occasional missing keys",
        )

        disp_std = standardize_dispensary_master(disp_mess)
        disp_std = add_ingestion_metadata(
            disp_std,
            load_id=load_id,
            source_system="reference_dispensary_master",
            cadence="daily",
            drop_date=d,
        )
        disp_std = df_for_copy(disp_std)

        pg_copy_append(con, args.pg_schema, args.t_dispensary_master, disp_std)

        log(
            domain="reference",
            system="dispensary_master",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(disp_std),
            notes="loaded standardized dispensary_master into postgres",
            target=f"{args.pg_schema}.{args.t_dispensary_master}",
        )
        # --- DAILY: sku distribution status (CSV + Postgres raw) ---
        sku_dist_mess = gen_sku_distribution_status_day(cfg, rng, d, stores)

        # write messy file drops
        p_in = incoming_dir(root, "reference", "assortment", d)
        p_cur = current_dir(root, "reference", "assortment")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "sku_distribution_status.csv"
        f_cur = p_cur / "sku_distribution_status.csv"
        sku_dist_mess.to_csv(f_in, index=False)
        sku_dist_mess.to_csv(f_cur, index=False)

        log(
            domain="reference",
            system="assortment",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(sku_dist_mess),
            notes="sku distribution status snapshot; casing/whitespace drift; occasional missing store_code/sku; mixed date formats",
        )

        # standardize + load to Postgres raw
        sku_dist_std = standardize_sku_distribution_status(sku_dist_mess)
        sku_dist_std = add_ingestion_metadata(
            sku_dist_std,
            load_id=load_id,
            source_system="reference_sku_distribution_status",
            cadence="daily",
            drop_date=d,
        )
        sku_dist_std = df_for_copy(sku_dist_std)

        pg_copy_append(con, args.pg_schema, args.t_sku_distribution_status, sku_dist_std)

        log(
            domain="reference",
            system="assortment",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(sku_dist_std),
            notes="loaded standardized sku_distribution_status into postgres",
            target=f"{args.pg_schema}.{args.t_sku_distribution_status}",
        )
        # sales: pos CSV
        pos_raw = gen_pos_transactions_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "sales", "pos", d)
        p_cur = current_dir(root, "sales", "pos")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "pos_transactions.csv"
        f_cur = p_cur / "pos_transactions.csv"
        pos_raw.to_csv(f_in, index=False)
        pos_raw.to_csv(f_cur, index=False)
        log(
            domain="sales",
            system="pos",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(pos_raw),
            notes="row-level POS; some bad datetime formats; missing store_code possible",
        )

        # sales: pos -> Postgres raw
        pos_std = standardize_pos(pos_raw)
        pos_std = add_ingestion_metadata(pos_std, load_id=load_id, source_system="sales_pos", cadence="daily", drop_date=d)
        pos_std = df_for_copy(pos_std)
        pg_copy_append(con, args.pg_schema, args.t_pos, pos_std)
        log(
            domain="sales",
            system="pos",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(pos_std),
            notes="loaded standardized + parsed timestamps + normalized keys into postgres",
            target=f"{args.pg_schema}.{args.t_pos}",
        )

        # ops: inventory snapshot CSV
        inv_mess = gen_inventory_snapshot_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "ops", "erp", d)
        p_cur = current_dir(root, "ops", "erp")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "inventory_erp_snapshot.csv"
        f_cur = p_cur / "inventory_erp_snapshot.csv"
        inv_mess.to_csv(f_in, index=False)
        inv_mess.to_csv(f_cur, index=False)
        log(
            domain="ops",
            system="erp",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(inv_mess),
            notes="negative On Hand exceptions; site code drift (lowercase + hyphen)",
        )

        # ops: inventory -> Postgres raw
        inv_std = standardize_inventory_snapshot(inv_mess)
        inv_std = add_ingestion_metadata(inv_std, load_id=load_id, source_system="ops_erp_inventory", cadence="daily", drop_date=d)
        inv_std = df_for_copy(inv_std)
        pg_copy_append(con, args.pg_schema, args.t_inventory, inv_std)
        log(
            domain="ops",
            system="erp",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(inv_std),
            notes="loaded standardized + normalized keys into postgres",
            target=f"{args.pg_schema}.{args.t_inventory}",
        )

        # ops: wms shipments CSV
        wms_raw = gen_wms_shipments_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "ops", "wms", d)
        p_cur = current_dir(root, "ops", "wms")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "wms_shipments.csv"
        f_cur = p_cur / "wms_shipments.csv"
        wms_raw.to_csv(f_in, index=False)
        wms_raw.to_csv(f_cur, index=False)
        log(
            domain="ops",
            system="wms",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(wms_raw),
            notes="duplicates; occasional missing sku",
        )

        # ops: wms -> Postgres raw
        wms_std = standardize_wms(wms_raw)
        wms_std = add_ingestion_metadata(wms_std, load_id=load_id, source_system="ops_wms_shipments", cadence="daily", drop_date=d)
        wms_std = df_for_copy(wms_std)
        pg_copy_append(con, args.pg_schema, args.t_wms, wms_std)
        log(
            domain="ops",
            system="wms",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(wms_std),
            notes="loaded standardized + normalized keys into postgres",
            target=f"{args.pg_schema}.{args.t_wms}",
        )

        # people: timeclock CSV
        tc_raw = gen_timeclock_day(cfg, rng, d, stores)
        p_in = incoming_dir(root, "people", "timeclock", d)
        p_cur = current_dir(root, "people", "timeclock")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "timeclock_punches.csv"
        f_cur = p_cur / "timeclock_punches.csv"
        tc_raw.to_csv(f_in, index=False)
        tc_raw.to_csv(f_cur, index=False)
        log(
            domain="people",
            system="timeclock",
            cadence="daily",
            drop_date=d,
            file_path=f_in,
            file_type="csv",
            rows=len(tc_raw),
            notes="missing OUT punches; mixed timestamp formats",
        )

        # people: timeclock -> Postgres raw
        tc_std = standardize_timeclock(tc_raw)
        tc_std = add_ingestion_metadata(tc_std, load_id=load_id, source_system="people_timeclock", cadence="daily", drop_date=d)
        tc_std = df_for_copy(tc_std)
        pg_copy_append(con, args.pg_schema, args.t_timeclock, tc_std)
        log(
            domain="people",
            system="timeclock",
            cadence="daily",
            drop_date=d,
            file_path=None,
            file_type="postgres",
            rows=len(tc_std),
            notes="loaded standardized + parsed timestamps + normalized keys into postgres",
            target=f"{args.pg_schema}.{args.t_timeclock}",
        )

    # -------------------------
    # WEEKLY
    # -------------------------
    for we in week_range:
        payroll_mess = gen_payroll_week(cfg, rng, we, stores)
        p_in = incoming_dir(root, "people", "payroll", we)
        p_cur = current_dir(root, "people", "payroll")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "labor_hours_payroll_export.xlsx"
        f_cur = p_cur / "labor_hours_payroll_export.xlsx"
        with pd.ExcelWriter(f_in, engine="openpyxl") as w:
            payroll_mess.to_excel(w, index=False, sheet_name="payroll")
        with pd.ExcelWriter(f_cur, engine="openpyxl") as w:
            payroll_mess.to_excel(w, index=False, sheet_name="payroll")
        log(
            domain="people",
            system="payroll",
            cadence="weekly",
            drop_date=we,
            file_path=f_in,
            file_type="xlsx",
            rows=len(payroll_mess),
            notes="team spelling variation; zero-hour rows with cost",
        )

        # payroll -> Postgres raw
        payroll_std = standardize_payroll(payroll_mess)
        payroll_std = add_ingestion_metadata(payroll_std, load_id=load_id, source_system="people_payroll", cadence="weekly", drop_date=we)
        payroll_std = df_for_copy(payroll_std)
        pg_copy_append(con, args.pg_schema, args.t_payroll, payroll_std)
        log(
            domain="people",
            system="payroll",
            cadence="weekly",
            drop_date=we,
            file_path=None,
            file_type="postgres",
            rows=len(payroll_std),
            notes="loaded standardized + normalized keys into postgres",
            target=f"{args.pg_schema}.{args.t_payroll}",
        )

    # -------------------------
    # MONTHLY
    # -------------------------
    for ms in month_range:
        # finance actuals xlsx
        # fin_mess = gen_finance_actuals_month(cfg, rng, ms)

        # use truth data instead of generating new data
        fin_mess = gen_finance_actuals_month_from_truth(
            rng=rng,
            month_start=ms,
            sales_monthly=sales_monthly,
            labor_monthly=labor_monthly,
        )
        p_in = incoming_dir(root, "finance", "erp_finance", ms)
        p_cur = current_dir(root, "finance", "erp_finance")
        p_in.mkdir(parents=True, exist_ok=True)
        p_cur.mkdir(parents=True, exist_ok=True)

        f_in = p_in / "finance_actuals_summary.xlsx"
        f_cur = p_cur / "finance_actuals_summary.xlsx"
        with pd.ExcelWriter(f_in, engine="openpyxl") as w:
            fin_mess.to_excel(w, index=False, sheet_name="actuals")
        with pd.ExcelWriter(f_cur, engine="openpyxl") as w:
            fin_mess.to_excel(w, index=False, sheet_name="actuals")
        log(
            domain="finance",
            system="erp_finance",
            cadence="monthly",
            drop_date=ms,
            file_path=f_in,
            file_type="xlsx",
            rows=len(fin_mess),
            notes="metric label variance; small drift",
        )

        # finance actuals -> Postgres raw
        fin_std = standardize_finance_actuals(fin_mess)
        fin_std = add_ingestion_metadata(fin_std, load_id=load_id, source_system="finance_actuals", cadence="monthly", drop_date=ms)
        fin_std = df_for_copy(fin_std)
        pg_copy_append(con, args.pg_schema, args.t_finance_actuals, fin_std)
        log(
            domain="finance",
            system="erp_finance",
            cadence="monthly",
            drop_date=ms,
            file_path=None,
            file_type="postgres",
            rows=len(fin_std),
            notes="loaded standardized into postgres",
            target=f"{args.pg_schema}.{args.t_finance_actuals}",
        )

        # finance gl -> Postgres raw (still a DB “export” conceptually)
        gl_raw = gen_gl_detail_month(cfg, rng, ms, stores)
        gl_std = standardize_gl(gl_raw)
        gl_std = add_ingestion_metadata(gl_std, load_id=load_id, source_system="finance_gl", cadence="monthly", drop_date=ms)
        gl_std = df_for_copy(gl_std)
        pg_copy_append(con, args.pg_schema, args.t_gl, gl_std)
        log(
            domain="finance",
            system="gl",
            cadence="monthly",
            drop_date=ms,
            file_path=None,
            file_type="postgres",
            rows=len(gl_std),
            notes="loaded standardized + normalized keys into postgres",
            target=f"{args.pg_schema}.{args.t_gl}",
        )

    con.close()

    manifest = pd.DataFrame(manifest_rows)
    out_manifest = root / "docs" / "source_drop_manifest.csv"
    manifest.to_csv(out_manifest, index=False)

    print("\n✅ Source drops generated + loaded to Postgres (ALL sources).")
    print("Backend: postgres-only")
    print(f"Schema: {args.pg_schema}")
    print("Tables:")
    for t in selected_tables:
        print(f"  - {args.pg_schema}.{t}")
    print(f"Manifest: {out_manifest}")
    print(f"Rows in manifest: {len(manifest):,}")
    print(f"Load ID: {load_id}\n")


if __name__ == "__main__":
    main()