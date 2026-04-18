# Scripts

Utility scripts for data generation, loading, QA checks, and exports.

## Usage
Run scripts from the repo root:

```bash
python scripts/generate_project1_data.py
```

# SQLite (default)
python scripts/generate_project1_data.py --start 2024-01-01 --end 2025-12-31

# Postgres
python scripts/generate_project1_data.py --pg-dsn "$PROJECT1_PG_DSN"