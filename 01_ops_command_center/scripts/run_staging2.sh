#!/usr/bin/env bash
# scripts/run_phase2_staging.sh
#
# Runs Phase 2 staging SQL (non-dbt) in Postgres:
# - ensures stg schema exists
# - creates/replaces all stg.* views
# - runs QA checks
#
# Usage:
#   PROJECT1_PG_DSN="postgresql://user:pass@host:5432/db" ./scripts/run_phase2_staging.sh
#   ./scripts/run_phase2_staging.sh "postgresql://user:pass@host:5432/db"
#   ./scripts/run_phase2_staging.sh --no-qa
#   ./scripts/run_phase2_staging.sh --dsn "postgresql://..."

set -euo pipefail

# -------------------------
# Args
# -------------------------
DSN="${PROJECT1_PG_DSN:-}"
RUN_QA=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dsn)
      DSN="${2:-}"
      shift 2
      ;;
    --no-qa)
      RUN_QA=0
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  scripts/run_staging.sh [--dsn <POSTGRES_DSN>] [--no-qa]

Examples:
  PROJECT1_PG_DSN="postgresql://user:pass@host:5432/db" ./scripts/run_phase2_staging.sh
  ./scripts/run_staging.sh --dsn "postgresql://user:pass@host:5432/db"
  ./scripts/run_staging.sh --no-qa
EOF
      exit 0
      ;;
    *)
      # If a positional DSN is provided, use it
      if [[ -z "$DSN" && "$1" == postgresql://* ]]; then
        DSN="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        exit 2
      fi
      ;;
  esac
done

if [[ -z "${DSN// }" ]]; then
  echo "ERROR: Postgres DSN missing. Set PROJECT1_PG_DSN or pass --dsn." >&2
  exit 2
fi

# -------------------------
# Paths (repo-root relative)
# -------------------------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$ROOT/01_ops_command_center/sql/staging"
QA_FILE="$ROOT/01_ops_command_center/sql/staging/checks/qa_checks.sql"

# List your staging SQL files here (in the order you want them applied)
STAGING_FILES=(
  "$SQL_DIR/stg_sales_distributor.sql"
  "$SQL_DIR/stg_inventory_erp.sql"
  "$SQL_DIR/stg_labor_payroll.sql"
  "$SQL_DIR/stg_finance_actuals.sql"
  "$SQL_DIR/stg_account_status.sql"
  "$SQL_DIR/stg_dispensary_master.sql"
  "$SQL_DIR/stg_sku_distribution_status.sql"
)

# -------------------------
# Helpers
# -------------------------
psql_run() {
  local file="$1"
  echo "==> Running: ${file#$ROOT/}"
  psql "$DSN" \
    -v ON_ERROR_STOP=1 \
    -v VERBOSITY=terse \
    -f "$file"
}

# -------------------------
# Run
# -------------------------
echo "✅ Phase 2 staging runner"
echo "   DSN: (provided)"
echo "   Root: $ROOT"
echo

echo "==> Ensuring schema stg exists"
psql "$DSN" -v ON_ERROR_STOP=1 -v VERBOSITY=terse -c "create schema if not exists stg;"

echo
echo "==> Applying staging models"
for f in "${STAGING_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Missing file: ${f#$ROOT/}" >&2
    exit 3
  fi
  psql_run "$f"
done

if [[ "$RUN_QA" -eq 1 ]]; then
  echo
  echo "==> Running QA checks"
  if [[ ! -f "$QA_FILE" ]]; then
    echo "ERROR: Missing QA file: ${QA_FILE#$ROOT/}" >&2
    exit 3
  fi
  psql_run "$QA_FILE"
else
  echo
  echo "==> Skipping QA checks (--no-qa)"
fi

echo
echo "🎉 Done. Staging models applied."