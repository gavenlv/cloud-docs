# Doris表设计

## 概述

本文档介绍Doris的表设计最佳实践，包括数据模型选择、分区设计、分桶策略和索引设计。

## 数据模型

### Duplicate模型

适用场景：需要保留完整原始数据的分析场景

```sql
CREATE TABLE IF NOT EXISTS example_db.log_table
(
    log_id     BIGINT       NOT NULL,
    timestamp  DATETIME     NOT NULL,
    client_ip  VARCHAR(50)  NOT NULL,
    request    VARCHAR(500),
    response   VARCHAR(500),
    duration   INT
)
DUPLICATE KEY(log_id, timestamp)
DISTRIBUTED BY HASH(log_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "3"
);
```

特点：
- 存储完整的原始数据
- 查询时不需要聚合
- 存储空间较大

### Aggregate模型

适用场景：需要预先聚合的指标统计场景

```sql
CREATE TABLE IF NOT EXISTS example_db.agg_table
(
    user_id       BIGINT      NOT NULL,
    date          DATE        NOT NULL,
    city          VARCHAR(20),
    uv            BIGINT      SUM DEFAULT '0',
    pv            BIGINT      SUM DEFAULT '0',
    revenue       DECIMAL(15,2) SUM DEFAULT '0'
)
AGGREGATE KEY(user_id, date, city)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PARTITION BY RANGE(date) (
    PARTITION p202301 VALUES LESS THAN ('2023-02-01'),
    PARTITION p202302 VALUES LESS THAN ('2023-03-01'),
    PARTITION p202303 VALUES LESS THAN ('2023-04-01')
);
```

特点：
- 相同Key的数据自动聚合
- 减少存储空间
- 适合报表统计

### Unique模型

适用场景：需要保证数据唯一性的场景

```sql
CREATE TABLE IF NOT EXISTS example_db.user_table
(
    user_id     BIGINT      NOT NULL,
    username    VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    last_login  DATETIME
)
UNIQUE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "3"
);
```

特点：
- 保证Key唯一性
- 最新值覆盖旧值
- 支持实时更新

## 分区设计

### Range分区

按时间范围分区：

```sql
CREATE TABLE IF NOT EXISTS example_db.partition_table
(
    event_date DATE      NOT NULL,
    user_id    BIGINT    NOT NULL,
    event_type VARCHAR(50),
    amount     DECIMAL(15,2)
)
PARTITION BY RANGE(event_date) (
    PARTITION p202301 VALUES LESS THAN ('2023-02-01'),
    PARTITION p202302 VALUES LESS THAN ('2023-03-01'),
    PARTITION p202303 VALUES LESS THAN ('2023-04-01'),
    PARTITION p202304 VALUES LESS THAN ('2023-05-01'),
    PARTITION p202305 VALUES LESS THAN ('2023-06-01'),
    PARTITION p202306 VALUES LESS THAN ('2023-07-01'),
    PARTITION p202307 VALUES LESS THAN ('2023-08-01'),
    PARTITION p202308 VALUES LESS THAN ('2023-09-01'),
    PARTITION p202309 VALUES LESS THAN ('2023-10-01'),
    PARTITION p202310 VALUES LESS THAN ('2023-11-01'),
    PARTITION p202311 VALUES LESS THAN ('2023-12-01'),
    PARTITION p202312 VALUES LESS THAN ('2024-01-01'),
    PARTITION p202401 VALUES LESS THAN ('2024-02-01'),
    PARTITION p202402 VALUES LESS THAN ('2024-03-01'),
    PARTITION p202403 VALUES LESS THAN ('2024-04-01')
)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;
```

动态分区：

```sql
CREATE TABLE IF NOT EXISTS example_db.dynamic_partition_table
(
    event_date DATE      NOT NULL,
    user_id    BIGINT    NOT NULL,
    event_type VARCHAR(50)
)
PARTITION BY RANGE(event_date) ()
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "DAY",
    "dynamic_partition.start" = "-30",
    "dynamic_partition.end" = "3",
    "dynamic_partition.prefix" = "p",
    "dynamic_partition.buckets" = "10"
);
```

### List分区

按枚举值分区：

