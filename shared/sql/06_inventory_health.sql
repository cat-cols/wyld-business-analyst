-- Inventory Health (DOH, Turnover proxy, In-Stock %, Stockout Rate)
WITH inv AS (
  SELECT
    d.month_start_date,
    i.product_key,
    i.location_key,
    AVG(i.on_hand_units) AS avg_on_hand_units,
    AVG(
      CASE
        WHEN i.in_stock_flag IS NOT NULL THEN i.in_stock_flag::numeric
        WHEN i.on_hand_units > 0 THEN 1
        ELSE 0
      END
    ) AS in_stock_pct
  FROM fact_inventory i
  JOIN dim_date d ON i.date_key = d.date_key
  GROUP BY 1,2,3
),
sales AS (
  SELECT
    d.month_start_date,
    s.product_key,
    s.location_key,
    SUM(s.units_sold) AS units_sold
  FROM fact_sales s
  JOIN dim_date d ON s.date_key = d.date_key
  GROUP BY 1,2,3
)
SELECT
  inv.month_start_date,
  l.state,
  p.product_name,
  AVG(inv.avg_on_hand_units) AS avg_on_hand_units,
  SUM(COALESCE(sales.units_sold,0)) AS units_sold,
  AVG(inv.in_stock_pct) AS in_stock_pct,
  1 - AVG(inv.in_stock_pct) AS stockout_rate,
  CASE WHEN SUM(COALESCE(sales.units_sold,0)) = 0 THEN NULL
       ELSE AVG(inv.avg_on_hand_units) /
            (SUM(sales.units_sold)::numeric /
             NULLIF(EXTRACT(DAY FROM (inv.month_start_date + INTERVAL '1 month - 1 day')),0))
  END AS approx_days_on_hand,
  CASE WHEN AVG(inv.avg_on_hand_units) = 0 THEN NULL
       ELSE SUM(COALESCE(sales.units_sold,0))::numeric / AVG(inv.avg_on_hand_units)
  END AS inventory_turnover_units
FROM inv
LEFT JOIN sales
  ON sales.month_start_date = inv.month_start_date
 AND sales.product_key = inv.product_key
 AND sales.location_key = inv.location_key
JOIN dim_product p ON inv.product_key = p.product_key
JOIN dim_location l ON inv.location_key = l.location_key
WHERE p.brand_name = 'Wyld'
GROUP BY inv.month_start_date, l.state, p.product_name
ORDER BY inv.month_start_date, l.state, p.product_name;
