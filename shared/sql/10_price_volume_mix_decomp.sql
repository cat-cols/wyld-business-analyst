-- Price / Volume / Mix decomposition (month-over-month)
WITH sku_month AS (
  SELECT
    d.month_start_date,
    s.product_key,
    SUM(s.units_sold) AS units,
    SUM(s.net_sales_amount) AS net_sales,
    CASE WHEN SUM(s.units_sold) = 0 THEN NULL
         ELSE SUM(s.net_sales_amount)::numeric / SUM(s.units_sold)
    END AS net_price
  FROM fact_sales s
  JOIN dim_date d    ON s.date_key = d.date_key
  JOIN dim_product p ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2
),
curr_prev AS (
  SELECT
    c.month_start_date,
    c.product_key,
    c.units AS curr_units,
    c.net_sales AS curr_sales,
    c.net_price AS curr_price,
    p.units AS prev_units,
    p.net_sales AS prev_sales,
    p.net_price AS prev_price
  FROM sku_month c
  LEFT JOIN sku_month p
    ON p.product_key = c.product_key
   AND p.month_start_date = c.month_start_date - INTERVAL '1 month'
),
decomp AS (
  SELECT
    month_start_date,
    product_key,
    COALESCE(curr_sales,0) - COALESCE(prev_sales,0) AS revenue_variance,
    COALESCE(prev_units,0) * (COALESCE(curr_price,0) - COALESCE(prev_price,0)) AS price_effect,
    COALESCE(prev_price,0) * (COALESCE(curr_units,0) - COALESCE(prev_units,0)) AS volume_effect
  FROM curr_prev
)
SELECT
  month_start_date,
  SUM(revenue_variance) AS revenue_variance,
  SUM(price_effect) AS price_effect,
  SUM(volume_effect) AS volume_effect,
  SUM(revenue_variance) - SUM(price_effect) - SUM(volume_effect) AS mix_effect
FROM decomp
GROUP BY 1
ORDER BY 1;
