-- Account Retention (monthly)
WITH monthly_active AS (
  SELECT DISTINCT
    d.month_start_date,
    s.location_key
  FROM fact_sales s
  JOIN dim_date d    ON s.date_key = d.date_key
  JOIN dim_product p ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
    AND s.units_sold > 0
),
retention AS (
  SELECT
    cur.month_start_date,
    COUNT(DISTINCT cur.location_key) AS active_accounts_current,
    COUNT(DISTINCT prev.location_key) AS retained_accounts
  FROM monthly_active cur
  LEFT JOIN monthly_active prev
    ON prev.location_key = cur.location_key
   AND prev.month_start_date = cur.month_start_date - INTERVAL '1 month'
  GROUP BY 1
),
prior_active AS (
  SELECT
    month_start_date + INTERVAL '1 month' AS month_start_date,
    COUNT(DISTINCT location_key) AS active_accounts_prior
  FROM monthly_active
  GROUP BY 1
)
SELECT
  r.month_start_date,
  r.active_accounts_current,
  COALESCE(p.active_accounts_prior,0) AS active_accounts_prior,
  r.retained_accounts,
  ROUND(r.retained_accounts::numeric / NULLIF(p.active_accounts_prior,0), 4) AS account_retention_pct
FROM retention r
LEFT JOIN prior_active p
  ON r.month_start_date = p.month_start_date
ORDER BY r.month_start_date;
