#!/usr/bin/env python3
# 02_quarterly_dc_qaqc_system/scripts/generate_sample_quarterly_sources.py

from pathlib import Path
import pandas as pd


def get_project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def ensure_output_dir(project_root: Path) -> Path:
    output_dir = project_root / "data" / "source_extracts"
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def generate_retail_account_sales() -> pd.DataFrame:
    clean_rows = [
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "dispensary_account_id": "DSP001",
            "sku_id": "SKU001",
            "units_sold": 40,
            "gross_sales": 480.00,
            "discount_amount": 30.00,
            "net_sales": 450.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "dispensary_account_id": "DSP002",
            "sku_id": "SKU001",
            "units_sold": 32,
            "gross_sales": 384.00,
            "discount_amount": 24.00,
            "net_sales": 360.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "dispensary_account_id": "DSP001",
            "sku_id": "SKU002",
            "units_sold": 28,
            "gross_sales": 364.00,
            "discount_amount": 14.00,
            "net_sales": 350.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "dispensary_account_id": "DSP003",
            "sku_id": "SKU001",
            "units_sold": 50,
            "gross_sales": 600.00,
            "discount_amount": 45.00,
            "net_sales": 555.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "dispensary_account_id": "DSP002",
            "sku_id": "SKU002",
            "units_sold": 36,
            "gross_sales": 468.00,
            "discount_amount": 18.00,
            "net_sales": 450.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "dispensary_account_id": "DSP003",
            "sku_id": "SKU002",
            "units_sold": 44,
            "gross_sales": 572.00,
            "discount_amount": 22.00,
            "net_sales": 550.00,
        },
    ]

    defect_rows = [
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "dispensary_account_id": None,
            "sku_id": "SKU001",
            "units_sold": 30,
            "gross_sales": 390.00,
            "discount_amount": 15.00,
            "net_sales": 375.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "dispensary_account_id": "DSP001",
            "sku_id": "SKU001",
            "units_sold": 40,
            "gross_sales": 480.00,
            "discount_amount": 30.00,
            "net_sales": 450.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-04-12",
            "dispensary_account_id": "DSP002",
            "sku_id": "SKU001",
            "units_sold": 25,
            "gross_sales": 325.00,
            "discount_amount": 10.00,
            "net_sales": 315.00,
        },
    ]

    return pd.DataFrame(clean_rows + defect_rows)
    # Intentionally no rows for expected week 2026-02-01


def generate_wholesale_account_sales() -> pd.DataFrame:
    clean_rows = [
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "wholesale_account_id": "WH001",
            "sku_id": "SKU001",
            "cases_sold": 18,
            "gross_sales": 540.00,
            "net_sales": 500.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "wholesale_account_id": "WH002",
            "sku_id": "SKU002",
            "cases_sold": 12,
            "gross_sales": 420.00,
            "net_sales": 390.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "wholesale_account_id": "WH001",
            "sku_id": "SKU002",
            "cases_sold": 20,
            "gross_sales": 700.00,
            "net_sales": 650.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "wholesale_account_id": "WH003",
            "sku_id": "SKU001",
            "cases_sold": 16,
            "gross_sales": 560.00,
            "net_sales": 520.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "wholesale_account_id": "WH002",
            "sku_id": "SKU001",
            "cases_sold": 14,
            "gross_sales": 490.00,
            "net_sales": 455.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "wholesale_account_id": "WH003",
            "sku_id": "SKU002",
            "cases_sold": 15,
            "gross_sales": 525.00,
            "net_sales": 490.00,
        },
    ]

    defect_rows = [
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "wholesale_account_id": "WH004",
            "sku_id": None,
            "cases_sold": 10,
            "gross_sales": 300.00,
            "net_sales": 280.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "wholesale_account_id": "WH001",
            "sku_id": "SKU001",
            "cases_sold": 18,
            "gross_sales": 540.00,
            "net_sales": 500.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "wholesale_account_id": "WH005",
            "sku_id": "SKU003",
            "cases_sold": 8,
            "gross_sales": 500.00,
            "net_sales": 100.00,
        },
    ]

    return pd.DataFrame(clean_rows + defect_rows)


