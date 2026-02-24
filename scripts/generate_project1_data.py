#!/usr/bin/env python3
# Please install openpyxl before running this script

from __future__ import annotations

import argparse
from dataclasses import dataclass, asdict
from pathlib import Path
import numpy as np
import pandas as pd
import openpyxl

@dataclass
class Config:
    start_date: str = "2025-01-01"
    end_date: str = "2025-12-31"
    seed: int = 42
    n_products: int = 15
    n_locations: int = 2345

# Ensure all directories exist
def ensure_dirs(base: Path):
    p1 = base / "01_ops_command_center"
    paths = {
        "modeled": p1 / "data" / "modeled",
        "sales_src": p1 / "data" / "source_extracts" / "sales",
        "ops_src": p1 / "data" / "source_extracts" / "ops",
        "people_src": p1 / "data" / "source_extracts" / "people",
        "finance_src": p1 / "data" / "source_extracts" / "finance",
        "sample": p1 / "data" / "sample",
        "docs": p1 / "docs",
    }
    for p in paths.values():
        p.mkdir(parents=True, exist_ok=True)
    return paths

# Return seasonality factor for given month
def month_seasonality(month: int) -> float:
    return {
        1: 0.93, 2: 0.95, 3: 0.98, 4: 1.00, 5: 1.03, 6: 1.06,
        7: 1.08, 8: 1.07, 9: 1.02, 10: 1.01, 11: 1.10, 12: 1.14
    }[month]

# Return weekday factor for given weekday and channel
def weekday_factor(weekday: int, channel_name: str) -> float:
    if channel_name.lower() == "retail":
        return [0.95, 0.98, 1.00, 1.02, 1.08, 1.15, 1.12][weekday]
    if channel_name.lower() == "wholesale":
        return [1.10, 1.10, 1.08, 1.05, 0.95, 0.60, 0.45][weekday]
    return [0.98, 1.00, 1.02, 1.03, 1.05, 1.08, 1.07][weekday]

# Sigmoid function = 1 / (1 + e^(-x)) = 0.5 when x = 0
def sigmoid(x):
    return 1 / (1 + np.exp(-x))

# Write DataFrame to CSV file
def write_csv(df, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)

# Write DataFrame to XLSX file
def write_xlsx(df, path, sheet_name="sales_data"):
    path.parent.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(path, engine="openpyxl") as writer:
        df.to_excel(writer, index=False, sheet_name=sheet_name)

# Generate 'dates' dim table
def generate_dim_date(cfg):
    d = pd.date_range(cfg.start_date, cfg.end_date, freq="D")
    df = pd.DataFrame({"full_date": d})
    df["date_key"] = df["full_date"].dt.strftime("%Y%m%d").astype(int)
    df["year_num"] = df["full_date"].dt.year
    df["quarter_num"] = df["full_date"].dt.quarter
    df["month_num"] = df["full_date"].dt.month
    df["month_name"] = df["full_date"].dt.strftime("%b")
    df["week_num"] = df["full_date"].dt.isocalendar().week.astype(int)
    df["weekday_num"] = df["full_date"].dt.weekday + 1
    df["weekday_name"] = df["full_date"].dt.strftime("%a")
    df["month_start_date"] = df["full_date"].values.astype("datetime64[M]")
    df["is_weekend"] = df["full_date"].dt.weekday.isin([5, 6]).astype(int)
    return df

