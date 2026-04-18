#!/usr/bin/env bash
# scripts/rebuild_project1.sh
#
# One-command rebuild of Project 1:
#   1) DROP stg schema (optional) + DROP raw schema (optional)
#   2) Regenerate raw tables + file drops via scripts/generate_project1_data.py
#   3) Rebuild staging views via scripts/run_staging.sh (optionally run QA)
#
# Usage:
#   PROJECT1_PG_DSN="postgresql://..." ./scripts/rebuild_project1.sh --yes
#   ./scripts/rebuild_project1.sh --dsn "postgresql://..." --base 01_ops_command_center --yes
#   ./scripts/rebuild_project1.sh --yes --no-qa
#   ./scripts/rebuild_project1.sh --yes --keep-raw      # don't drop raw schema
#   ./scripts/rebuild_project1.sh --yes --keep-stg      # don't drop stg schema
#
set -euo pipefail

DSN="${PROJECT1_PG_DSN:-}"
BASE_DIR="${PROJECT1_BASE_DIR:-01_ops_command_center}"
RAW_SCHEMA="${PROJECT1_PG_SCHEMA:-raw}"

DROP_RAW=1
DROP_STG=1
RUN_QA=1
YES=0

# Optional passthroughs to generate_project1_data.py
GEN_START=""
GEN_END=""
GEN_SEED=""
GEN_STORES=""
GEN_PRODUCTS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dsn)
      DSN="${2:-}"
      shift 2
      ;;
    --base)
      BASE_DIR="${2:-}"
      shift 2
      ;;
    --raw-schema)
      RAW_SCHEMA="${2:-}"
      shift 2
      ;;
    --keep-raw)
      DROP_RAW=0
      shift
      ;;
    --keep-stg)
      DROP_STG=0
      shift
      ;;
    --no-qa)
      RUN_QA=0
      shift
      ;;
    --yes)
      YES=1
      shift
      ;;
    --start)
      GEN_START="${2:-}"
      shift 2
      ;;
    --end)
      GEN_END="${2:-}"
      shift 2
      ;;
    --seed)
      GEN_SEED="${2:-}"
      shift 2
      ;;
    --stores)
      GEN_STORES="${2:-}"
      shift 2
      ;;
    --products)
      GEN_PRODUCTS="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  scripts/rebuild_project1.sh --yes [options]

Required:
  --yes              Acknowledge destructive steps (drops schemas).

Options:
  --dsn <DSN>        Postgres DSN (or set PROJECT1_PG_DSN).
  --base <dir>       Base project dir (default: 01_ops_command_center).
  --raw-schema <s>   Raw schema name (default: raw, or PROJECT1_PG_SCHEMA).
  --keep-raw         Do NOT drop the raw schema.
  --keep-stg         Do NOT drop the stg schema.
  --no-qa            Skip QA checks in run_staging.sh.

Generator passthroughs (optional):
  --start YYYY-MM-DD
  --end   YYYY-MM-DD
  --seed  N
  --stores N
  --products N

Examples:
  PROJECT1_PG_DSN="postgresql://..." ./scripts/rebuild_project1.sh --yes
  ./scripts/rebuild_project1.sh --dsn "postgresql://..." --yes --no-qa
  ./scripts/rebuild_project1.sh --yes --start 2025-01-01 --end 2025-01-31 --stores 60
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "${DSN// }" ]]; then
  echo "ERROR: Postgres DSN missing. Set PROJECT1_PG_DSN or pass --dsn." >&2
  exit 2
fi

if [[ "$YES" -ne 1 ]]; then
  echo "ERROR: Refusing to run without --yes." >&2
  echo "This script may DROP schemas:"
  echo "  - stg (cascade)  [unless --keep-stg]"
  echo "  - ${RAW_SCHEMA} (cascade)  [unless --keep-raw]"
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "✅ Rebuild Project 1"
echo "   Root:       $ROOT"
echo "   Base:       $BASE_DIR"
echo "   DSN:        (provided)"
echo "   Raw schema: $RAW_SCHEMA"
echo "   Drop stg:   $DROP_STG"
echo "   Drop raw:   $DROP_RAW"
echo "   Run QA:     $RUN_QA"
echo

