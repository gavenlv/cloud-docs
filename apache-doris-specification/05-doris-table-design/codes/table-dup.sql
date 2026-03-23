-- Duplicate模型表示例
-- 适用场景：日志分析、原始数据存储

CREATE TABLE IF NOT EXISTS example_db.log_table
(
    log_id     BIGINT       NOT NULL,
    timestamp  DATETIME     NOT NULL,
    client_ip  VARCHAR(50)  NOT NULL,
    request    VARCHAR(500),
    response   VARCHAR(500),
    status_code INT,
    duration   INT
)
DUPLICATE KEY(log_id, timestamp)
DISTRIBUTED BY HASH(log_id) BUCKETS 10
PARTITION BY RANGE(timestamp) (
    PARTITION p202401 VALUES LESS THAN ('2024-02-01'),
    PARTITION p202402 VALUES LESS THAN ('2024-03-01'),
    PARTITION p202403 VALUES LESS THAN ('2024-04-01')
)
PROPERTIES (
    "replication_num" = "3",
    "storage_medium" = "SSD"
);

-- 插入测试数据
INSERT INTO log_table VALUES
(1, '2024-01-01 10:00:00', '192.168.1.1', '/api/users', 'success', 200, 100),
(2, '2024-01-01 10:01:00', '192.168.1.2', '/api/orders', 'success', 200, 150),
(3, '2024-01-01 10:02:00', '192.168.1.1', '/api/products', 'error', 500, 50);

-- 查询所有数据
SELECT * FROM log_table;

-- 按时间范围查询
SELECT * FROM log_table WHERE timestamp >= '2024-01-01 10:00:00' AND timestamp < '2024-01-01 11:00:00';

-- 按状态码统计
SELECT status_code, COUNT(*) as count, AVG(duration) as avg_duration
FROM log_table
GROUP BY status_code;
