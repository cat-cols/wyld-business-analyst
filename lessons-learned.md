1. the dependency lesson: drop_and_create can’t drop raw tables if staging views exist.

So do this EVERY TIME you rebuild raw
```bash
psql "$PROJECT1_PG_DSN" -c "drop schema if exists stg cascade;"


python3 scripts/generate_project1_data.py \
  --pg-dsn "$PROJECT1_PG_DSN" \
  --pg-schema raw \
  --pg-ddl-mode drop_and_create \
  --pg-load-mode truncate_then_append \
  --base 01_ops_command_center

./scripts/run_staging.sh --base 01_ops_command_center
```