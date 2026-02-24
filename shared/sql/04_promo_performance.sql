-- Promo Performance (Promo Penetration + Promo Lift proxy)
WITH by_store_week AS (
  SELECT
    d.week_start_date,
    l.location_key,
    l.state,
    p.product_name,
    MAX(CASE WHEN s.promo_flag = 1 THEN 1 ELSE 0 END) AS any_promo,
    SUM(s.units_sold) AS units_sold
  FROM fact_sales s
  JOIN dim_date d      ON s.date_key = d.date_key
  JOIN dim_location l  ON s.location_key = l.location_key
  JOIN dim_product p   ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2,3,4
),
summary AS (
  SELECT
    week_start_date,
    state,
    product_name,
    SUM(CASE WHEN any_promo = 1 THEN units_sold ELSE 0 END) AS promo_units,
    SUM(CASE WHEN any_promo = 0 THEN units_sold ELSE 0 END) AS nonpromo_units,
    COUNT(DISTINCT CASE WHEN any_promo = 1 THEN location_key END) AS promo_locations,
    COUNT(DISTINCT CASE WHEN any_promo = 0 THEN location_key END) AS nonpromo_locations
  FROM by_store_week
  GROUP BY 1,2,3
)
SELECT
  week_start_date,
  state,
  product_name,
  promo_units,
  nonpromo_units,
  ROUND(promo_units::numeric / NULLIF(promo_units + nonpromo_units, 0), 4) AS promo_penetration_pct,
  ROUND(promo_units::numeric / NULLIF(promo_locations, 0), 2) AS promo_ros_units_per_store,
  ROUND(nonpromo_units::numeric / NULLIF(nonpromo_locations, 0), 2) AS nonpromo_ros_units_per_store,
  ROUND(
    (
      (promo_units::numeric / NULLIF(promo_locations, 0)) -
      (nonpromo_units::numeric / NULLIF(nonpromo_locations, 0))
    ) / NULLIF((nonpromo_units::numeric / NULLIF(nonpromo_locations, 0)), 0),
    4
  ) AS promo_lift_pct
FROM summary
ORDER BY week_start_date, state, product_name;
