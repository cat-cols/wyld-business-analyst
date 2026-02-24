
# Fake Data Generation Method

Use `scripts/generate_data.py` to generate **realistic synthetic data** for your Ops Command Center.

## What it creates
### Modeled truth layer (`data/modeled/`)
- `dim_date.csv`
- `dim_product.csv`
- `dim_location.csv`
- `dim_channel.csv`
- `dim_employee_group.csv`
- `fact_sales.csv`
- `fact_inventory.csv`
- `fact_labor.csv`

### Messy source extracts (`data/source_extracts/`)
- `sales/sales_distributor_extract.csv`
- `ops/inventory_erp_snapshot.csv`
- `people/labor_hours_payroll_export.xlsx`
- `finance/finance_actuals_summary.xlsx`

### Git-friendly sample subset (`data/sample/`)
Small 2-week subset for repo inspection.

## Why this is good for your portfolio
The script intentionally injects realistic issues:
- duplicates
- missing IDs
- inconsistent text/casing
- date gaps
- slight finance reconciliation drift

That gives your staging + QA/QC + reconciliation logic something real to catch.

## Run it
From the repo root:

```bash
python3 scripts/generate_data.py
```

Custom run (same script, different volume/date range):

```bash
python3 scripts/generate_data.py --start 2025-01-01 --end 2025-12-31 --seed 42 --products 60 --locations 15
```
