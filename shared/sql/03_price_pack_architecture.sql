-- Price Pack Architecture (Price/Pack, Revenue per mg THC)
SELECT
  d.month_start_date,
  l.state,
  p.product_name,
  p.cannabinoid_family,
  p.pack_size,
  p.thc_mg_per_pack,
  SUM(s.units_sold) AS units_sold,
  SUM(s.net_sales_amount) AS net_sales,
  SUM(s.net_sales_amount - s.cogs_amount) AS gross_margin_dollars,
  CASE WHEN SUM(s.units_sold) = 0 THEN NULL
       ELSE SUM(s.net_sales_amount)::numeric / SUM(s.units_sold)
  END AS net_price_per_pack,
  CASE WHEN SUM(s.units_sold * COALESCE(p.thc_mg_per_pack,0)) = 0 THEN NULL
       ELSE SUM(s.net_sales_amount)::numeric / SUM(s.units_sold * p.thc_mg_per_pack)
  END AS net_revenue_per_mg_thc,
  CASE WHEN SUM(s.units_sold * COALESCE(p.thc_mg_per_pack,0)) = 0 THEN NULL
       ELSE SUM(s.net_sales_amount - s.cogs_amount)::numeric / SUM(s.units_sold * p.thc_mg_per_pack)
  END AS margin_per_mg_thc
FROM fact_sales s
JOIN dim_date d      ON s.date_key = d.date_key
JOIN dim_product p   ON s.product_key = p.product_key
JOIN dim_location l  ON s.location_key = l.location_key
WHERE p.brand_name = 'Wyld'
GROUP BY 1,2,3,4,5,6
ORDER BY d.month_start_date, l.state, net_sales DESC;