```sql
CREATE TABLE IF NOT EXISTS example_db.list_partition_table
(
    region   VARCHAR(20) NOT NULL,
    user_id  BIGINT      NOT NULL,
    amount   DECIMAL(15,2)
)
PARTITION BY LIST(region) (
    PARTITION p_china VALUES IN ('Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen'),
    PARTITION p_usa VALUES IN ('New York', 'Los Angeles', 'San Francisco'),
    PARTITION p_europe VALUES IN ('London', 'Paris', 'Berlin')
)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;
```

## 分桶设计

### 选择分桶键

原则：
- 选择高基列（区分度高的列）
- 常用于JOIN的列
- 常用于WHERE条件的列

```sql
-- 错误的分桶键（低基列）
CREATE TABLE bad_example (
    status VARCHAR(20) NOT NULL,
    ...
)
DISTRIBUTED BY HASH(status) BUCKETS 10;  -- status只有几个值，数据倾斜

-- 正确的分桶键（高基列）
CREATE TABLE good_example (
    user_id BIGINT NOT NULL,
    ...
)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;
```

### 分桶数量

```sql
-- 小表
CREATE TABLE small_table (
    ...
)
DISTRIBUTED BY HASH(id) BUCKETS 10;

-- 中等表（千万级）
CREATE TABLE medium_table (
    ...
)
DISTRIBUTED BY HASH(id) BUCKETS 30;

-- 大表（亿级以上）
CREATE TABLE large_table (
    ...
)
DISTRIBUTED BY HASH(id) BUCKETS 50;
```

### 复合分桶键

```sql
-- 多列分桶
CREATE TABLE example_table (
    user_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    amount DECIMAL(15,2)
)
DISTRIBUTED BY HASH(user_id, order_id) BUCKETS 20;
```

## 索引设计

### 前缀索引

Doris自动创建基于分桶键的前缀索引：

```sql
-- 分桶键即前缀索引
CREATE TABLE prefix_example (
    user_id BIGINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    age INT
)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;

-- 查询优化：如果WHERE条件包含user_id，查询会很快
SELECT * FROM prefix_example WHERE user_id = 123;
```

### Bloom Filter索引

适用于高基列的等值查询：

```sql
CREATE TABLE bloomfilter_example (
    user_id BIGINT NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100)
)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "bloom_filter_columns" = "phone,email"
);
```

## 最佳实践

### 表设计原则

1. **合理的模型选择**
   - 日志分析：Duplicate模型
   - 统计报表：Aggregate模型
   - 实时数据：Unique模型

2. **分区策略**
   - 按时间分区，便于数据管理
   - 控制分区大小（建议10GB-100GB）
   - 历史数据分区可适当放大

3. **分桶策略**
   - 选择高基列作为分桶键
   - 避免数据倾斜
   - Bucket数量适中

4. **字段设计**
   - 避免使用TEXT/BLOB等大字段
   - 合理使用DECIMAL精度
   - 尽量使用NOT NULL

### 示例：电商数据表

```sql
-- 订单事实表
CREATE TABLE IF NOT EXISTS dw.order_fact
(
    order_id        BIGINT        NOT NULL,
    user_id         BIGINT        NOT NULL,
    order_date      DATE          NOT NULL,
    order_time      DATETIME      NOT NULL,
    city_id         INT           NOT NULL,
    order_status    TINYINT       NOT NULL,
    total_amount    DECIMAL(15,2) NOT NULL,
    discount_amount DECIMAL(15,2) DEFAULT '0',
    payment_method  VARCHAR(20),
    shipping_method VARCHAR(20)
)
UNIQUE KEY(order_id, order_time)
DISTRIBUTED BY HASH(order_id) BUCKETS 20
PARTITION BY RANGE(order_date) ()
PROPERTIES (
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "DAY",
    "dynamic_partition.start" = "-90",
    "dynamic_partition.end" = "3",
    "dynamic_partition.buckets" = "20"
);

-- 用户维度表
CREATE TABLE IF NOT EXISTS dw.user_dim
(
    user_id     BIGINT       NOT NULL,
    username    VARCHAR(50)  NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    register_date DATE,
    user_level  TINYINT      DEFAULT '1'
)
UNIQUE KEY(user_id)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;
```
