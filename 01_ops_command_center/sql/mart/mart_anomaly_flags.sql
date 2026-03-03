-- Build anomaly flags (rolling z-score / IQR) for margin drops and stockout spikes
-- /mart/mart_anomaly_flags.sql

-- Create daily/weekly anomaly flags for:

-- * margin drops
-- * stockout spikes
-- * labor productivity drops

-- Use simple logic:

-- * rolling mean + rolling std dev
-- * z-score threshold (e.g., abs(z) > 2)
-- * or IQR if easier in SQL

-- Columns:

-- * `metric_name`
-- * `date_key`
-- * `location_key` (optional)
-- * `value`
-- * `baseline_avg`
-- * `z_score`
-- * `is_anomaly`