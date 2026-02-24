-- Customer/Account Concentration (Top 10 accounts share)
WITH acct_sales AS (
  SELECT
    d.month_start_date,
    l.location_name AS account_name,
    l.region,
    SUM(s.net_sales_amount) AS net_sales
  FROM fact_sales s
  JOIN dim_date d      ON s.date_key = d.date_key
  JOIN dim_location l  ON s.location_key = l.location_key
  JOIN dim_product p   ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2,3
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY month_start_date ORDER BY net_sales DESC) AS rn,
    SUM(net_sales) OVER (PARTITION BY month_start_date) AS total_month_sales
  FROM acct_sales
)
SELECT
  month_start_date,
  SUM(CASE WHEN rn <= 10 THEN net_sales ELSE 0 END) AS top_10_sales,
  MAX(total_month_sales) AS total_month_sales,
  ROUND(
    SUM(CASE WHEN rn <= 10 THEN net_sales ELSE 0 END)::numeric / NULLIF(MAX(total_month_sales),0),
    4
  ) AS top_10_concentration_pct
FROM ranked
GROUP BY month_start_date
ORDER BY month_start_date;