def generate_finance_actuals(
    retail_df: pd.DataFrame,
    wholesale_df: pd.DataFrame,
) -> pd.DataFrame:
    retail_net_sales = retail_df["net_sales"].sum()
    wholesale_net_sales = wholesale_df["net_sales"].sum()
    operational_net_sales = retail_net_sales + wholesale_net_sales

    # Intentionally create a finance total that is more than 1% away
    # from operational sales to trigger reconciliation failure.
    finance_revenue_total = round(operational_net_sales * 0.9725, 2)

    rows = [
        {
            "quarter_id": "2026Q1",
            "account_code": "4000",
            "department_code": "SALES",
            "actual_amount": finance_revenue_total,
            "reporting_category": "net_revenue",
        },
        {
            "quarter_id": "2026Q1",
            "account_code": "5000",
            "department_code": "OPS",
            "actual_amount": 4200.00,
            "reporting_category": "cogs",
        },
        {
            "quarter_id": "2026Q1",
            "account_code": "6100",
            "department_code": "GNA",
            "actual_amount": 1800.00,
            "reporting_category": "operating_expense",
        },
    ]

    return pd.DataFrame(rows)


def generate_inventory_quarterly() -> pd.DataFrame:
    clean_rows = [
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "warehouse_id": "WHSE01",
            "sku_id": "SKU001",
            "on_hand_units": 120,
            "available_units": 110,
            "inventory_value": 1020.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "warehouse_id": "WHSE01",
            "sku_id": "SKU002",
            "on_hand_units": 95,
            "available_units": 90,
            "inventory_value": 855.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "warehouse_id": "WHSE02",
            "sku_id": "SKU001",
            "on_hand_units": 140,
            "available_units": 132,
            "inventory_value": 1190.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "warehouse_id": "WHSE02",
            "sku_id": "SKU002",
            "on_hand_units": 88,
            "available_units": 80,
            "inventory_value": 792.00,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "warehouse_id": "WHSE01",
            "sku_id": "SKU001",
            "on_hand_units": 105,
            "available_units": 98,
            "inventory_value": 892.50,
        },
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "warehouse_id": "WHSE02",
            "sku_id": "SKU002",
            "on_hand_units": 76,
            "available_units": 70,
            "inventory_value": 684.00,
        },
    ]

    defect_rows = [
        # Negative inventory
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-18",
            "warehouse_id": "WHSE01",
            "sku_id": "SKU003",
            "on_hand_units": -12,
            "available_units": 0,
            "inventory_value": -108.00,
        },
        # Exact duplicate of a clean row
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-11",
            "warehouse_id": "WHSE01",
            "sku_id": "SKU001",
            "on_hand_units": 120,
            "available_units": 110,
            "inventory_value": 1020.00,
        },
        # Missing required key
        {
            "quarter_id": "2026Q1",
            "week_end_date": "2026-01-25",
            "warehouse_id": "WHSE02",
            "sku_id": None,
            "on_hand_units": 60,
            "available_units": 55,
            "inventory_value": 540.00,
        },
    ]

    return pd.DataFrame(clean_rows + defect_rows)


