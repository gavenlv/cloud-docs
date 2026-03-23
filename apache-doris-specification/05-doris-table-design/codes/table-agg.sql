-- Aggregate模型表示例
-- 适用场景：报表统计、指标分析

CREATE TABLE IF NOT EXISTS example_db.agg_table
(
    user_id       BIGINT      NOT NULL,
    date          DATE        NOT NULL,
    city          VARCHAR(20),
    uv            BIGINT      SUM DEFAULT '0',
    pv            BIGINT      SUM DEFAULT '0',
    revenue       DECIMAL(15,2) SUM DEFAULT '0',
    duration      BIGINT      SUM DEFAULT '0'
)
AGGREGATE KEY(user_id, date, city)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PARTITION BY RANGE(date) (
    PARTITION p202401 VALUES LESS THAN ('2024-02-01'),
    PARTITION p202402 VALUES LESS THAN ('2024-03-01'),
    PARTITION p202403 VALUES LESS THAN ('2024-04-01')
)
PROPERTIES (
    "replication_num" = "3"
);

-- 插入数据（相同Key自动聚合）
INSERT INTO agg_table VALUES
(1, '2024-01-01', 'Beijing', 1, 10, 100.00, 1000),
(1, '2024-01-01', 'Beijing', 1, 5, 50.00, 500),
(2, '2024-01-01', 'Shanghai', 1, 8, 80.00, 800);

-- 查询（已自动聚合）
SELECT * FROM agg_table;

-- 按日期统计
SELECT date, SUM(uv) as total_uv, SUM(pv) as total_pv, SUM(revenue) as total_revenue
FROM agg_table
GROUP BY date;

-- 按城市统计
SELECT city, SUM(uv) as total_uv, SUM(revenue) as total_revenue
FROM agg_table
GROUP BY city;