# Generate 'products' dim table
WYLD_PRODUCTS = [
    {
        "ratio_label": "1:1 THC:CBC",
        "product_line": "Bliss",
        "product_name": "Wyld Blood Orange 1:1 THC:CBC Gummies",
        "flavor_name": "Blood Orange",
        "effect_type": "Sativa Enhanced",
        "benefit_line": "Bliss",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.00,
        "base_cogs_ratio": 0.45,
        "demand_weight": 1.02,
    },
    {
        "ratio_label": "1:1:1 THC:CBD:CBN",
        "product_line": "Dream",
        "product_name": "Wyld Boysenberry 1:1:1 THC:CBD:CBN Gummies",
        "flavor_name": "Boysenberry",
        "effect_type": "Indica Enhanced",
        "benefit_line": "Dream",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.00,
        "base_cogs_ratio": 0.47,
        "demand_weight": 1.08,
    },
    {
        "ratio_label": "2:1 THC:CBN",
        "product_line": "Sleep",
        "product_name": "Wyld Elderberry 2:1 THC:CBN Gummies",
        "flavor_name": "Elderberry",
        "effect_type": "Indica Enhanced",
        "benefit_line": "Sleep",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.46,
        "demand_weight": 1.12,
    },
    {
        "ratio_label": "1:1:1 THC:CBG:CBC",
        "product_line": "Revive",
        "product_name": "Wyld Grapefruit 1:1:1 THC:CBG:CBC Gummies",
        "flavor_name": "Grapefruit",
        "effect_type": "Sativa Enhanced",
        "benefit_line": "Revive",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.48,
        "demand_weight": 0.95,
    },
    {
        "ratio_label": "THC",
        "product_line": "Playful",
        "product_name": "Wyld Huckleberry THC Gummies",
        "flavor_name": "Huckleberry",
        "effect_type": "Hybrid Enhanced",
        "benefit_line": "Playful",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.00,
        "base_cogs_ratio": 0.42,
        "demand_weight": 1.18,
    },
    {
        "ratio_label": "1:1 THC:THCv",
        "product_line": "Energy",
        "product_name": "Wyld Kiwi 1:1 THC:THCv Gummies",
        "flavor_name": "Kiwi",
        "effect_type": "Sativa Enhanced",
        "benefit_line": "Energy",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.49,
        "demand_weight": 0.93,
    },
    {
        "ratio_label": "THC",
        "product_line": "Mellow",
        "product_name": "Wyld Marionberry THC Gummies",
        "flavor_name": "Marionberry",
        "effect_type": "Indica Enhanced",
        "benefit_line": "Mellow",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.00,
        "base_cogs_ratio": 0.42,
        "demand_weight": 1.15,
    },
    {
        "ratio_label": "2:1 CBD:THC",
        "product_line": "Chill",
        "product_name": "Wyld Peach 2:1 CBD:THC Gummies",
        "flavor_name": "Peach",
        "effect_type": "Hybrid Enhanced",
        "benefit_line": "Chill",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.46,
        "demand_weight": 1.04,
    },
    {
        "ratio_label": "1:1 THC:CBG",
        "product_line": "Refresh",
        "product_name": "Wyld Pear 1:1 THC:CBG Gummies",
        "flavor_name": "Pear",
        "effect_type": "Hybrid Enhanced",
        "benefit_line": "Refresh",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.47,
        "demand_weight": 0.97,
    },
    {
        "ratio_label": "1:1 THC:CBD",
        "product_line": "Restore",
        "product_name": "Wyld Pomegranate 1:1 THC:CBD Gummies",
        "flavor_name": "Pomegranate",
        "effect_type": "Hybrid Enhanced",
        "benefit_line": "Restore",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.46,
        "demand_weight": 1.06,
    },
    {
        "ratio_label": "THC",
        "product_line": "Active",
        "product_name": "Wyld Raspberry THC Gummies",
        "flavor_name": "Raspberry",
        "effect_type": "Sativa Enhanced",
        "benefit_line": "Active",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.42,
        "demand_weight": 1.10,
    },
    {
        "ratio_label": "THC",
        "product_line": "Active",
        "product_name": "Wyld Sour Apple THC Gummies",
        "flavor_name": "Sour Apple",
        "effect_type": "Sativa Enhanced",
        "benefit_line": "Active",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.42,
        "demand_weight": 1.09,
    },
    {
        "ratio_label": "THC",
        "product_line": "Mellow",
        "product_name": "Wyld Sour Cherry THC Gummies",
        "flavor_name": "Sour Cherry",
        "effect_type": "Indica Enhanced",
        "benefit_line": "Mellow",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.42,
        "demand_weight": 1.11,
    },
    {
        "ratio_label": "THC",
        "product_line": "Playful",
        "product_name": "Wyld Sour Tangerine THC Gummies",
        "flavor_name": "Sour Tangerine",
        "effect_type": "Hybrid Enhanced",
        "benefit_line": "Playful",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.43,
        "demand_weight": 1.14,
    },
    {
        "ratio_label": "20:1 CBD:THC",
        "product_line": "Calm",
        "product_name": "Wyld Strawberry 20:1 CBD:THC Gummies",
        "flavor_name": "Strawberry",
        "effect_type": "Hybrid Enhanced",
        "benefit_line": "Calm",
        "category_name": "Gummies",
        "pack_size": 10,
        "potency_mg_total": 100,
        "base_list_price": 10.50,
        "base_cogs_ratio": 0.47,
        "demand_weight": 0.98,
    },
]

