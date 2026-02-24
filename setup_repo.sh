#!/usr/bin/env bash
set -euo pipefail

# Wyld Bootstrap: Business Analyst Repo
# Usage:
#   bash setup_repo.sh
#   bash setup_repo.sh --skip-venv
#   bash setup_repo.sh --venv-name .venv

VENV_NAME=".venv"
SKIP_VENV="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-venv)
      SKIP_VENV="true"
      shift
      ;;
    --venv-name)
      VENV_NAME="${2:-.venv}"
      shift 2
      ;;
    -h|--help)
      echo "Usage: bash setup_repo.sh [--skip-venv] [--venv-name NAME]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "==> Bootstrapping repo in: $REPO_ROOT"

# NOTE: fails if the file isn’t there:
if [[ ! -f "README.md" ]]; then
  echo "WARNING: README.md not found. Make sure you're in the repo root."
fi

# NOTE: fails if the folder isn’t there:
# if [[ ! -d "1_ops_command_center" ]]; then
#   echo "ERROR: 1_ops_command_center/ not found."
#   echo "Run this script from the wyld-business-analyst repo root."
#   exit 1
# fi

echo "==> Creating standard directories..."

# shared folders
mkdir -p docs/screenshots
mkdir -p shared/semantic_model shared/data_governance shared/reporting_ops shared/sql_patterns shared/seeds
mkdir -p scripts
mkdir -p environment/sql/postgres environment/sql/duckdb environment/powerbi environment/setup
mkdir -p data/reference data/sample data/raw

# individual project folders
P1="01_ops_command_center"
P2="02_quarterly_dc_qaqc_system"
P3="03_forecasting_variance_story"
P4="04_ghg_scope_reporting"

# project folders
mkdir -p "$P1"/data/{seeds,source_extracts/{sales,ops,people,finance},standardized,modeled,exceptions,sample,raw}
mkdir -p "$P1"/sql/{staging,conformance,marts,validation}
mkdir -p "$P1"/powerbi/{semantic_model,report_pages,exports}
mkdir -p "$P1"/docs
mkdir -p "$P1"/reports/{executive_decks,ad_hoc_requests,scheduled_exports}

mkdir -p "$P2"/data/{source_extracts/{sales,finance,operations,people},standardized,exceptions,dq_runs,sample,raw}
mkdir -p "$P2"/sql/{staging,dq_rules,marts,validation}
mkdir -p "$P2"/powerbi/{semantic_model,report_pages}
mkdir -p "$P2"/docs
mkdir -p "$P2"/reports/{exceptions_reports,reconciliation_templates,executive_decks}

mkdir -p "$P3"/data/{source_extracts,modeled,forecast_outputs,sample,raw}
mkdir -p "$P3"/sql/{staging,marts,validation}
mkdir -p "$P3"/python
mkdir -p "$P3"/notebooks
mkdir -p "$P3"/powerbi/{semantic_model,report_pages}
mkdir -p "$P3"/docs
mkdir -p "$P3"/reports/{executive_decks,scheduled_exports,ad_hoc_requests}

mkdir -p "$P4"/data/{source_extracts/{utilities,fuel,shipping,packaging,finance_support},factors,modeled,assurance_pack,sample,raw}
mkdir -p "$P4"/sql/{staging,conformance,marts,validation}
mkdir -p "$P4"/powerbi/{semantic_model,report_pages}
mkdir -p "$P4"/docs
mkdir -p "$P4"/reports/{executive_decks,assurance_exports,scheduled_exports}

if [[ -f ".env.example" && ! -f ".env" ]]; then
  echo "==> Creating .env from .env.example"
  cp .env.example .env
elif [[ ! -f ".env.example" ]]; then
  cat > .env.example <<'EOF'
PYTHONUNBUFFERED=1
# DBT_PROFILES_DIR=./.dbt
# POSTGRES_HOST=localhost
# POSTGRES_PORT=5432
# POSTGRES_DB=wyld_sim
# POSTGRES_USER=postgres
# POSTGRES_PASSWORD=postgres
EOF
  echo "==> Created starter .env.example"
fi

if [[ "$SKIP_VENV" == "false" ]]; then
  echo "==> Setting up Python virtual environment: $VENV_NAME"

  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
  else
    echo "ERROR: Python not found."
    exit 1
  fi

  if [[ ! -d "$VENV_NAME" ]]; then
    "$PYTHON_BIN" -m venv "$VENV_NAME"
    echo "==> Created virtual environment"
  else
    echo "==> Virtual environment already exists"
  fi

  # shellcheck disable=SC1090
  source "$VENV_NAME/bin/activate"
  python -m pip install --upgrade pip setuptools wheel

  if [[ -f "requirements.txt" ]]; then
    echo "==> Installing requirements.txt"
    pip install -r requirements.txt
  else
    echo "==> No requirements.txt found (skipping pip install)"
  fi
else
  echo "==> Skipping virtual environment setup (--skip-venv)"
fi

if [[ ! -f "scripts/README.md" ]]; then
  cat > scripts/README.md <<'EOF'
# Scripts

Utility scripts for data generation, loading, QA checks, and exports.

## Usage
Run scripts from the repo root:

```bash
python scripts/generate_project1_data.py
```
EOF
fi

if [[ ! -f "environment/setup/setup_instructions.md" ]]; then
  cat > environment/setup/setup_instructions.md <<'EOF'
# Setup Instructions

1. Run `bash setup_repo.sh`
2. Activate venv: `source .venv/bin/activate`
3. Generate sample data for Project 1:
   - `python scripts/generate_project1_data.py`
4. Load generated CSVs into DuckDB/Postgres (optional)
5. Build SQL marts and connect Power BI to modeled outputs
EOF
fi

echo
echo "✅ Repo bootstrap complete."
echo "Next commands to run:"
echo "  source $VENV_NAME/bin/activate"
echo "  python scripts/generate_project1_data.py"
echo
echo "Power BI note: Power BI Desktop is Windows-only. On Mac, develop the SQL/data/docs and publish/open in Power BI Service."
