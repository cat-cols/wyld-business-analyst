# Oregon Cannabis License Reference Data

This folder holds **shared reference data** that can be used by multiple projects in this repo (including `01_ops_command_center`).

It contains:

- **Raw source drop (immutable):** `Cannabis-Business-Licenses-All.xlsx`
- **Derived clean subset:** `or_recreational_retailers_wholesalers_filtered.csv` (recreational retailers/wholesalers only)

## Why this exists

Wyld (and basically any consumer-products company) ends up needing a **stable “location / account master”** to join facts to:
sales, inventory, shipments, labor, finance, etc.

This dataset is used as a realistic seed for a *dispensary master* / *account master* dimension and for QA sanity checks.

## Recommended repo layout

Put shared reference data at the **repo root** so multiple projects can reuse it:

```
data/reference/or_cannabis_licenses/
  raw/
    Cannabis-Business-Licenses-All.xlsx
  derived/
    or_recreational_retailers_wholesalers_filtered.csv
  manifest.json
  README.md
```

Then each project can either:

- read from `data/reference/...` directly, or
- copy/symlink the derived file into the project’s own `01_ops_command_center/data/reference/` folder if you want project isolation.

## What’s inside the derived CSV

- Rows: **1,059**
- Primary key: `license_number` (unique in this file)
- License group counts:
  - Recreational Retailer: 794
  - Recreational Wholesaler: 263
  - Recreational Retailer/Wholesaler: 2

Columns:

- `license_number`
- `business_name`
- `license_group`
- `business_licenses`
- `license_type`
- `physical_address`
- `county`
- `expiration_date`
- `tier`
- `canopy_type`
- `indoor_canopy_sqft`
- `outdoor_canopy_sqft`
- `endorsement`
- `sos_registration_number`

## How the derived file is built

The script `scripts/build_or_license_reference.py`:

1. Reads the source Excel file.
2. Normalizes column names + trims text.
3. Builds `license_text = business_licenses | license_type`.
4. Filters to **recreational** AND (**retail** OR **wholesale**).
5. Dedupe by `license_number` (keeps latest expiration date when available).
6. Writes:
   - filtered detail CSV
   - summary CSV (group counts, county counts, status breakdown)

Example run:

```bash
python3 scripts/build_or_license_reference.py \
  --src notes/data/Cannabis-Business-Licenses-All.xlsx \
  --project-dir 01_ops_command_center
```

## Loading into Postgres (optional)

If you want to stage this into a raw table (for joins in SQL):

1. Create a raw table, e.g. `raw.dispensary_master` (or `raw.or_license_reference`).
2. COPY the CSV in, or load via your generator script.
3. Point `stg_dispensary_master.sql` at that raw table.

A simple approach (psql):

```bash
psql "$PROJECT1_PG_DSN" -c "create schema if not exists raw;"
psql "$PROJECT1_PG_DSN" -c "drop table if exists raw.or_license_reference;"
psql "$PROJECT1_PG_DSN" -c "
create table raw.or_license_reference (
  license_number text,
  business_name text,
  license_group text,
  business_licenses text,
  license_type text,
  physical_address text,
  county text,
  expiration_date date,
  tier text,
  canopy_type text,
  indoor_canopy_sqft double precision,
  outdoor_canopy_sqft double precision,
  endorsement text,
  sos_registration_number text
);"
psql "$PROJECT1_PG_DSN" -c "\copy raw.or_license_reference from 'data/reference/or_cannabis_licenses/derived/or_recreational_retailers_wholesalers_filtered.csv' with (format csv, header true)"
```

## Notes / gotchas

- Treat the Excel file as **external data**. Don’t edit it in place; version it by replacing the whole file + updating `manifest.json`.
- The derived CSV is only as good as the source export and text filtering logic; expect occasional misclassification.
- For simulated projects, you may still want to generate synthetic IDs (`dispensary_id`) and map them to `license_number`.

## Metadata

See `manifest.json` for checksums, row counts, and build details.