# Generate 'products' dim table
def generate_dim_product(cfg, rng):
    rows = []

    for product_key, prod in enumerate(WYLD_PRODUCTS, start=1):
        # small realistic noise so repeated runs aren't perfectly rigid (but seed-controlled)
        price = float(prod["base_list_price"]) * float(rng.normal(1.0, 0.02))
        cogs_ratio = float(np.clip(prod["base_cogs_ratio"] + rng.normal(0.0, 0.008), 0.30, 0.70))

        rows.append({
            "product_key": product_key,
            "source_product_code": f"SKU{product_key:04d}",
            "product_name": prod["product_name"],
            "brand_name": "Wyld",
            "category_name": prod["category_name"],
            "flavor_name": prod["flavor_name"],
            "product_line": prod["product_line"],            # new
            "benefit_line": prod["benefit_line"],            # new
            "effect_type": prod["effect_type"],              # new
            "ratio_label": prod["ratio_label"],              # new
            "pack_size": int(prod["pack_size"]),
            "potency_mg_total": int(prod["potency_mg_total"]),  # renamed from generic potency_mg
            "base_list_price": round(max(4, price), 2),
            "base_cogs_ratio": round(cogs_ratio, 4),
            "demand_weight": float(prod["demand_weight"]),   # new (used by sales generation)
            "is_active": 1,
        })

    return pd.DataFrame(rows)

# Generate dimension table for locations
def generate_dim_location(cfg, rng):
    states = [("OR","Pacific NW"),("WA","Pacific NW"),("CA","West"),("CO","Mountain"),("AZ","Southwest"),("NV","West"),("MI","Midwest"),("IL","Midwest")]
    rows = []
    for i in range(1, cfg.n_locations + 1):
        state, region = states[(i-1) % len(states)]
        loc_type = rng.choice(["Retail Account","Distributor Account","Facility"], p=[0.65,0.25,0.10])
        if loc_type == "Facility":
            preferred = "Distributor"; size_tier="L"; vol = rng.uniform(1.15,1.45)
        elif loc_type == "Distributor Account":
            preferred = "Wholesale"; size_tier = rng.choice(["M","L"], p=[0.6,0.4]); vol = rng.uniform(0.95,1.35)
        else:
            preferred = "Retail"; size_tier = rng.choice(["S","M","L"], p=[0.35,0.45,0.20]); vol = {"S":rng.uniform(0.55,0.85),"M":rng.uniform(0.85,1.15),"L":rng.uniform(1.15,1.55)}[size_tier]
        rows.append({
            "location_key": i,
            "source_location_code": f"{state}{i:02d}",
            "location_name": f"{state} Site {i:02d}",
            "state_province": state,
            "region": region,
            "location_type": loc_type,
            "preferred_channel": preferred,
            "size_tier": size_tier,
            "volume_multiplier": round(float(vol),4),
            "is_active": 1,
        })
    return pd.DataFrame(rows)


# Generate dimension table for channels
def generate_dim_channel():
    return pd.DataFrame([(1,"Retail"),(2,"Wholesale"),(3,"Distributor")], columns=["channel_key","channel_name"])


# Generate dimension table for employee groups
def generate_dim_employee_group():
    return pd.DataFrame([
        (1,"Operations","Fulfillment"),
        (2,"Operations","Warehouse"),
        (3,"Sales","Field Sales"),
        (4,"Finance","FP&A"),
        (5,"People","HR"),
        (6,"Operations","Manufacturing"),
        (7,"Supply Chain","Planning"),
        (8,"G&A","Corporate"),
    ], columns=["employee_group_key","department_name","team_name"])


