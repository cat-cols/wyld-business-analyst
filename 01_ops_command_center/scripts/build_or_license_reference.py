#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
import pandas as pd


def parse_args():
    ap = argparse.ArgumentParser(
        description="Filter Oregon cannabis licenses to recreational retailers/wholesalers and build summaries."
    )
    ap.add_argument(
        "--repo-root",
        type=str,
        default=None,
        help="Repo root path (defaults to parent of this script, i.e. ../ from scripts/)",
    )
    ap.add_argument(
        "--src",
        type=str,
        default="notes/data/Cannabis-Business-Licenses-All.xlsx",
        help="Path to source Excel file (relative to repo root unless absolute)",
    )
    ap.add_argument(
        "--project-dir",
        type=str,
        default="01_ops_command_center",
        help="Project folder to write outputs into",
    )
    ap.add_argument(
        "--filtered-out",
        type=str,
        default=None,
        help="Optional override for filtered CSV output path",
    )
    ap.add_argument(
        "--summary-out",
        type=str,
        default=None,
        help="Optional override for summary CSV output path",
    )
    return ap.parse_args()


def resolve_path(p: str | None, repo_root: Path) -> Path | None:
    if p is None:
        return None
    path = Path(p)
    return path if path.is_absolute() else (repo_root / path)


