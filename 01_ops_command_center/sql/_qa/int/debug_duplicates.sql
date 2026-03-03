-- Run this to check for duplicates

-- If qa fails, here are fast “show me the offenders” queries
-- psql "$PROJECT1_PG_DSN" -v ON_ERROR_STOP=1 -f 01_ops_command_center/sql/_qa/_run_qa.sql

-- dispensary duplicates
select store_code, count(*)
from int.int_dispensary_latest
group by 1
having count(*) > 1;

-- account status duplicates
select store_code, count(*)
from int.int_account_status_current
group by 1
having count(*) > 1;

-- sales dedup duplicates at grain
select sale_date, store_code, sku, channel, count(*)
from int.int_sales_distributor_dedup
group by 1,2,3,4
having count(*) > 1;

-- punches duplicates by punch_id
select punch_id, count(*)
from int.int_timeclock_punches_latest
where punch_id is not null
group by 1
having count(*) > 1;

-- punches duplicates by punch_key
select
  coalesce(punch_id::text, store_code || '|' || employee_id || '|' || clock_in_at::text) as punch_key,
  count(*)
from int.int_timeclock_punches_latest
group by 1
having count(*) > 1;

where should I store these sql checks