# Generate fact table for sales
def generate_fact_sales(dim_date, dim_product, dim_location, dim_channel, cfg, rng):
    date_df = dim_date[["date_key","full_date","month_num"]]
    promo_dates = pd.date_range(cfg.start_date, cfg.end_date, freq="35D")
    cat_weight = {"Gummies":1.25,"Beverages":0.85,"Tinctures":0.40,"Mints":0.55}
    channel_base = {"Retail":1.00,"Wholesale":0.75,"Distributor":0.55}
    channel_price_factor = {"Retail": 1.00, "Wholesale": 0.88, "Distributor": 0.82}
    channels = dict(zip(dim_channel["channel_name"], dim_channel["channel_key"]))
    rows = []

    for _, drow in date_df.iterrows():
        full_date = pd.Timestamp(drow["full_date"])
        weekday = full_date.weekday()
        season = month_seasonality(int(drow["month_num"]))
        promo = any(abs((full_date - pd.Timestamp(p)).days) <= 3 for p in promo_dates)
        promo_boost = 1.18 if promo else 1.0
        promo_discount_extra = 0.06 if promo else 0.0

        for _, l in dim_location.iterrows():
            for _, p in dim_product.iterrows():
                ch_list = [l["preferred_channel"]]
                if rng.random() < 0.18:
                    ch_list.append(rng.choice([c for c in ["Retail","Wholesale","Distributor"] if c != l["preferred_channel"]]))

                for ch_name in ch_list:
                    base_units = 2.2 * float(l["volume_multiplier"]) * cat_weight[p["category_name"]] * channel_base[ch_name] * season * weekday_factor(weekday, ch_name)
                    prob = float(np.clip(sigmoid((base_units - 1.2)*1.2), 0.12, 0.98))
                    if rng.random() > prob:
                        continue
                    units = max(1, int(rng.poisson(max(0.2, base_units * promo_boost))))

                    # Product/base price with row-level noise
                    base_unit_list_price = float(p["base_list_price"]) * float(rng.normal(1.0, 0.03))

                    # Apply channel price factor to get the actual unit list price for this sale row
                    unit_list_price = base_unit_list_price * channel_price_factor[ch_name]
                    unit_list_price = round(max(0.01, unit_list_price), 2)

                    # Row-level discount (store as decimal rate, e.g. 0.12 = 12%)
                    discount_rate = float(np.clip(rng.normal(0.08 + promo_discount_extra, 0.035), 0, 0.35))
                    discount_rate = round(discount_rate, 4)

                    # Net unit price after discount
                    unit_net_price = round(unit_list_price * (1 - discount_rate), 2)

                    # Extended amounts
                    gross = round(units * unit_list_price, 2)
                    net = round(units * unit_net_price, 2)

                    # Cost
                    cogs_ratio = float(np.clip(p["base_cogs_ratio"] + rng.normal(0, 0.015), 0.25, 0.75))
                    cogs = round(net * cogs_ratio, 2)

                    orders = max(1, int(np.ceil(units / rng.integers(2,6)))) if ch_name=="Retail" else max(1, int(np.ceil(units / rng.integers(8,20))))
                    customers = max(1, int(np.ceil(orders * rng.uniform(0.85,1.0))))
                    # Add rows to fact table
                    rows.append({
                    "date_key": int(drow["date_key"]),
                    "product_key": int(p["product_key"]),
                    "location_key": int(l["location_key"]),
                    "channel_key": int(channels[ch_name]),
                    "units_sold": units,
                    "unit_list_price": unit_list_price,
                    "unit_net_price": unit_net_price,
                    "discount_rate": discount_rate,
                    "gross_sales_amount": gross,
                    "discount_amount": round(gross - net, 2),
                    "net_sales_amount": net,
                    "cogs_amount": cogs,
                    "order_count": orders,
                    "customer_count": customers,
                    })
    return pd.DataFrame(rows)

# Generate fact table for inventory
def generate_fact_inventory(dim_date, dim_product, dim_location, fact_sales, rng):
    sales_agg = fact_sales.groupby(["date_key","product_key","location_key"], as_index=False)["units_sold"].sum().rename(columns={"units_sold":"sales_units"})
    grid = dim_date[["date_key"]].assign(k=1).merge(dim_product[["product_key"]].assign(k=1), on="k").merge(dim_location[["location_key"]].assign(k=1), on="k").drop(columns="k")
    inv = grid.merge(sales_agg, how="left", on=["date_key","product_key","location_key"])
    inv["sales_units"] = inv["sales_units"].fillna(0).astype(int)
    prod_factor = dim_product.set_index("product_key")["category_name"].map({"Gummies":1.4,"Beverages":1.8,"Tinctures":0.7,"Mints":0.9})
    loc_factor = dim_location.set_index("location_key")["volume_multiplier"]

    inv = inv.sort_values(["product_key","location_key","date_key"]).reset_index(drop=True)
    state = {}
    out_cols = {k: [] for k in ["on_hand_units","received_units","shipped_units","requested_units","backordered_units","in_stock_flag"]}
    for r in inv.itertuples(index=False):
        key = (r.product_key, r.location_key)
        if key not in state:
            state[key] = int(max(10, rng.normal(80,20) * prod_factor.loc[r.product_key] * loc_factor.loc[r.location_key]))
        current = state[key]
        sales_units = int(r.sales_units)
        requested = int(max(sales_units, round(sales_units * rng.uniform(1.00,1.08))))
        shipped = min(current, requested)
        backordered = max(0, requested - shipped)
        low_thr = int(max(6, 20 * prod_factor.loc[r.product_key] * loc_factor.loc[r.location_key]))
        receipt = 0
        if current < low_thr or rng.random() < 0.12:
            receipt = int(max(0, rng.normal(55,18) * prod_factor.loc[r.product_key] * loc_factor.loc[r.location_key]))
            if rng.random() < 0.06:
                receipt = 0
        end_oh = max(0, current - shipped + receipt)
        state[key] = end_oh

        out_cols["on_hand_units"].append(int(end_oh))
        out_cols["received_units"].append(int(receipt))
        out_cols["shipped_units"].append(int(shipped))
        out_cols["requested_units"].append(int(requested))
        out_cols["backordered_units"].append(int(backordered))
        out_cols["in_stock_flag"].append(1 if end_oh > 0 else 0)

    for c, vals in out_cols.items():
        inv[c] = vals
    return inv[["date_key","product_key","location_key","on_hand_units","received_units","shipped_units","requested_units","backordered_units","in_stock_flag"]]


