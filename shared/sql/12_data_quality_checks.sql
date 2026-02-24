-- Data Quality / Sanity checks for fact_sales
SELECT
  COUNT(*) AS rows_checked,
  SUM(CASE WHEN units_sold < 0 THEN 1 ELSE 0 END) AS negative_units_rows,
  SUM(CASE WHEN net_sales_amount < 0 THEN 1 ELSE 0 END) AS negative_net_sales_rows,
  SUM(CASE WHEN gross_sales_amount < net_sales_amount THEN 1 ELSE 0 END) AS gross_less_than_net_rows,
  SUM(CASE WHEN cogs_amount < 0 THEN 1 ELSE 0 END) AS negative_cogs_rows,
  SUM(CASE WHEN units_sold = 0 AND net_sales_amount <> 0 THEN 1 ELSE 0 END) AS zero_units_nonzero_sales_rows
FROM fact_sales;
