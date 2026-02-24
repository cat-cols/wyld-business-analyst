Love this schema. This is already thinking like an analytics engineer, which is exactly the lane you want.

Given your star schema, here’s a **Wyld-tailored SQL query pack** for a business analyst workflow: pricing, mix, inventory, labor productivity, and operational performance.

## Assumptions (important so the SQL doesn’t hallucinate)

I’ll assume these common columns exist (rename as needed):

### `fact_sales`

* `date_key`
* `product_key`
* `location_key`
* `channel_key`
* `units_sold`
* `gross_sales_amount`
* `net_sales_amount`
* `cogs_amount`
* `promo_flag` (0/1 or boolean)
* `order_count` *(optional, useful)*
* `customer_count` *(optional, useful)*

### `fact_inventory`

* `date_key`
* `product_key`
* `location_key`
* `on_hand_units`
* `received_units` *(optional)*
* `shipped_units` *(optional)*
* `in_stock_flag` (1/0) *(optional but great)*

### `fact_labor`

* `date_key`
* `location_key`
* `employee_group_key` *(optional)*
* `labor_hours`
* `headcount`
* `labor_cost_amount` *(optional but ideal)*

### Dimensions

* `dim_date(date_key, full_date, year, month, week_start_date, month_start_date, ...)`
* `dim_product(product_key, product_name, brand_name, cannabinoid_family, flavor, pack_size, thc_mg_per_pack, cbd_mg_per_pack, ...)`
* `dim_location(location_key, location_name, region, state, ...)`
* `dim_channel(channel_key, channel_name)`
* `dim_employee_group(employee_group_key, team_name, department_name)`

---

# 1) Core Sales KPI Dashboard Base

This is your “exec summary” dataset by month / state / channel.

```sql
WITH sales_base AS (
  SELECT
    d.month_start_date,
    l.state,
    c.channel_name,
    SUM(s.units_sold) AS units_sold,
    SUM(s.gross_sales_amount) AS gross_sales,
    SUM(s.net_sales_amount) AS net_sales,
    SUM(s.cogs_amount) AS cogs
  FROM fact_sales s
  JOIN dim_date d      ON s.date_key = d.date_key
  JOIN dim_location l  ON s.location_key = l.location_key
  JOIN dim_channel c   ON s.channel_key = c.channel_key
  JOIN dim_product p   ON s.product_key = p.product_key
  WHERE p.brand_name = 'Wyld'
  GROUP BY 1,2,3
)
SELECT
  month_start_date,
  state,
  channel_name,
  units_sold,
  gross_sales,
  net_sales,
  cogs,
  (net_sales - cogs) AS gross_margin_dollars,
  CASE WHEN net_sales = 0 THEN NULL ELSE (net_sales - cogs) / net_sales END AS gross_margin_pct,
  CASE WHEN units_sold = 0 THEN NULL ELSE gross_sales / units_sold END AS gross_vwap,
  CASE WHEN units_sold = 0 THEN NULL ELSE net_sales / units_sold END AS net_vwap,
  CASE WHEN gross_sales = 0 THEN NULL ELSE (gross_sales - net_sales) / gross_sales END AS discount_rate
FROM sales_base
ORDER BY month_start_date, state, channel_name;
```

---

# 2) Product Mix Analysis (Revenue + Units + Margin Mix)

This helps answer: “Which product families are actually driving profitable growth?”

```sql
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
```

---

# 3) Price Pack Architecture (Price per Pack, Price per mg THC)

This is very cannabis-specific and very useful.

