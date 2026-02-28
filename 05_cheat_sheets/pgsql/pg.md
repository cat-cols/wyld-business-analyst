# Drop schema
psql "$PROJECT1_PG_DSN" -c "drop schema if exists stg cascade;"

# Drop table
psql "$PROJECT1_PG_DSN" -c "drop table if exists raw.sales_distributor_extract cascade;"