# Generate fact table for labor
def generate_fact_labor(dim_date, dim_location, dim_employee_group, fact_sales, fact_inventory, rng):
    sales_loc = fact_sales.groupby(["date_key","location_key"], as_index=False).agg(net_sales_amount=("net_sales_amount","sum"), units_sold=("units_sold","sum"))
    ship_loc = fact_inventory.groupby(["date_key","location_key"], as_index=False).agg(shipped_units=("shipped_units","sum"), backordered_units=("backordered_units","sum"))
    base = dim_date[["date_key"]].assign(k=1).merge(dim_location[["location_key","volume_multiplier"]].assign(k=1), on="k").drop(columns="k")
    base = base.merge(sales_loc, how="left", on=["date_key","location_key"]).merge(ship_loc, how="left", on=["date_key","location_key"])
    for c in ["net_sales_amount","units_sold","shipped_units","backordered_units"]:
        base[c] = base[c].fillna(0)

    weights = {"Fulfillment":0.22,"Warehouse":0.20,"Field Sales":0.16,"FP&A":0.06,"HR":0.05,"Manufacturing":0.20,"Planning":0.08,"Corporate":0.03}
    rates = {"Fulfillment":24,"Warehouse":26,"Field Sales":34,"FP&A":42,"HR":36,"Manufacturing":29,"Planning":38,"Corporate":45}
    hc_state = {}
    rows = []

    for date_key in sorted(base["date_key"].unique()):
        dt = pd.to_datetime(str(date_key))
        day_df = base[base["date_key"] == date_key]
        for b in day_df.itertuples(index=False):
            for e in dim_employee_group.itertuples(index=False):
                team = e.team_name
                hk = (b.location_key, e.employee_group_key)
                if hk not in hc_state:
                    start_hc = {"Fulfillment":4,"Warehouse":4,"Field Sales":3,"FP&A":1,"HR":1,"Manufacturing":5,"Planning":2,"Corporate":1}[team]
                    hc_state[hk] = max(1, int(round(start_hc * float(b.volume_multiplier))))
                hires = 0; terms = 0
                if dt.day <= 3 and rng.random() < 0.10:
                    hc_state[hk] += 1; hires = 1
                if dt.day >= 20 and rng.random() < 0.08 and hc_state[hk] > 1:
                    hc_state[hk] -= 1; terms = 1
                hc = hc_state[hk]
                weekday = dt.weekday()
                workload = 0.0006*float(b.net_sales_amount) + 0.09*float(b.shipped_units) + 0.15*float(b.backordered_units)
                day_mult = 0.55 if weekday >= 5 and team in ("FP&A","HR","Corporate","Planning") else (0.8 if weekday >= 5 else 1.0)
                labor_hours = max(0.0, rng.normal(hc * weights[team] * 8.5 * day_mult + workload * weights[team], 1.4))
                ot_prob = np.clip((workload - 20) / 65, 0, 0.45)
                overtime = float(max(0, rng.normal(0.12 * labor_hours, 0.8))) if rng.random() < ot_prob else 0.0
                rate = rates[team] * float(rng.normal(1.0, 0.05))
                cost = labor_hours * rate + overtime * rate * 0.5
                rows.append({
                    "date_key": int(date_key),
                    "location_key": int(b.location_key),
                    "employee_group_key": int(e.employee_group_key),
                    "labor_hours": round(float(labor_hours),2),
                    "overtime_hours": round(float(overtime),2),
                    "headcount": int(hc),
                    "hires": hires,
                    "terminations": terms,
                    "labor_cost_amount": round(float(cost),2),
                })
    return pd.DataFrame(rows)

