#!/usr/bin/env bash
# scripts/run_staging.sh
#
# Runs Phase 2 staging SQL (non-dbt) in Postgres.
# Defaults to staging SQL under: <repo>/01_ops_command_center/sql/staging
# QA file default: <repo>/01_ops_command_center/docs/qa_checks.sql (fallback: <repo>/docs/qa_phase2_checks.sql)
#
# Usage:
#   PROJECT1_PG_DSN="postgresql://user:pass@host:5432/db" ./scripts/run_staging.sh
#   ./scripts/run_staging.sh --dsn "postgresql://user:pass@host:5432/db]"
#   ./scripts/run_staging.sh --base 01_ops_command_center
#   ./scripts/run_staging.sh --sql-dir "/abs/path/sql/staging" --qa-file "/abs/path/qa.sql"
#   ./scripts/run_staging.sh --no-qa

set -euo pipefail

DSN="${PROJECT1_PG_DSN:-}"
RUN_QA=1
BASE_DIR="${PROJECT1_BASE_DIR:-01_ops_command_center}"
SQL_DIR_OVERRIDE=""
QA_FILE_OVERRIDE=""

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
    --base)
      BASE_DIR="${2:-}"
      shift 2
      ;;
    --sql-dir)
      SQL_DIR_OVERRIDE="${2:-}"
      shift 2
      ;;
    --qa-file)
      QA_FILE_OVERRIDE="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  scripts/run_staging.sh [--dsn <POSTGRES_DSN>] [--no-qa]
                         [--base <subdir>] [--sql-dir <path>] [--qa-file <path>]

Defaults:
  --base 01_ops_command_center
  SQL files: <repo>/<base>/sql/staging
  QA file:   <repo>/<base>/docs/qa_phase2_checks.sql (fallback: <repo>/docs/qa_phase2_checks.sql)

Examples:
  PROJECT1_PG_DSN="postgresql://..." ./scripts/run_staging.sh
  ./scripts/run_staging.sh --dsn "postgresql://..." --base 01_ops_command_center
  ./scripts/run_staging.sh --sql-dir "/abs/path/sql/staging" --qa-file "/abs/path/qa.sql"
  ./scripts/run_staging.sh --no-qa
EOF
      exit 0
      ;;
    *)
      # allow positional DSN as first arg
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

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SQL_DIR="${SQL_DIR_OVERRIDE:-$ROOT/$BASE_DIR/sql/staging}"

# Prefer QA inside base/sql/staging/checks, then base/docs, then repo/docs
QA_CANDIDATE_1="$ROOT/$BASE_DIR/sql/staging/checks/qa_checks.sql"
QA_CANDIDATE_2="$ROOT/$BASE_DIR/docs/qa_checks.sql"
QA_CANDIDATE_3="$ROOT/docs/qa_checks.sql"

if [[ -n "$QA_FILE_OVERRIDE" ]]; then
  QA_FILE="$QA_FILE_OVERRIDE"
elif [[ -f "$QA_CANDIDATE_1" ]]; then
  QA_FILE="$QA_CANDIDATE_1"
elif [[ -f "$QA_CANDIDATE_2" ]]; then
  QA_FILE="$QA_CANDIDATE_2"
else
  QA_FILE="$QA_CANDIDATE_3"
fi

STAGING_FILES=(
  "$SQL_DIR/stg_sales_distributor.sql"
  "$SQL_DIR/stg_inventory_erp.sql"
  "$SQL_DIR/stg_labor_payroll.sql"
  "$SQL_DIR/stg_finance_actuals.sql"
  "$SQL_DIR/stg_account_status.sql"
  "$SQL_DIR/stg_dispensary_master.sql"
  "$SQL_DIR/stg_sku_distribution_status.sql"
)

psql_run() {
  local file="$1"
  echo "==> Running: ${file#$ROOT/}"
  psql "$DSN" -v ON_ERROR_STOP=1 -v VERBOSITY=terse -f "$file"
}

echo "✅ Phase 2 staging runner"
echo "   Root: $ROOT"
echo "   SQL_DIR: $SQL_DIR"
echo "   QA_FILE: $QA_FILE"
echo

echo "==> Ensuring schema stg exists"
psql "$DSN" -v ON_ERROR_STOP=1 -v VERBOSITY=terse -c "create schema if not exists stg;"

echo
echo "==> Applying staging models"
for f in "${STAGING_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Missing file: $f" >&2
    exit 3
  fi
  psql_run "$f"
done

if [[ "$RUN_QA" -eq 1 ]]; then
  echo
  echo "==> Running QA checks"
  if [[ ! -f "$QA_FILE" ]]; then
    echo "ERROR: Missing QA file: $QA_FILE" >&2
    exit 3
  fi
  psql_run "$QA_FILE"
else
  echo
  echo "==> Skipping QA checks (--no-qa)"
fi

echo
echo "🎉 Done. Staging models applied."