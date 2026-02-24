-- Wyld KPI Executive Summary (Monthly / State / Channel)
-- Assumes PostgreSQL-compatible SQL. Rename columns as needed.

WITH sales_base AS (
  SELECT
    d.month_start_date,
    l.state,
    c.channel_name,
    SUM(s.units_sold) AS units_sold,
    SUM(s.gross_sales_amount) AS gross_sales,
    SUM(s.net_sales_amount) AS net_sales,
    SUM(s.cogs_amount) AS cogs
  FROM fact_sales s
  JOIN dim_date d      ON s.date_key = d.date_key
  JOIN dim_location l  ON s.location_key = l.location_key
  JOIN dim_channel c   ON s.channel_key = c.channel_key
  JOIN dim_product p   ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2,3
)
SELECT
  month_start_date,
  state,
  channel_name,
  units_sold,
  gross_sales,
  net_sales,
  cogs,
  (net_sales - cogs) AS gross_margin_dollars,
  CASE WHEN net_sales = 0 THEN NULL ELSE (net_sales - cogs)::numeric / net_sales END AS gross_margin_pct,
  CASE WHEN units_sold = 0 THEN NULL ELSE gross_sales::numeric / units_sold END AS gross_vwap,
  CASE WHEN units_sold = 0 THEN NULL ELSE net_sales::numeric / units_sold END AS net_vwap,
  CASE WHEN gross_sales = 0 THEN NULL ELSE (gross_sales - net_sales)::numeric / gross_sales END AS discount_rate
FROM sales_base
ORDER BY month_start_date, state, channel_name;