# Generate finance summary extract
def generate_finance_summary_extract(dim_date, fact_sales, fact_labor, rng):
    sales_m = (fact_sales.merge(dim_date[["date_key","month_start_date"]], on="date_key", how="left")
               .groupby("month_start_date", as_index=False)
               .agg(gross_sales=("gross_sales_amount","sum"),
                    net_sales=("net_sales_amount","sum"),
                    cogs=("cogs_amount","sum")))
    sales_m["gross_margin"] = sales_m["net_sales"] - sales_m["cogs"]
    labor_m = (fact_labor.merge(dim_date[["date_key","month_start_date"]], on="date_key", how="left")
               .groupby("month_start_date", as_index=False)
               .agg(labor_cost=("labor_cost_amount","sum")))
    monthly = sales_m.merge(labor_m, on="month_start_date", how="left").fillna(0)
    rows = []
    for r in monthly.itertuples(index=False):
        vals = {
            "gross_sales": float(r.gross_sales),
            "net_sales": float(r.net_sales),
            "cogs": float(r.cogs),
            "gross_margin": float(r.gross_margin),
            "labor_cost": float(r.labor_cost),
        }
        for k, amount in vals.items():
            drift = float(rng.normal(0.002 if k in ("gross_sales","net_sales") else 0.001, 0.003))
            if rng.random() < 0.12:
                drift += float(rng.choice([-0.0085, 0.0090]))
            label = {
                "gross_sales": rng.choice(["Gross Sales","gross_sales","GROSS_SALES"]),
                "net_sales": rng.choice(["Net Sales","net_sales","NET_SALES"]),
                "cogs": rng.choice(["COGS","cogs","Cost of Goods"]),
                "gross_margin": rng.choice(["Gross Margin","gross_margin"]),
                "labor_cost": rng.choice(["Labor Cost","labor_cost"]),
            }[k]
            rows.append({
                "month_start": pd.Timestamp(r.month_start_date).date(),
                "metric_name": label,
                "actual_amount": round(amount * (1 + drift), 2),
                "currency_code": "USD",
            })
    return pd.DataFrame(rows)

# Build sales source extract
def build_sales_source_extract(fact_sales, dim_date, dim_product, dim_location, dim_channel, rng):
    df = (fact_sales.merge(dim_date[["date_key","full_date"]], on="date_key")
                  .merge(dim_product[["product_key","source_product_code","product_name"]], on="product_key")
                  .merge(dim_location[["location_key","source_location_code"]], on="location_key")
                  .merge(dim_channel[["channel_key","channel_name"]], on="channel_key"))
    src = pd.DataFrame({
        "sale_date": df["full_date"].dt.strftime("%Y-%m-%d"),
        "sku": df["source_product_code"],
        "product_name": df["product_name"],
        "store_id": df["source_location_code"],
        "channel": df["channel_name"],
        "qty": df["units_sold"],
        "gross_sales": df["gross_sales_amount"],
        "net_sales": df["net_sales_amount"],
        "cogs": df["cogs_amount"],
        "orders": df["order_count"],
        "customers": df["customer_count"],
        "unit_list_price": df["unit_list_price"],
        "unit_net_price": df["unit_net_price"],
        "discount_rate": df["discount_rate"],
    })
    dup_n = max(5, int(len(src) * 0.006))
    src = pd.concat([src, src.sample(n=dup_n, random_state=int(rng.integers(1,1_000_000)))], ignore_index=True)
    miss_idx = src.sample(n=max(3,int(len(src)*0.0025)), random_state=int(rng.integers(1,1_000_000))).index
    src.loc[miss_idx, "store_id"] = None
    ch_idx = src.sample(n=max(10,int(len(src)*0.01)), random_state=int(rng.integers(1,1_000_000))).index.tolist()
    third = len(ch_idx)//3
    for i in ch_idx[:third]:
        src.at[i, "channel"] = str(src.at[i, "channel"]).upper()
    for i in ch_idx[third:2*third]:
        src.at[i, "channel"] = " " + str(src.at[i, "channel"]).lower() + " "
    pn_idx = src.sample(n=max(10,int(len(src)*0.008)), random_state=int(rng.integers(1,1_000_000))).index
    src.loc[pn_idx, "product_name"] = src.loc[pn_idx, "product_name"].astype(str) + "  "
    return src.sort_values(["sale_date","sku","store_id"], na_position="last").reset_index(drop=True)