if [[ "$DROP_STG" -eq 1 ]]; then
  echo "==> Dropping schema stg (CASCADE)"
  psql "$DSN" -v ON_ERROR_STOP=1 -c "drop schema if exists stg cascade;"
  echo
fi

if [[ "$DROP_RAW" -eq 1 ]]; then
  echo "==> Dropping schema ${RAW_SCHEMA} (CASCADE)"
  psql "$DSN" -v ON_ERROR_STOP=1 -c "drop schema if exists ${RAW_SCHEMA} cascade;"
  echo
fi

echo "==> Generating + loading raw data"
GEN_ARGS=( "--pg-dsn" "$DSN" "--pg-schema" "$RAW_SCHEMA" "--pg-ddl-mode" "drop_and_create" "--pg-load-mode" "truncate_then_append" "--base" "$BASE_DIR" )

if [[ -n "${GEN_START// }" ]]; then GEN_ARGS+=( "--start" "$GEN_START" ); fi
if [[ -n "${GEN_END// }" ]]; then GEN_ARGS+=( "--end" "$GEN_END" ); fi
if [[ -n "${GEN_SEED// }" ]]; then GEN_ARGS+=( "--seed" "$GEN_SEED" ); fi
if [[ -n "${GEN_STORES// }" ]]; then GEN_ARGS+=( "--stores" "$GEN_STORES" ); fi
if [[ -n "${GEN_PRODUCTS// }" ]]; then GEN_ARGS+=( "--products" "$GEN_PRODUCTS" ); fi

python3 "$ROOT/scripts/generate_project1_data.py" "${GEN_ARGS[@]}"
echo

echo "==> Building staging views"
STG_ARGS=( "--dsn" "$DSN" "--base" "$BASE_DIR" )
if [[ "$DROP_STG" -eq 1 ]]; then
  STG_ARGS+=( "--reset-stg" )
fi
if [[ "$RUN_QA" -eq 0 ]]; then
  STG_ARGS+=( "--no-qa" )
fi

"$ROOT/scripts/run_staging.sh" "${STG_ARGS[@]}"
echo

echo "==> Quick rowcount sanity (raw vs stg)"
psql "$DSN" -v ON_ERROR_STOP=1 -c "
select 'raw.sales_distributor_extract' t, count(*) n from ${RAW_SCHEMA}.sales_distributor_extract union all
select 'raw.pos_transactions_csv', count(*) from ${RAW_SCHEMA}.pos_transactions_csv union all
select 'raw.inventory_erp_snapshot', count(*) from ${RAW_SCHEMA}.inventory_erp_snapshot union all
select 'raw.wms_shipments', count(*) from ${RAW_SCHEMA}.wms_shipments union all
select 'raw.timeclock_punches', count(*) from ${RAW_SCHEMA}.timeclock_punches union all
select 'raw.labor_hours_payroll_export', count(*) from ${RAW_SCHEMA}.labor_hours_payroll_export union all
select 'raw.finance_actuals_summary', count(*) from ${RAW_SCHEMA}.finance_actuals_summary union all
select 'raw.gl_detail_csv', count(*) from ${RAW_SCHEMA}.gl_detail_csv union all
select 'raw.account_status', count(*) from ${RAW_SCHEMA}.account_status union all
select 'raw.dispensary_master', count(*) from ${RAW_SCHEMA}.dispensary_master union all
select 'raw.sku_distribution_status', count(*) from ${RAW_SCHEMA}.sku_distribution_status
order by t;
"

psql "$DSN" -v ON_ERROR_STOP=1 -c "
select 'stg.stg_sales_distributor' t, count(*) n from stg.stg_sales_distributor union all
select 'stg.stg_inventory_erp', count(*) from stg.stg_inventory_erp union all
select 'stg.stg_labor_payroll', count(*) from stg.stg_labor_payroll union all
select 'stg.stg_finance_actuals', count(*) from stg.stg_finance_actuals union all
select 'stg.stg_account_status', count(*) from stg.stg_account_status union all
select 'stg.stg_dispensary_master', count(*) from stg.stg_dispensary_master union all
select 'stg.stg_sku_distribution_status', count(*) from stg.stg_sku_distribution_status
order by t;
"

echo
echo "🎉 Rebuild complete."