-- Forecast Accuracy (requires fact_forecast table)
-- Assumes fact_forecast(date_key, product_key, location_key, forecast_units)

WITH actuals AS (
  SELECT
    d.week_start_date,
    s.product_key,
    s.location_key,
    SUM(s.units_sold) AS actual_units
  FROM fact_sales s
  JOIN dim_date d    ON s.date_key = d.date_key
  JOIN dim_product p ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2,3
),
fcst AS (
  SELECT
    d.week_start_date,
    f.product_key,
    f.location_key,
    SUM(f.forecast_units) AS forecast_units
  FROM fact_forecast f
  JOIN dim_date d ON f.date_key = d.date_key
  GROUP BY 1,2,3
)
SELECT
  a.week_start_date,
  SUM(a.actual_units) AS actual_units,
  SUM(COALESCE(f.forecast_units,0)) AS forecast_units,
  SUM(ABS(a.actual_units - COALESCE(f.forecast_units,0))) AS abs_error_units,
  ROUND(
    SUM(ABS(a.actual_units - COALESCE(f.forecast_units,0)))::numeric /
    NULLIF(SUM(a.actual_units), 0),
    4
  ) AS wape,
  ROUND(
    SUM((a.actual_units - COALESCE(f.forecast_units,0)))::numeric /
    NULLIF(SUM(a.actual_units), 0),
    4
  ) AS forecast_bias_pct
FROM actuals a
LEFT JOIN fcst f
  ON a.week_start_date = f.week_start_date
 AND a.product_key = f.product_key
 AND a.location_key = f.location_key
GROUP BY 1
ORDER BY 1;