# Build inventory source extract
def build_inventory_source_extract(fact_inventory, dim_date, dim_product, dim_location, rng):
    df = (fact_inventory.merge(dim_date[["date_key","full_date"]], on="date_key")
                     .merge(dim_product[["product_key","source_product_code"]], on="product_key")
                     .merge(dim_location[["location_key","source_location_code"]], on="location_key"))
    src = pd.DataFrame({
        "snapshot_date": df["full_date"].dt.strftime("%Y-%m-%d"),
        "sku": df["source_product_code"],
        "site_code": df["source_location_code"],
        "on_hand": df["on_hand_units"],
        "receipts": df["received_units"],
        "shipments": df["shipped_units"],
        "requested_units": df["requested_units"],
        "backordered_units": df["backordered_units"],
    })
    neg_idx = src.sample(n=min(25,max(5,int(len(src)*0.0003))), random_state=int(rng.integers(1,1_000_000))).index
    src.loc[neg_idx, "on_hand"] = -src.loc[neg_idx, "on_hand"].abs().clip(lower=1)
    site_idx = src.sample(n=max(10,int(len(src)*0.002)), random_state=int(rng.integers(1,1_000_000))).index.tolist()
    half = len(site_idx)//2
    src.loc[site_idx[:half], "site_code"] = src.loc[site_idx[:half], "site_code"].str.lower()
    src.loc[site_idx[half:], "site_code"] = src.loc[site_idx[half:], "site_code"].str.replace(r"([A-Z]{2})(\d+)", r"\1-\2", regex=True)
    # remove one date for one location
    loc = src["site_code"].astype(str).str.replace("-", "", regex=False).str.upper().iloc[0]
    gap_day = sorted(pd.to_datetime(src["snapshot_date"].unique()))[min(30, src["snapshot_date"].nunique()-1)].strftime("%Y-%m-%d")
    mask = (src["snapshot_date"] == gap_day) & (src["site_code"].astype(str).str.replace("-", "", regex=False).str.upper() == loc)
    src = src.loc[~mask].copy()
    return src.sort_values(["snapshot_date","sku","site_code"]).reset_index(drop=True)

# Build labor source extract
def build_labor_source_extract(fact_labor, dim_date, dim_location, dim_employee_group, rng):
    df = (fact_labor.merge(dim_date[["date_key","full_date"]], on="date_key")
                   .merge(dim_location[["location_key","source_location_code"]], on="location_key")
                   .merge(dim_employee_group[["employee_group_key","department_name","team_name"]], on="employee_group_key"))
    src = pd.DataFrame({
        "work_date": df["full_date"].dt.strftime("%Y-%m-%d"),
        "site_code": df["source_location_code"],
        "department": df["department_name"],
        "team": df["team_name"],
        "hours_worked": df["labor_hours"],
        "ot_hours": df["overtime_hours"],
        "employee_count": df["headcount"],
        "labor_cost": df["labor_cost_amount"],
    })
    idx = src.sample(n=max(8,int(len(src)*0.0015)), random_state=int(rng.integers(1,1_000_000))).index
    src.loc[idx, "team"] = src.loc[idx, "team"].replace({"Fulfillment":"Fulfilment"})
    bad_idx = src.sample(n=5, random_state=int(rng.integers(1,1_000_000))).index
    src.loc[bad_idx, "hours_worked"] = 0
    src.loc[bad_idx, "labor_cost"] = src.loc[bad_idx, "labor_cost"].clip(lower=50)

    src["work_date_dt"] = pd.to_datetime(src["work_date"])
    site = src["site_code"].iloc[0]
    start = src["work_date_dt"].min() + pd.Timedelta(days=120)
    end = start + pd.Timedelta(days=6)
    mask = (src["site_code"] == site) & (src["team"].astype(str).str.contains("Field", case=False, na=False)) & (src["work_date_dt"].between(start, end))
    src = src.loc[~mask].drop(columns=["work_date_dt"]).copy()
    return src.sort_values(["work_date","site_code","team"]).reset_index(drop=True)

# Save sample files
def save_samples(paths, dim_date, dim_product, dim_location, dim_channel, dim_employee_group, fact_sales, fact_inventory, fact_labor):
    dates = sorted(dim_date["date_key"].tolist())[:14]
    prods = sorted(dim_product["product_key"].tolist())[:5]
    locs = sorted(dim_location["location_key"].tolist())[:3]
    samples = {
        "dim_date_sample.csv": dim_date[dim_date["date_key"].isin(dates)],
        "dim_product_sample.csv": dim_product[dim_product["product_key"].isin(prods)],
        "dim_location_sample.csv": dim_location[dim_location["location_key"].isin(locs)],
        "dim_channel_sample.csv": dim_channel,
        "dim_employee_group_sample.csv": dim_employee_group,
        "fact_sales_sample.csv": fact_sales[fact_sales["date_key"].isin(dates) & fact_sales["product_key"].isin(prods) & fact_sales["location_key"].isin(locs)],
        "fact_inventory_sample.csv": fact_inventory[fact_inventory["date_key"].isin(dates) & fact_inventory["product_key"].isin(prods) & fact_inventory["location_key"].isin(locs)],
        "fact_labor_sample.csv": fact_labor[fact_labor["date_key"].isin(dates) & fact_labor["location_key"].isin(locs)],
    }
    for fname, df in samples.items():
        write_csv(df, paths["sample"] / fname)

