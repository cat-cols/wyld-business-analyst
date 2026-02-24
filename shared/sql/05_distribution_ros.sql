-- Distribution + Rate of Sale (ROS)
WITH ros AS (
  SELECT
    d.week_start_date,
    l.state,
    p.product_name,
    COUNT(DISTINCT CASE WHEN s.units_sold > 0 THEN s.location_key END) AS active_doors,
    SUM(s.units_sold) AS units_sold
  FROM fact_sales s
  JOIN dim_date d      ON s.date_key = d.date_key
  JOIN dim_location l  ON s.location_key = l.location_key
  JOIN dim_product p   ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2,3
)
SELECT
  week_start_date,
  state,
  product_name,
  active_doors,
  units_sold,
  ROUND(units_sold::numeric / NULLIF(active_doors, 0), 2) AS rate_of_sale_units_per_active_door
FROM ros
ORDER BY week_start_date, state, units_sold DESC;
