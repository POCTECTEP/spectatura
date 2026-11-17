CREATE DATABASE IF NOT EXISTS marketcontrol_db ENGINE = Atomic;

-- 1. historical_data
CREATE TABLE IF NOT EXISTS marketcontrol_db.historical_data (
    timestamp DateTime('Europe/Moscow') NOT NULL,
    item_id UInt32 NOT NULL,
    purchase_price Decimal(10, 2) NOT NULL,
    sale_price Decimal(10, 2) NOT NULL,
    purchases_count UInt32 NOT NULL,
    sales_count UInt32 NOT NULL,
    missed_updates UInt16 NOT NULL
) ENGINE = MergeTree()
ORDER BY (item_id, timestamp);

-- 2. data_for_neural_network
CREATE TABLE IF NOT EXISTS marketcontrol_db.data_for_neural_network (
    timestamp DateTime('Europe/Moscow') NOT NULL,
    item_id UInt32 NOT NULL,
    hour_sin Float64 NOT NULL,
    hour_cos Float64 NOT NULL,
    day_sin Float64 NOT NULL,
    day_cos Float64 NOT NULL,
    is_weekend UInt8 NOT NULL,
    month_of_year UInt8 NOT NULL,
    missed_updates UInt16 NOT NULL,
    is_data_stale UInt8 NOT NULL,
    data_freshness_score Float32 NOT NULL,
    log_return_1h Float64 NOT NULL,
    log_return_6h Float64 NOT NULL,
    log_return_24h Float64 NOT NULL,
    log_return_7d Float64 NOT NULL,
    trend_slope_24h Float64 NOT NULL,
    volatility_24h Float64 NOT NULL,
    volatility_7d Float64 NOT NULL,
    percentile_rank_7d Float64 NOT NULL,
    percentile_rank_30d Float64 NOT NULL,
    distance_to_hist_max Decimal(10, 2) NOT NULL,
    distance_to_hist_min Decimal(10, 2) NOT NULL,
    is_near_floor UInt8 NOT NULL,
    spread_vs_commission Float64 NOT NULL,
    relative_bid_strength Float64 NOT NULL,
    liquidity_depth_log Float64 NOT NULL,
    target Int8 NOT NULL
) ENGINE = MergeTree()
ORDER BY (item_id, timestamp);

-- 3. audit_log
CREATE TABLE IF NOT EXISTS marketcontrol_db.audit_log (
    timestamp DateTime64(6, 'Europe/Moscow') NOT NULL,
    level LowCardinality(String) NOT NULL,
    source LowCardinality(String) NOT NULL,
    message String NOT NULL,
    duration UInt32
) ENGINE = MergeTree()
ORDER BY timestamp
TTL toDateTime(timestamp) + INTERVAL 30 DAY;