# Please install openpyxl before running this script
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", default="2025-01-01")
    ap.add_argument("--end", default="2025-12-31")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--products", type=int, default=60)
    ap.add_argument("--locations", type=int, default=15)
    args = ap.parse_args()
    cfg = Config(start_date=args.start, end_date=args.end, seed=args.seed, n_products=args.products, n_locations=args.locations)

    repo_root = Path(__file__).resolve().parents[1]
    paths = ensure_dirs(repo_root)
    rng = np.random.default_rng(cfg.seed)

    dim_date = generate_dim_date(cfg)
    dim_product = generate_dim_product(cfg, rng)
    dim_location = generate_dim_location(cfg, rng)
    dim_channel = generate_dim_channel()
    dim_employee_group = generate_dim_employee_group()

    fact_sales = generate_fact_sales(dim_date, dim_product, dim_location, dim_channel, cfg, rng)
    fact_inventory = generate_fact_inventory(dim_date, dim_product, dim_location, fact_sales, rng)
    fact_labor = generate_fact_labor(dim_date, dim_location, dim_employee_group, fact_sales, fact_inventory, rng)
    fin_src = generate_finance_summary_extract(dim_date, fact_sales, fact_labor, rng)

    sales_src = build_sales_source_extract(fact_sales, dim_date, dim_product, dim_location, dim_channel, rng)
    inv_src = build_inventory_source_extract(fact_inventory, dim_date, dim_product, dim_location, rng)
    labor_src = build_labor_source_extract(fact_labor, dim_date, dim_location, dim_employee_group, rng)

    # Save modeled truth
    for name, df in {
        "dim_date.csv": dim_date,
        "dim_product.csv": dim_product,
        "dim_location.csv": dim_location,
        "dim_channel.csv": dim_channel,
        "dim_employee_group.csv": dim_employee_group,
        "fact_sales.csv": fact_sales,
        "fact_inventory.csv": fact_inventory,
        "fact_labor.csv": fact_labor
    }.items():
        write_csv(df, paths["modeled"] / name)

    # Save source extracts (messy)
    write_csv(sales_src, paths["sales_src"] / "sales_distributor_extract.csv")
    write_csv(inv_src, paths["ops_src"] / "inventory_erp_snapshot.csv")
    write_xlsx(labor_src, paths["people_src"] / "labor_hours_payroll_export.xlsx", sheet_name="labor_export")
    write_xlsx(fin_src, paths["finance_src"] / "finance_actuals_summary.xlsx", sheet_name="finance_actuals")

    save_samples(paths, dim_date, dim_product, dim_location, dim_channel, dim_employee_group, fact_sales, fact_inventory, fact_labor)

    row_counts = pd.DataFrame([
        {"table_name": "dim_date", "row_count": len(dim_date)},
        {"table_name": "dim_product", "row_count": len(dim_product)},
        {"table_name": "dim_location", "row_count": len(dim_location)},
        {"table_name": "dim_channel", "row_count": len(dim_channel)},
        {"table_name": "dim_employee_group", "row_count": len(dim_employee_group)},
        {"table_name": "fact_sales", "row_count": len(fact_sales)},
        {"table_name": "fact_inventory", "row_count": len(fact_inventory)},
        {"table_name": "fact_labor", "row_count": len(fact_labor)},
        {"table_name": "src_sales_distributor_extract", "row_count": len(sales_src)},
        {"table_name": "src_inventory_erp_snapshot", "row_count": len(inv_src)},
        {"table_name": "src_labor_hours_payroll_export", "row_count": len(labor_src)},
        {"table_name": "src_finance_actuals_summary", "row_count": len(fin_src)},
    ])
    write_csv(row_counts, paths["docs"] / "generated_row_counts.csv")
    summary = {
        "config": asdict(cfg),
        "notes": [
            "Modeled CSVs are the truth layer.",
            "Source extracts intentionally include controlled quality issues for QA/QC demos."
        ]
    }
    (paths["docs"] / "generated_data_summary.json").write_text(pd.Series(summary).to_json(indent=2), encoding="utf-8")

    print("Synthetic data generation complete.")
    print(row_counts.to_string(index=False))


if __name__ == "__main__":
    main()
