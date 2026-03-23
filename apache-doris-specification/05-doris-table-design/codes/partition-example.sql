-- 分区表示例

-- Range分区 - 按时间范围
CREATE TABLE IF NOT EXISTS example_db.range_partition_table
(
    order_id        BIGINT        NOT NULL,
    user_id         BIGINT        NOT NULL,
    order_date      DATE          NOT NULL,
    order_time      DATETIME      NOT NULL,
    total_amount    DECIMAL(15,2) NOT NULL,
    status          VARCHAR(20)
)
DUPLICATE KEY(order_id, order_date)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PARTITION BY RANGE(order_date) (
    PARTITION p202401 VALUES LESS THAN ('2024-02-01'),
    PARTITION p202402 VALUES LESS THAN ('2024-03-01'),
    PARTITION p202403 VALUES LESS THAN ('2024-04-01'),
    PARTITION p202404 VALUES LESS THAN ('2024-05-01'),
    PARTITION p202405 VALUES LESS THAN ('2024-06-01'),
    PARTITION p202406 VALUES LESS THAN ('2024-07-01'),
    PARTITION p202407 VALUES LESS THAN ('2024-08-01'),
    PARTITION p202408 VALUES LESS THAN ('2024-09-01'),
    PARTITION p202409 VALUES LESS THAN ('2024-10-01'),
    PARTITION p202410 VALUES LESS THAN ('2024-11-01'),
    PARTITION p202411 VALUES LESS THAN ('2024-12-01'),
    PARTITION p202412 VALUES LESS THAN ('2025-01-01'),
    PARTITION p2025q1 VALUES LESS THAN ('2025-04-01'),
    PARTITION p2025q2 VALUES LESS THAN ('2025-07-01'),
    PARTITION p_future VALUES LESS THAN MAXVALUE
)
PROPERTIES (
    "replication_num" = "3"
);

-- 动态分区 - 自动管理分区
CREATE TABLE IF NOT EXISTS example_db.dynamic_partition_table
(
    event_date DATE      NOT NULL,
    user_id    BIGINT    NOT NULL,
    event_type VARCHAR(50),
    amount     DECIMAL(15,2)
)
DUPLICATE KEY(event_date, user_id)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PARTITION BY RANGE(event_date) ()
PROPERTIES (
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "DAY",
    "dynamic_partition.start" = "-30",
    "dynamic_partition.end" = "3",
    "dynamic_partition.prefix" = "p",
    "dynamic_partition.buckets" = "10"
);

-- List分区 - 按枚举值
CREATE TABLE IF NOT EXISTS example_db.list_partition_table
(
    region   VARCHAR(20) NOT NULL,
    user_id  BIGINT      NOT NULL,
    amount   DECIMAL(15,2)
)
PARTITION BY LIST(region) (
    PARTITION p_china VALUES IN ('Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Hangzhou'),
    PARTITION p_usa VALUES IN ('New York', 'Los Angeles', 'San Francisco', 'Seattle'),
    PARTITION p_europe VALUES IN ('London', 'Paris', 'Berlin', 'Madrid'),
    PARTITION p_other VALUES IN (DEFAULT)
)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;

-- 添加分区
ALTER TABLE range_partition_table ADD PARTITION p2025q3 VALUES LESS THAN ('2025-10-01');

-- 删除分区
ALTER TABLE range_partition_table DROP PARTITION p_future;

-- 查看分区
SHOW PARTITIONS FROM range_partition_table;
