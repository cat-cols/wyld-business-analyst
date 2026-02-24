-- Product Mix Analysis (Revenue, Unit, Margin mix)
WITH mix AS (
  SELECT
    d.month_start_date,
    p.cannabinoid_family,
    p.flavor,
    SUM(s.units_sold) AS units_sold,
    SUM(s.net_sales_amount) AS net_sales,
    SUM(s.net_sales_amount - s.cogs_amount) AS gross_margin_dollars
  FROM fact_sales s
  JOIN dim_date d      ON s.date_key = d.date_key
  JOIN dim_product p   ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2,3
),
totals AS (
  SELECT
    month_start_date,
    SUM(units_sold) AS total_units,
    SUM(net_sales) AS total_net_sales,
    SUM(gross_margin_dollars) AS total_margin
  FROM mix
  GROUP BY 1
)
SELECT
  m.month_start_date,
  m.cannabinoid_family,
  m.flavor,
  m.units_sold,
  m.net_sales,
  m.gross_margin_dollars,
  ROUND(m.units_sold::numeric / NULLIF(t.total_units,0), 4) AS unit_mix_pct,
  ROUND(m.net_sales::numeric / NULLIF(t.total_net_sales,0), 4) AS revenue_mix_pct,
  ROUND(m.gross_margin_dollars::numeric / NULLIF(t.total_margin,0), 4) AS margin_mix_pct
FROM mix m
JOIN totals t
  ON m.month_start_date = t.month_start_date
ORDER BY m.month_start_date, m.net_sales DESC;