```sql
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
       ELSE SUM(s.net_sales_amount) / SUM(s.units_sold)
  END AS net_price_per_pack,
  CASE WHEN SUM(s.units_sold * COALESCE(p.thc_mg_per_pack,0)) = 0 THEN NULL
       ELSE SUM(s.net_sales_amount) / SUM(s.units_sold * p.thc_mg_per_pack)
  END AS net_revenue_per_mg_thc,
  CASE WHEN SUM(s.units_sold * COALESCE(p.thc_mg_per_pack,0)) = 0 THEN NULL
       ELSE SUM(s.net_sales_amount - s.cogs_amount) / SUM(s.units_sold * p.thc_mg_per_pack)
  END AS margin_per_mg_thc
FROM fact_sales s
JOIN dim_date d      ON s.date_key = d.date_key
JOIN dim_product p   ON s.product_key = p.product_key
JOIN dim_location l  ON s.location_key = l.location_key
WHERE p.brand_name = 'Wyld'
GROUP BY 1,2,3,4,5,6
ORDER BY d.month_start_date, l.state, net_sales DESC;
```

---

# 4) Promo Performance (Promo Penetration + Promo Lift Proxy)

This version compares promo vs non-promo unit velocity.

```sql
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
```

---

# 5) Distribution + Rate of Sale (ROS)

“How many active doors?” and “How fast are products moving where listed?”

```sql
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
```

---

# 6) Inventory Health (DOH, Turnover Proxy, In-Stock %)

If `fact_inventory` is daily snapshots, this is gold.

```sql
WITH inv AS (
  SELECT
    d.month_start_date,
    i.product_key,
    i.location_key,
    AVG(i.on_hand_units) AS avg_on_hand_units,
    AVG(CASE
          WHEN i.in_stock_flag IS NOT NULL THEN i.in_stock_flag::numeric
          WHEN i.on_hand_units > 0 THEN 1
          ELSE 0
        END) AS in_stock_pct
  FROM fact_inventory i
  JOIN dim_date d ON i.date_key = d.date_key
  GROUP BY 1,2,3
),
sales AS (
  SELECT
    d.month_start_date,
    s.product_key,
    s.location_key,
    SUM(s.units_sold) AS units_sold,
    SUM(s.cogs_amount) AS cogs
  FROM fact_sales s
  JOIN dim_date d ON s.date_key = d.date_key
  GROUP BY 1,2,3
)
SELECT
  d.month_start_date,
  l.state,
  p.product_name,
  AVG(inv.avg_on_hand_units) AS avg_on_hand_units,
  SUM(COALESCE(sales.units_sold,0)) AS units_sold,
  AVG(inv.in_stock_pct) AS in_stock_pct,
  1 - AVG(inv.in_stock_pct) AS stockout_rate,
  CASE WHEN SUM(COALESCE(sales.units_sold,0)) = 0 THEN NULL
       ELSE AVG(inv.avg_on_hand_units) / (SUM(sales.units_sold) / NULLIF(EXTRACT(DAY FROM (d.month_start_date + INTERVAL '1 month - 1 day')),0))
  END AS approx_days_on_hand,
  CASE WHEN AVG(inv.avg_on_hand_units) = 0 THEN NULL
       ELSE SUM(COALESCE(sales.units_sold,0)) / AVG(inv.avg_on_hand_units)
  END AS inventory_turnover_units
FROM (SELECT DISTINCT month_start_date FROM dim_date) d
JOIN inv
  ON inv.month_start_date = d.month_start_date
LEFT JOIN sales
  ON sales.month_start_date = inv.month_start_date
 AND sales.product_key = inv.product_key
 AND sales.location_key = inv.location_key
JOIN dim_product p ON inv.product_key = p.product_key
JOIN dim_location l ON inv.location_key = l.location_key
WHERE p.brand_name = 'Wyld'
GROUP BY d.month_start_date, l.state, p.product_name
ORDER BY d.month_start_date, l.state, p.product_name;
```

---

# 7) Sales + Labor Productivity (Revenue per Labor Hour / Unit per Labor Hour)

This is excellent for operations + staffing conversations.

