-- Sales + Labor Productivity
WITH sales_loc_day AS (
  SELECT
    s.date_key,
    s.location_key,
    SUM(s.net_sales_amount) AS net_sales,
    SUM(s.units_sold) AS units_sold,
    SUM(s.net_sales_amount - s.cogs_amount) AS gross_margin_dollars
  FROM fact_sales s
  JOIN dim_product p ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2
),
labor_loc_day AS (
  SELECT
    l.date_key,
    l.location_key,
    SUM(l.labor_hours) AS labor_hours,
    SUM(COALESCE(l.headcount,0)) AS headcount,
    SUM(COALESCE(l.labor_cost_amount,0)) AS labor_cost
  FROM fact_labor l
  GROUP BY 1,2
)
SELECT
  d.full_date,
  loc.state,
  loc.location_name,
  COALESCE(s.net_sales,0) AS net_sales,
  COALESCE(s.units_sold,0) AS units_sold,
  COALESCE(s.gross_margin_dollars,0) AS gross_margin_dollars,
  COALESCE(lb.labor_hours,0) AS labor_hours,
  COALESCE(lb.headcount,0) AS headcount,
  COALESCE(lb.labor_cost,0) AS labor_cost,
  CASE WHEN COALESCE(lb.labor_hours,0) = 0 THEN NULL ELSE s.net_sales::numeric / lb.labor_hours END AS revenue_per_labor_hour,
  CASE WHEN COALESCE(lb.labor_hours,0) = 0 THEN NULL ELSE s.units_sold::numeric / lb.labor_hours END AS units_per_labor_hour,
  CASE WHEN COALESCE(lb.labor_cost,0) = 0 THEN NULL ELSE s.gross_margin_dollars::numeric / lb.labor_cost END AS gross_margin_to_labor_cost_ratio
FROM dim_date d
JOIN dim_location loc ON 1=1
LEFT JOIN sales_loc_day s
  ON s.date_key = d.date_key
 AND s.location_key = loc.location_key
LEFT JOIN labor_loc_day lb
  ON lb.date_key = d.date_key
 AND lb.location_key = loc.location_key
WHERE d.full_date >= CURRENT_DATE - INTERVAL '90 day'
ORDER BY d.full_date, loc.state, loc.location_name;