def generate_trade_adjustments() -> pd.DataFrame:
    clean_rows = [
        {
            "quarter_id": "2026Q1",
            "adjustment_id": "ADJ001",
            "account_id": "DSP001",
            "adjustment_type": "trade_spend",
            "adjustment_amount": -120.00,
            "adjustment_date": "2026-01-15",
            "reason_code": "PROMO",
        },
        {
            "quarter_id": "2026Q1",
            "adjustment_id": "ADJ002",
            "account_id": "DSP002",
            "adjustment_type": "rebate",
            "adjustment_amount": -200.00,
            "adjustment_date": "2026-01-22",
            "reason_code": "REBATE",
        },
        {
            "quarter_id": "2026Q1",
            "adjustment_id": "ADJ003",
            "account_id": "WH001",
            "adjustment_type": "promo_credit",
            "adjustment_amount": 75.00,
            "adjustment_date": "2026-01-29",
            "reason_code": "PRICE_PROTECTION",
        },
        {
            "quarter_id": "2026Q1",
            "adjustment_id": "ADJ004",
            "account_id": "DSP003",
            "adjustment_type": "return_adjustment",
            "adjustment_amount": -90.00,
            "adjustment_date": "2026-02-02",
            "reason_code": "RETURN",
        },
    ]

    defect_rows = [
        # Negative adjustment missing required reason code
        {
            "quarter_id": "2026Q1",
            "adjustment_id": "ADJ005",
            "account_id": "DSP002",
            "adjustment_type": "trade_spend",
            "adjustment_amount": -150.00,
            "adjustment_date": "2026-02-09",
            "reason_code": None,
        },
        # Duplicate adjustment_id
        {
            "quarter_id": "2026Q1",
            "adjustment_id": "ADJ002",
            "account_id": "DSP002",
            "adjustment_type": "rebate",
            "adjustment_amount": -200.00,
            "adjustment_date": "2026-01-22",
            "reason_code": "REBATE",
        },
        # Out-of-period adjustment date
        {
            "quarter_id": "2026Q1",
            "adjustment_id": "ADJ006",
            "account_id": "WH002",
            "adjustment_type": "promo_credit",
            "adjustment_amount": -80.00,
            "adjustment_date": "2026-04-15",
            "reason_code": "PROMO",
        },
    ]

    return pd.DataFrame(clean_rows + defect_rows)



def main() -> None:
    project_root = get_project_root()
    output_dir = ensure_output_dir(project_root)

    retail_df = generate_retail_account_sales()
    wholesale_df = generate_wholesale_account_sales()
    finance_df = generate_finance_actuals(retail_df, wholesale_df)

    retail_output = output_dir / "retail_account_sales_quarterly_extract.csv"
    wholesale_output = output_dir / "wholesale_account_sales_quarterly_extract.csv"
    finance_output = output_dir / "finance_quarterly_actuals.csv"

    retail_df.to_csv(retail_output, index=False)
    wholesale_df.to_csv(wholesale_output, index=False)
    finance_df.to_csv(finance_output, index=False)

    inventory_df = generate_inventory_quarterly()
    inventory_output = output_dir / "inventory_quarterly_extract.csv"
    inventory_df.to_csv(inventory_output, index=False)

    inventory_df = generate_inventory_quarterly()
    trade_adjustments_df = generate_trade_adjustments()

    inventory_output = output_dir / "inventory_quarterly_extract.csv"
    trade_adjustments_output = output_dir / "trade_adjustments_extract.csv"

    inventory_df.to_csv(inventory_output, index=False)
    trade_adjustments_df.to_csv(trade_adjustments_output, index=False)

    print(f"Created: {retail_output}")
    print(f"Rows written: {len(retail_df)}")

    print(f"Created: {wholesale_output}")
    print(f"Rows written: {len(wholesale_df)}")

    print(f"Created: {finance_output}")
    print(f"Rows written: {len(finance_df)}")

    print(f"Created: {inventory_output}")
    print(f"Rows written: {len(inventory_df)}")

    print(f"Created: {inventory_output}")
    print(f"Rows written: {len(inventory_df)}")

    print(f"Created: {trade_adjustments_output}")
    print(f"Rows written: {len(trade_adjustments_df)}")

    retail_total = retail_df['net_sales'].sum()
    wholesale_total = wholesale_df['net_sales'].sum()
    finance_revenue_total = finance_df.loc[
        finance_df['reporting_category'] == 'net_revenue',
        'actual_amount'
    ].sum()

    print("")
    print(f"Retail net sales total: {retail_total:.2f}")
    print(f"Wholesale net sales total: {wholesale_total:.2f}")
    print(f"Operational net sales total: {retail_total + wholesale_total:.2f}")
    print(f"Finance net revenue total: {finance_revenue_total:.2f}")


if __name__ == "__main__":
    main()