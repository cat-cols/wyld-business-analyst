-- dim_date.sql
-- Purpose: Build a reusable calendar/date dimension for Wyld analytics.
-- Dialect: PostgreSQL-compatible (works in many warehouses with small tweaks).
--
-- Notes:
-- - Generates one row per calendar date
-- - Includes common calendar attributes for weekly/monthly reporting
-- - Week starts on Monday (ISO-style)
-- - Includes fiscal placeholders (set fiscal_start_month as needed)

-- dax?
-- DimDate[Date] (marked as date table)
-- DimDate[WeekStart], DimDate[Month], etc.

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
WITH params AS (
    SELECT
        DATE '2022-01-01' AS start_date,   -- adjust range as needed
        DATE '2030-12-31' AS end_date,
        1 AS fiscal_start_month            -- 1 = January fiscal year; set to e.g. 4 for April
),
dates AS (
    SELECT
        gs::date AS full_date
    FROM params p
    CROSS JOIN generate_series(p.start_date, p.end_date, interval '1 day') AS gs
),
base AS (
    SELECT
        -- Surrogate key in YYYYMMDD integer format
        CAST(to_char(d.full_date, 'YYYYMMDD') AS integer) AS date_key,
        d.full_date,

        -- Basic calendar parts
        EXTRACT(YEAR  FROM d.full_date)::int AS year_num,
        EXTRACT(MONTH FROM d.full_date)::int AS month_num,
        EXTRACT(DAY   FROM d.full_date)::int AS day_of_month,
        EXTRACT(QUARTER FROM d.full_date)::int AS quarter_num,

        -- Names
        to_char(d.full_date, 'FMMonth') AS month_name,
        to_char(d.full_date, 'Mon') AS month_name_short,
        to_char(d.full_date, 'FMDay') AS day_name,
        to_char(d.full_date, 'Dy') AS day_name_short,

        -- Day/Week attributes
        EXTRACT(DOY FROM d.full_date)::int AS day_of_year,
        EXTRACT(ISODOW FROM d.full_date)::int AS iso_day_of_week_num, -- Mon=1 .. Sun=7
        CASE WHEN EXTRACT(ISODOW FROM d.full_date) IN (6,7) THEN TRUE ELSE FALSE END AS is_weekend,

        -- Week/Month boundaries
        date_trunc('week', d.full_date)::date AS week_start_date,      -- Monday start in Postgres
        (date_trunc('week', d.full_date)::date + INTERVAL '6 day')::date AS week_end_date,
        date_trunc('month', d.full_date)::date AS month_start_date,
        (date_trunc('month', d.full_date) + INTERVAL '1 month - 1 day')::date AS month_end_date,
        date_trunc('quarter', d.full_date)::date AS quarter_start_date,
        (date_trunc('quarter', d.full_date) + INTERVAL '3 month - 1 day')::date AS quarter_end_date,
        date_trunc('year', d.full_date)::date AS year_start_date,
        (date_trunc('year', d.full_date) + INTERVAL '1 year - 1 day')::date AS year_end_date,

        -- ISO week/year (very useful for weekly reporting)
        EXTRACT(ISOWEEK FROM d.full_date)::int AS iso_week_num,
        EXTRACT(ISOYEAR FROM d.full_date)::int AS iso_year_num,

        -- Common labels
        to_char(d.full_date, 'YYYY-MM') AS year_month_label,
        to_char(d.full_date, 'YYYY"Q"Q') AS year_quarter_label,

        -- Relative flags (relative to current date at runtime)
        CASE WHEN d.full_date = CURRENT_DATE THEN TRUE ELSE FALSE END AS is_today,
        CASE WHEN d.full_date = CURRENT_DATE - INTERVAL '1 day' THEN TRUE ELSE FALSE END AS is_yesterday,
        CASE WHEN d.full_date >= date_trunc('month', CURRENT_DATE)::date
               AND d.full_date <= CURRENT_DATE THEN TRUE ELSE FALSE END AS is_mtd,
        CASE WHEN d.full_date >= date_trunc('year', CURRENT_DATE)::date
               AND d.full_date <= CURRENT_DATE THEN TRUE ELSE FALSE END AS is_ytd

    FROM dates d
),
fiscal AS (
    SELECT
        b.*,
        p.fiscal_start_month,

        -- Fiscal year logic (fiscal year named by ending year)
        CASE
            WHEN b.month_num >= p.fiscal_start_month THEN b.year_num + CASE WHEN p.fiscal_start_month = 1 THEN 0 ELSE 1 END
            ELSE b.year_num
        END AS fiscal_year_num,

        -- Fiscal month number (1-12 relative to fiscal start)
        (((b.month_num - p.fiscal_start_month + 12) % 12) + 1) AS fiscal_month_num

    FROM base b
    CROSS JOIN params p
)
SELECT
    date_key,
    full_date,

    -- Calendar
    year_num AS year,
    quarter_num AS quarter,
    month_num AS month,
    month_name,
    month_name_short,
    day_of_month,
    day_of_year,
    day_name,
    day_name_short,
    iso_day_of_week_num,
    is_weekend,

    -- Week / month / quarter / year boundaries
    iso_week_num,
    iso_year_num,
    week_start_date,
    week_end_date,
    month_start_date,
    month_end_date,
    quarter_start_date,
    quarter_end_date,
    year_start_date,
    year_end_date,

    -- Labels
    year_month_label,
    year_quarter_label,

    -- Fiscal
    fiscal_start_month,
    fiscal_year_num AS fiscal_year,
    fiscal_month_num AS fiscal_month,
    CEIL(fiscal_month_num / 3.0)::int AS fiscal_quarter,
    CONCAT('FY', fiscal_year_num) AS fiscal_year_label,
    CONCAT('FY', fiscal_year_num, '-P', LPAD(fiscal_month_num::text, 2, '0')) AS fiscal_period_label,

    -- Relative flags
    is_today,
    is_yesterday,
    is_mtd,
    is_ytd

FROM fiscal
ORDER BY full_date;

-- Optional indexes (Postgres)
CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_date_date_key ON dim_date(date_key);
CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_date_full_date ON dim_date(full_date);
CREATE INDEX IF NOT EXISTS idx_dim_date_month_start ON dim_date(month_start_date);
CREATE INDEX IF NOT EXISTS idx_dim_date_week_start ON dim_date(week_start_date);

-- Quick sanity check
-- SELECT * FROM dim_date ORDER BY full_date LIMIT 10;
-- SELECT * FROM dim_date ORDER BY full_date DESC LIMIT 10;
