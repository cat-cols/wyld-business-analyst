#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# run_marts.sh
# Builds current mart layer models in dependency order.
# Requires: psql + PROJECT1_PG_DSN (or pass DSN as first arg)
# -----------------------------

# Resolve repo root assuming this script lives in <repo>/scripts/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# DSN priority: arg1 > env var
DSN="${1:-${PROJECT1_PG_DSN:-}}"

if [[ -z "${DSN}" ]]; then
  echo "ERROR: No DSN provided."
  echo "Usage:"
  echo "  PROJECT1_PG_DSN='postgresql://...' ./scripts/run_marts.sh"
  echo "  ./scripts/run_marts.sh 'postgresql://...'"
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql not found. Install Postgres client tools first."
  exit 1
fi

SQL_BASE="${REPO_ROOT}/01_ops_command_center/sql"

# List mart SQL files in dependency order
FILES=(
  "${SQL_BASE}/mart/core/dim_store.sql"
  "${SQL_BASE}/mart/sales/fact_sales_distributor_daily.sql"
  "${SQL_BASE}/mart/ops/fact_labor_daily.sql"
  "${SQL_BASE}/mart/ops/kpi_sales_per_labor_hour_daily.sql"
)

echo ""
echo "=============================="
echo " Running MART builds"
echo " Repo: ${REPO_ROOT}"
echo " DSN : (provided)"
echo "=============================="
echo ""

for f in "${FILES[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "ERROR: Missing file: ${f}"
    exit 1
  fi
  echo ">> psql -f ${f}"
  psql "${DSN}" -X -v ON_ERROR_STOP=1 -f "${f}"
  echo ""
done

echo "=============================="
echo " Quick sanity checks"
echo "=============================="

psql "${DSN}" -X -v ON_ERROR_STOP=1 <<'SQL'
-- basic rowcounts
select 'mart.dim_store' as model, count(*) as rows from mart.dim_store
union all
select 'mart.fact_sales_distributor_daily', count(*) from mart.fact_sales_distributor_daily
union all
select 'mart.fact_labor_daily', count(*) from mart.fact_labor_daily
union all
select 'mart.kpi_sales_per_labor_hour_daily', count(*) from mart.kpi_sales_per_labor_hour_daily
order by 1;

-- grain uniqueness (should return 0 rows)
select sale_date, store_code, sku, channel, count(*) as n
from mart.fact_sales_distributor_daily
group by 1,2,3,4
having count(*) > 1;

select work_date, store_code, count(*) as n
from mart.fact_labor_daily
group by 1,2
having count(*) > 1;

select kpi_date, store_code, count(*) as n
from mart.kpi_sales_per_labor_hour_daily
group by 1,2
having count(*) > 1;

-- key null checks (should be 0)
select count(*) as bad_sales_keys
from mart.fact_sales_distributor_daily
where sale_date is null or store_code is null or sku is null or channel is null;

select count(*) as bad_labor_keys
from mart.fact_labor_daily
where work_date is null or store_code is null;

select count(*) as kpi_rows_missing_labor
from mart.kpi_sales_per_labor_hour_daily
where hours_worked is null;
SQL

echo ""
echo "✅ MART build complete."