def main():
    args = parse_args()

    # Default repo root: parent of /scripts
    # e.g. /repo/scripts/build_or_license_reference.py -> /repo
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[1]
    repo_root = Path(args.repo_root).resolve() if args.repo_root else default_repo_root

    src_path = resolve_path(args.src, repo_root)

    # Default outputs (repo-relative, not hardcoded absolute)
    default_filtered = repo_root / args.project_dir / "data" / "reference" / "or_recreational_retailers_wholesalers_filtered.csv"
    default_summary = repo_root / args.project_dir / "docs" / "or_recreational_retailers_wholesalers_summary.csv"

    out_filtered = resolve_path(args.filtered_out, repo_root) or default_filtered
    out_summary = resolve_path(args.summary_out, repo_root) or default_summary

    out_filtered.parent.mkdir(parents=True, exist_ok=True)
    out_summary.parent.mkdir(parents=True, exist_ok=True)

    if not src_path.exists():
        raise FileNotFoundError(f"Source file not found: {src_path}")

    # --- Read Excel ---
    df = pd.read_excel(src_path, sheet_name=0, engine="openpyxl")

    # --- Normalize/clean column names ---
    df.columns = (
        df.columns.astype(str)
        .str.strip()
        .str.rstrip(",")
    )

    rename_map = {
        "License Number": "license_number",
        "Business Licenses": "business_licenses",
        "Business Name": "business_name",
        "SOS Registration Number": "sos_registration_number",
        "PhysicalAddress": "physical_address",
        "County": "county",
        "License Type": "license_type",
        "Expiration Date": "expiration_date",
        "Tier": "tier",
        "Canopy Type": "canopy_type",
        "Indoor Canopy SQFT": "indoor_canopy_sqft",
        "Outdoor Canopy SQFT": "outdoor_canopy_sqft",
        "Endorsement": "endorsement",
    }
    df = df.rename(columns={k: v for k, v in rename_map.items() if k in df.columns})

    print("\nColumns found after rename:")
    print(df.columns.tolist())

    required_cols = ["business_licenses", "license_type", "business_name", "county"]
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise ValueError(f"Missing expected columns: {missing}")

    # --- Clean text fields ---
    text_cols = [
        "business_licenses", "license_type", "business_name", "county",
        "physical_address", "endorsement", "tier", "canopy_type"
    ]
    for col in text_cols:
        if col in df.columns:
            df[col] = df[col].astype("string").str.strip()

    # Parse expiration date if present
    if "expiration_date" in df.columns:
        df["expiration_date"] = pd.to_datetime(df["expiration_date"], errors="coerce")

    # --- Build combined searchable license text ---
    df["license_text"] = (
        df["business_licenses"].fillna("").astype("string").str.strip() + " | " +
        df["license_type"].fillna("").astype("string").str.strip()
    )

    # --- Filter: Recreational Retailer + Recreational Wholesaler only ---
    txt = df["license_text"].str.lower()

    mask_recreational = txt.str.contains("recreat", na=False)
    mask_retail = txt.str.contains("retail", na=False)
    mask_wholesale = txt.str.contains("wholesal", na=False)

    filtered = df.loc[mask_recreational & (mask_retail | mask_wholesale)].copy()

    # --- Standardize license_group ---
    filtered["license_group"] = pd.NA
    filtered.loc[
        filtered["license_text"].str.contains("retail", case=False, na=False),
        "license_group"
    ] = "Recreational Retailer"
    filtered.loc[
        filtered["license_text"].str.contains("wholesal", case=False, na=False),
        "license_group"
    ] = "Recreational Wholesaler"

    both_mask = (
        filtered["license_text"].str.contains("retail", case=False, na=False) &
        filtered["license_text"].str.contains("wholesal", case=False, na=False)
    )
    filtered.loc[both_mask, "license_group"] = "Recreational Retailer/Wholesaler"

    # --- Normalize county formatting ---
    if "county" in filtered.columns:
        filtered["county"] = (
            filtered["county"]
            .replace({"nan": pd.NA, "None": pd.NA, "": pd.NA})
            .astype("string")
            .str.strip()
            .str.title()
        )

    # --- Dedupe exact duplicate licenses ---
    if "license_number" in filtered.columns:
        sort_cols = ["license_number"]
        if "expiration_date" in filtered.columns:
            sort_cols.append("expiration_date")

        filtered = (
            filtered
            .sort_values(sort_cols)
            .drop_duplicates(subset=["license_number"], keep="last")
        )

    # --- Save filtered detail file ---
    preferred_order = [
        "license_number",
        "business_name",
        "license_group",
        "business_licenses",
        "license_type",
        "physical_address",
        "county",
        "expiration_date",
        "tier",
        "canopy_type",
        "indoor_canopy_sqft",
        "outdoor_canopy_sqft",
        "endorsement",
        "sos_registration_number",
    ]
    existing_cols = [c for c in preferred_order if c in filtered.columns]
    remaining_cols = [c for c in filtered.columns if c not in existing_cols + ["license_text"]]

    filtered_out = filtered[existing_cols + remaining_cols].copy()
    filtered_out.to_csv(out_filtered, index=False)

    # --- Build aggregated summary ---
    summary_parts = []

    summary_by_group = (
        filtered.groupby("license_group", dropna=False)
        .size()
        .reset_index(name="location_count")
    )
    summary_by_group["summary_level"] = "license_group"
    summary_parts.append(summary_by_group)

    if "county" in filtered.columns:
        summary_by_county = (
            filtered.groupby(["county", "license_group"], dropna=False)
            .size()
            .reset_index(name="location_count")
        )
        summary_by_county["summary_level"] = "county_license_group"
        summary_parts.append(summary_by_county)

    if "expiration_date" in filtered.columns:
        today = pd.Timestamp.today().normalize()
        filtered["license_status"] = pd.NA
        filtered.loc[filtered["expiration_date"].isna(), "license_status"] = "Unknown"
        filtered.loc[
            filtered["expiration_date"].notna() & (filtered["expiration_date"] >= today),
            "license_status"
        ] = "Active/Unexpired"
        filtered.loc[
            filtered["expiration_date"].notna() & (filtered["expiration_date"] < today),
            "license_status"
        ] = "Expired"

        summary_by_status = (
            filtered.groupby(["license_group", "license_status"], dropna=False)
            .size()
            .reset_index(name="location_count")
        )
        summary_by_status["summary_level"] = "license_group_status"
        summary_parts.append(summary_by_status)

    summary = pd.concat(summary_parts, ignore_index=True, sort=False)
    summary.to_csv(out_summary, index=False)

    # --- Console output ---
    print("\nDone.")
    print(f"Repo root:      {repo_root}")
    print(f"Source file:    {src_path}")
    print(f"Filtered rows:  {len(filtered_out):,}")
    print(f"Filtered file:  {out_filtered}")
    print(f"Summary file:   {out_summary}")

    print("\nCounts by license group:")
    print(summary_by_group.to_string(index=False))

    if "county" in filtered.columns:
        print("\nTop counties (all selected license groups):")
        top_counties = (
            filtered.groupby("county", dropna=False)
            .size()
            .reset_index(name="location_count")
            .sort_values("location_count", ascending=False)
            .head(15)
        )
        print(top_counties.to_string(index=False))


if __name__ == "__main__":
    main()