```sql
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
  CASE WHEN COALESCE(lb.labor_hours,0) = 0 THEN NULL ELSE s.net_sales / lb.labor_hours END AS revenue_per_labor_hour,
  CASE WHEN COALESCE(lb.labor_hours,0) = 0 THEN NULL ELSE s.units_sold / lb.labor_hours END AS units_per_labor_hour,
  CASE WHEN COALESCE(lb.labor_cost,0) = 0 THEN NULL ELSE s.gross_margin_dollars / lb.labor_cost END AS gross_margin_to_labor_cost_ratio
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
```

---

# 8) Customer / Account Concentration (Top Account Risk)

If `location` = retail account / customer account in wholesale contexts, this is crucial.

```sql
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
```

---

# 9) Repeat Purchase / Retention (Account-Level)

If no consumer-level data, account retention is still very useful.

```sql
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
   AND prev.month_start_date = (cur.month_start_date - INTERVAL '1 month')
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
```

---

# 10) Price / Volume / Mix Decomposition (Month-over-Month)

This is a killer finance/business analysis output.

```sql
WITH sku_month AS (
  SELECT
    d.month_start_date,
    s.product_key,
    SUM(s.units_sold) AS units,
    SUM(s.net_sales_amount) AS net_sales,
    CASE WHEN SUM(s.units_sold) = 0 THEN NULL
         ELSE SUM(s.net_sales_amount) / SUM(s.units_sold)
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
  d.month_start_date,
  SUM(d.revenue_variance) AS revenue_variance,
  SUM(d.price_effect) AS price_effect,
  SUM(d.volume_effect) AS volume_effect,
  SUM(d.revenue_variance) - SUM(d.price_effect) - SUM(d.volume_effect) AS mix_effect
FROM decomp d
GROUP BY 1
ORDER BY 1;
```

---

# 11) Forecast Accuracy (if you add a forecast fact)

You didn’t include a forecast table, but if you add `fact_forecast`, here’s the pattern.

### Assumed `fact_forecast`

* `date_key`
* `product_key`
* `location_key`
* `forecast_units`

```sql
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
    SUM((a.actual_units - COALESCE(f.forecast_units,0)))::numeric) /
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
```

---

# 12) Field-Test Query (Data Quality / Sanity Checks)

This is the sneaky-important one. Analysts who validate inputs are dangerous (in a good way).

```sql
SELECT
  COUNT(*) AS rows_checked,
  SUM(CASE WHEN units_sold < 0 THEN 1 ELSE 0 END) AS negative_units_rows,
  SUM(CASE WHEN net_sales_amount < 0 THEN 1 ELSE 0 END) AS negative_net_sales_rows,
  SUM(CASE WHEN gross_sales_amount < net_sales_amount THEN 1 ELSE 0 END) AS gross_less_than_net_rows,
  SUM(CASE WHEN cogs_amount < 0 THEN 1 ELSE 0 END) AS negative_cogs_rows,
  SUM(CASE WHEN units_sold = 0 AND net_sales_amount <> 0 THEN 1 ELSE 0 END) AS zero_units_nonzero_sales_rows
FROM fact_sales;
```

This catches weirdness before leadership catches it for you. Big difference.

---

# How I’d organize these in your repo (this will look legit)

```txt
sql/
  01_kpi_exec_summary.sql
  02_product_mix.sql
  03_price_pack_architecture.sql
  04_promo_performance.sql
  05_distribution_ros.sql
  06_inventory_health.sql
  07_sales_labor_productivity.sql
  08_account_concentration.sql
  09_account_retention.sql
  10_price_volume_mix_decomp.sql
  11_forecast_accuracy.sql
  12_data_quality_checks.sql
```

That’s portfolio candy for a hiring manager.

---

## 💡💡 Pro move for Wyld-specific analysis

Add a **cannabinoid performance lens** to almost every query:

* `p.cannabinoid_family`
* `p.flavor`
* `p.pack_size`

Why? Because cannabis businesses often look healthy at total brand level while one formulation family is quietly carrying the whole thing. Your job as analyst is to find the hidden engine (or hidden leak).

The universe runs on hidden variables and mislabeled columns. Your schema is already 80% of the battle.
