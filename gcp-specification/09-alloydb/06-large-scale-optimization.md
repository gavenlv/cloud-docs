# AlloyDB 列式存储与大规模数据管理

## 本章概述

本章深入解析AlloyDB的列式存储架构原理，介绍针对大规模数据写入、查询优化的实质性SQL操作方法，并提供可执行的示例和性能对比。

## 学习目标

- 深入理解AlloyDB列式存储的内部原理
- 掌握大规模数据写入的最佳实践
- 学会使用EXPLAIN ANALYZE分析查询执行计划
- 理解数据分布和分区策略

---

## 1. 列式存储原理

### 1.1 行式存储 vs 列式存储

```
行式存储 vs 列式存储 原理对比

┌─────────────────────────────────────────────────────────────────────────┐
│                        行式存储 (传统PostgreSQL)                        │
│                                                                         │
│  数据按行连续存储：                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Row1: [id=1, name=Alice, age=25, city=NYC, salary=75000, ...]   │   │
│  │ Row2: [id=2, name=Bob,   age=30, city=LA,   salary=80000, ...]   │   │
│  │ Row3: [id=3, name=Charlie,age=35, city=NYC, salary=90000, ...]   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  查询 SELECT AVG(salary) FROM users WHERE city='NYC':                   │
│  → 必须读取每一行的所有列，即使只需要 salary 和 city                    │
│  → IO放大: 读取 100% 数据，只使用 2%                                   │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                        列式存储 (AlloyDB)                               │
│                                                                         │
│  数据按列连续存储：                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ id列:    [1, 2, 3, 4, 5, ...]                                    │   │
│  │ name列:  [Alice, Bob, Charlie, David, Eve, ...]                   │   │
│  │ age列:   [25, 30, 35, 28, 42, ...]                               │   │
│  │ city列:  [NYC, LA, NYC, SF, NYC, ...]                            │   │
│  │ salary列:[75000, 80000, 90000, 65000, 95000, ...]                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  查询 SELECT AVG(salary) FROM users WHERE city='NYC':                   │
│  → 只读取 city列 和 salary列                                             │
│  → 过滤 city='NYC' 的行                                                 │
│  → 计算 salary平均值                                                    │
│  → IO节省: 读取 40% 数据，使用 100%                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 列式存储内部结构

```
AlloyDB 列式存储内部结构

┌─────────────────────────────────────────────────────────────────────────┐
│                        列式存储文件结构                                  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Column File (salary列)                       │   │
│  │                                                                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │ Segment 1: [75000, 80000, 90000] - Dictionary Encoding   │  │   │
│  │  │ Segment 2: [65000, 95000, 70000] - RLE Encoding          │  │   │
│  │  │ Segment 3: [85000, 72000, 88000] - Delta Encoding        │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  │                                                                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │ Statistics Block                                          │  │   │
│  │  │ • Min: 65000                                             │  │   │
│  │  │ • Max: 95000                                             │  │   │
│  │  │ • Null Count: 0                                          │  │   │
│  │  │ • Distinct Values: 15                                    │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Dictionary Encoding                         │   │
│  │                                                                  │   │
│  │  city列原始值: [NYC, LA, NYC, SF, NYC, LA, NYC, ...]              │   │
│  │                                                                  │   │
│  │  Dictionary:                                                    │   │
│  │  ┌─────────┬───────┐                                            │   │
│  │  │ NYC     │   0   │                                            │   │
│  │  │ LA      │   1   │                                            │   │
│  │  │ SF      │   2   │                                            │   │
│  │  └─────────┴───────┘                                            │   │
│  │                                                                  │   │
│  │  Encoded: [0, 1, 0, 2, 0, 1, 0, ...]                            │   │
│  │  → 压缩率: 3x (字符串 → 整数)                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.3 压缩算法原理

```sql
-- 1.3.1 查看列式存储统计信息

-- 查看表统计信息
SELECT
    schemaname,
    relname,
    reltuples::bigint as row_count,
    relpages as page_count,
    ROUND(reltuples / relpages, 2) as rows_per_page
FROM pg_class
WHERE relname IN ('orders', 'order_items', 'products')
ORDER BY reltuples DESC;

-- 1.3.2 查看列统计信息
SELECT
    attname,
    n_distinct,
    correlation,
    most_common_vals,
    most_common_freqs
FROM pg_stats
WHERE tablename = 'orders'
AND attname IN ('total_amount', 'status', 'created_at');

-- 1.3.3 查看索引统计
SELECT
    indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    idx_blks_read,
    idx_blks_hit
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

---

## 2. 大规模数据写入

### 2.1 批量写入性能对比

```sql
-- 2.1.1 单行插入 vs 批量插入 性能对比

-- 环境准备：创建测试表
CREATE TABLE IF NOT EXISTS test_records (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 测试1：单行插入 (1000次)
-- 执行时间：约 15-20 秒

-- 测试2：批量插入 (单条INSERT，1000行)
-- 执行时间：约 0.5-1 秒

-- 测试3：COPY命令 (最高效)
-- 执行时间：约 0.1-0.3 秒

-- 2.1.2 批量插入 SQL 示例

-- 方式1：多值INSERT
INSERT INTO test_records (user_id, event_type, event_data)
VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'page_view', '{"page": "/home"}'),
    ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'click', '{"button": "submit"}'),
    ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'purchase', '{"amount": 99.99}');

-- 方式2：大规模批量插入
INSERT INTO test_records (user_id, event_type, event_data)
SELECT
    gen_random_uuid(),
    (ARRAY['page_view', 'click', 'purchase', 'signup'])[floor(random() * 4 + 1)],
    jsonb_build_object('session_id', md5(random()::text), 'duration', (random() * 100)::int)
FROM generate_series(1, 10000);
```

### 2.2 写入优化策略

```sql
-- 2.2.1 禁用索引加速批量写入

-- 批量写入前：删除索引
CREATE INDEX idx_test_records_user_id ON test_records(user_id);
CREATE INDEX idx_test_records_event_type ON test_records(event_type);
CREATE INDEX idx_test_records_created_at ON test_records(created_at DESC);

-- 批量写入前删除索引
DROP INDEX idx_test_records_user_id;
DROP INDEX idx_test_records_event_type;
DROP INDEX idx_test_records_created_at;

-- 执行批量插入
INSERT INTO test_records (user_id, event_type, event_data)
SELECT
    gen_random_uuid(),
    'bulk_event',
    '{}'::jsonb
FROM generate_series(1, 100000);

-- 批量写入后重建索引 (CONCURRENTLY避免锁)
CREATE INDEX CONCURRENTLY idx_test_records_user_id ON test_records(user_id);
CREATE INDEX CONCURRENTLY idx_test_records_event_type ON test_records(event_type);
CREATE INDEX CONCURRENTLY idx_test_records_created_at ON test_records(created_at DESC);

-- 2.2.2 事务批量提交

-- 错误：大事务（内存压力大）
BEGIN;
INSERT INTO test_records ... -- 100万行
COMMIT;
-- 风险：事务回滚成本高，内存占用大

-- 推荐：分批提交
DO $$
DECLARE
    batch_size INT := 10000;
    total_rows INT := 100000;
    offset_val INT := 0;
BEGIN
    FOR i IN 1..CEIL(total_rows::float / batch_size) LOOP
        INSERT INTO test_records (user_id, event_type, event_data)
        SELECT
            gen_random_uuid(),
            'batch_event',
            jsonb_build_object('batch', i)
        FROM generate_series(1, batch_size);

        offset_val := offset_val + batch_size;
        RAISE NOTICE 'Inserted rows: %', offset_val;
    END LOOP;
END $$;

-- 2.2.3 使用 UNLOGGED 表加速写入（可恢复场景）

CREATE UNLOGGED TABLE test_events_staging (
    id SERIAL,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 高速写入（无WAL日志）
INSERT INTO test_events_staging (event_data)
SELECT jsonb_build_object('data', md5(random()::text))
FROM generate_series(1, 100000);

-- 完成后转移到正式表
INSERT INTO test_records (user_id, event_type, event_data, created_at)
SELECT
    gen_random_uuid(),
    'imported',
    event_data,
    created_at
FROM test_events_staging;

-- 清理临时表
DROP TABLE test_events_staging;
```

### 2.3 COPY命令详解

```sql
-- 2.3.1 COPY命令语法

-- 从标准输入COPY数据
COPY test_records (user_id, event_type, event_data)
FROM STDIN WITH (FORMAT csv);

-- 示例数据：
a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11,page_view,"{""page"":""/home""}"
b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22,click,"{""button"":""submit""}"

\.

-- 2.3.2 从文件COPY

COPY test_records (user_id, event_type, event_data)
FROM '/path/to/data.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- 2.3.3 COPY与INSERT性能对比 (100万行)

-- COPY方式
-- Time: 1.234 seconds
-- IO: 顺序写入，WAL优化

-- INSERT 100万次
-- Time: 45.678 seconds
-- IO: 随机写入，每次事务开销

-- 多值INSERT (每次1000行)
-- Time: 12.345 seconds
-- IO: 批量写入，优化事务开销
```

---

## 3. 大规模数据查询

### 3.1 查询执行计划分析

```sql
-- 3.1.1 EXPLAIN ANALYZE 完整示例

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT)
SELECT
    o.order_id,
    o.user_id,
    o.total_amount,
    o.status,
    DATE(o.created_at) as order_date,
    COUNT(oi.item_id) as item_count,
    SUM(oi.subtotal) as items_total
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
AND o.status IN ('completed', 'shipped')
GROUP BY o.order_id, o.user_id, o.total_amount, o.status, DATE(o.created_at)
ORDER BY order_date DESC, total_amount DESC
LIMIT 100;

-- 输出示例及解析：
/*
Finalize GroupAggregate  (cost=1000.00..15000.00 rows=500 width=128)
                         (actual time=150.234..180.567 rows=100 loops=1)
  Output: ...
  Buffers: shared hit=1234 read=567
  -> Gather Motion (4 slices)
     -> Partial GroupAggregate
        -> ...
*/

-- 关键指标解读：
-- • cost=1000.00..15000.00: 估算成本（启动..总成本）
-- • actual time=150.234..180.567: 实际执行时间（首次行..最后行）
-- • rows=500: 估算返回行数
-- • rows=100: 实际返回行数
-- • Buffers: shared hit=1234: 从缓存读取的块数
-- • Buffers: read=567: 从磁盘读取的块数
-- • hit/read 比例越高越好
```

### 3.2 复杂查询优化示例

```sql
-- 3.2.1 聚合查询优化

-- 原始查询 (全表扫描)
EXPLAIN ANALYZE
SELECT
    DATE(created_at) as date,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(created_at);

-- 优化方案1：使用索引
CREATE INDEX idx_orders_created_at_amt ON orders(created_at, total_amount);

-- 优化后执行计划应显示 Index Only Scan
-- 性能提升：3-5x

-- 优化方案2：使用物化视图
CREATE MATERIALIZED VIEW daily_order_stats AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue,
    SUM(total_amount) / NULLIF(COUNT(*), 0) as avg_order_value
FROM orders
GROUP BY DATE(created_at);

CREATE UNIQUE INDEX ON daily_order_stats(date);

-- 查询物化视图
SELECT * FROM daily_order_stats
WHERE date >= CURRENT_DATE - INTERVAL '90 days';

-- 性能提升：10-100x (针对历史数据分析)

-- 3.2.2 JOIN优化

-- 原始查询
EXPLAIN ANALYZE
SELECT
    o.order_id,
    u.username,
    u.email,
    o.total_amount
FROM orders o
INNER JOIN users u ON o.user_id = u.user_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '7 days';

-- 分析执行计划中的JOIN类型：

-- Nested Loop Join (小表驱动大表，最佳)
-- → 驱动表 rows=100，被驱动表 index lookup

-- Hash Join (中等表，适合无索引)
-- → 构建hash表，探测hash桶

-- Merge Join (已排序数据，最佳)
-- → 两侧数据已排序，顺序合并

-- 优化：确保JOIN列有索引
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_users_user_id ON users(user_id);

-- 3.2.3 窗口函数优化

-- 原始查询 (计算每用户订单累计金额)
EXPLAIN ANALYZE
SELECT
    user_id,
    order_id,
    total_amount,
    created_at,
    SUM(total_amount) OVER (
        PARTITION BY user_id
        ORDER BY created_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_amount
FROM orders;

-- 优化：添加排序列索引
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);

-- 优化后：避免全表排序，使用索引顺序
```

### 3.3 分区表查询

```sql
-- 3.3.1 创建分区表

CREATE TABLE orders_partitioned (
    order_id UUID NOT NULL,
    user_id UUID NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
) PARTITION BY RANGE (created_at);

-- 创建月度分区
CREATE TABLE orders_2024_01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE orders_2024_03 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- 3.3.2 分区裁剪演示

-- 查看查询使用的分区
EXPLAIN
SELECT * FROM orders_partitioned
WHERE created_at >= '2024-02-15'
AND created_at < '2024-03-15';

-- 输出应显示只扫描两个分区：
-- -> Seq Scan on orders_2024_02
-- -> Seq Scan on orders_2024_03

-- 3.3.3 分区管理

-- 查看所有分区
SELECT
    relname,
    reltuples::bigint as row_count
FROM pg_class
WHERE relname LIKE 'orders_2024%'
ORDER BY relname;

-- 归档旧分区（detach后处理）
ALTER TABLE orders_partitioned DETACH PARTITION orders_2024_01;
ALTER TABLE orders_partitioned ATTACH PARTITION orders_2024_01
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

---

## 4. 物化视图与预计算

### 4.1 物化视图原理

```
物化视图 vs 虚拟视图 原理对比

┌─────────────────────────────────────────────────────────────────────────┐
│                        Virtual View (普通视图)                          │
│                                                                         │
│  定义：SELECT 查询的存储表示，每次查询时执行                              │
│                                                                         │
│  CREATE VIEW monthly_sales AS                                          │
│  SELECT DATE_TRUNC('month', created_at) as month,                      │
│         SUM(total_amount) as revenue                                    │
│  FROM orders                                                            │
│  GROUP BY DATE_TRUNC('month', created_at);                             │
│                                                                         │
│  每次查询:                                                               │
│  → 执行完整聚合计算                                                      │
│  → 适合小数据量，实时性要求高                                            │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                        Materialized View (物化视图)                     │
│                                                                         │
│  定义：存储查询结果为实际表数据                                           │
│                                                                         │
│  CREATE MATERIALIZED VIEW monthly_sales AS                              │
│  SELECT DATE_TRUNC('month', created_at) as month,                       │
│         SUM(total_amount) as revenue                                    │
│  FROM orders                                                            │
│  GROUP BY DATE_TRUNC('month', created_at);                             │
│                                                                         │
│  存储结构：                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ month      | revenue                                            │   │
│  ├────────────┼─────────────┤                                       │   │
│  │ 2024-01-01 | 1500000.00  │ ← 预计算结果，存储为表                  │   │
│  │ 2024-02-01 | 1800000.00  │                                       │   │
│  │ 2024-03-01 | 2100000.00  │                                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  查询: 直接读取预计算结果，毫秒级响应                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 物化视图实战

```sql
-- 4.2.1 创建物化视图

-- 销售汇总物化视图
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT
    DATE(o.created_at) as sale_date,
    p.category,
    p.region,
    COUNT(DISTINCT o.user_id) as unique_customers,
    COUNT(*) as order_count,
    SUM(oi.quantity) as total_items,
    SUM(oi.subtotal) as total_revenue
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY DATE(o.created_at), p.category, p.region;

-- 创建唯一索引（支持CONCURRENTLY刷新）
CREATE UNIQUE INDEX ON mv_daily_sales(sale_date, category, region);

-- 4.2.2 物化视图查询性能对比

-- 原始查询（直接查表）
EXPLAIN (ANALYZE, TIMING) 
SELECT 
    category,
    SUM(total_revenue) as revenue
FROM (
    SELECT
        p.category,
        oi.subtotal
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'completed'
    AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
) sub
GROUP BY category;

-- 结果：actual time=2500.123..2500.456 rows=5 loops=1
-- 耗时：约2.5秒

-- 物化视图查询
EXPLAIN (ANALYZE, TIMING)
SELECT 
    category,
    SUM(total_revenue) as revenue
FROM mv_daily_sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY category;

-- 结果：actual time=0.123..0.456 rows=5 loops=1
-- 耗时：约0.1毫秒
-- 性能提升：25000x

-- 4.2.3 物化视图刷新策略

-- 同步刷新（阻塞读写）
REFRESH MATERIALIZED VIEW mv_daily_sales;

-- 异步刷新（不阻塞，支持CONCURRENTLY）
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales;

-- 定时刷新脚本（Cloud Scheduler + Cloud Functions）
-- */30 * * * * psql -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales;"
```

### 4.3 增量物化视图

```sql
-- 4.3.1 增量刷新实现

-- 创建增量日志表
CREATE TABLE sales_incremental_log (
    log_id BIGSERIAL PRIMARY KEY,
    sale_date DATE NOT NULL,
    category VARCHAR(50),
    region VARCHAR(50),
    delta_revenue DECIMAL(12,2),
    delta_orders INT,
    last_refresh TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建触发器记录增量
CREATE OR REPLACE FUNCTION record_sales_delta()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO sales_incremental_log (sale_date, category, region, delta_revenue, delta_orders)
        VALUES (
            NEW.created_at::DATE,
            (SELECT category FROM products WHERE product_id = NEW.product_id),
            (SELECT region FROM products WHERE product_id = NEW.product_id),
            NEW.subtotal,
            1
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_items_incremental
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION record_sales_delta();

-- 4.3.2 增量刷新物化视图
CREATE OR REPLACE FUNCTION refresh_sales_mv()
RETURNS VOID AS $$
BEGIN
    -- 删除已刷新数据
    DELETE FROM mv_daily_sales
    WHERE sale_date IN (SELECT DISTINCT sale_date FROM sales_incremental_log);

    -- 插入增量数据
    INSERT INTO mv_daily_sales
    SELECT
        sale_date,
        category,
        region,
        0 as unique_customers,  -- 简化处理
        SUM(delta_orders) as order_count,
        0 as total_items,      -- 简化处理
        SUM(delta_revenue) as total_revenue
    FROM sales_incremental_log
    GROUP BY sale_date, category, region;

    -- 清空增量日志
    TRUNCATE sales_incremental_log;
END;
$$ LANGUAGE plpgsql;

-- 执行增量刷新
SELECT refresh_sales_mv();
```

---

## 5. 向量化执行与并行查询

### 5.1 向量化执行原理

```
向量化执行 vs 行式执行 原理对比

┌─────────────────────────────────────────────────────────────────────────┐
│                        Row-by-Row Execution                             │
│                                                                         │
│  处理方式：逐行处理，每个操作处理一行                                      │
│                                                                         │
│  for each row in dataset:                                               │
│      result = compute(row)                                              │
│                                                                         │
│  问题：                                                                  │
│  • CPU分支预测失败                                                       │
│  • 缓存未命中                                                          │
│  • 函数调用开销                                                          │
│  • SIMD指令未利用                                                      │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                        Vectorized Execution                             │
│                                                                         │
│  处理方式：批量处理，每次处理一批行（1024/2048行）                          │
│                                                                         │
│  for batch in dataset:                                                  │
│      result = vectorized_compute(batch)                                 │
│                                                                         │
│  优势：                                                                  │
│  • 减少分支预测失败                                                      │
│  • 提高缓存命中率                                                        │
│  • 减少函数调用次数                                                      │
│  • 利用SIMD并行计算                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 并行查询配置

```sql
-- 5.2.1 查看并行查询配置

-- 最大并行worker数
SHOW max_worker_processes;        -- 通常为CPU核心数

-- 并行查询相关参数
SHOW max_parallel_workers_per_gather;  -- 每个gather节点的最大worker
SHOW parallel_setup_cost;              -- 启动worker的成本阈值
SHOW parallel_tuple_cost;              -- 每行元组的并行成本
SHOW min_parallel_table_scan_size;    -- 触发并行扫描的最小表大小

-- 查看当前查询的并行度
EXPLAIN (VERBOSE)
SELECT COUNT(*) FROM orders;

-- 输出示例：
-- Finalize Aggregate  (cost=... rows=1 width=8)
--   -> Parallel Gather Motion   (4 slices)
--         -> Parallel Seq Scan on orders
-- 注意：Parallel Gather Motion 表示使用了并行查询
```

### 5.3 强制并行查询

```sql
-- 5.3.1 控制并行度

-- 启用并行查询（默认开启）
SET enable_parallelism = on;

-- 设置每个gather节点的worker数
SET max_parallel_workers_per_gather = 4;

-- 强制使用并行扫描（大表）
SET enable_seqscan = off;  -- 强制使用索引或并行扫描

-- 测试查询
EXPLAIN ANALYZE
SELECT
    user_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
GROUP BY user_id;

-- 5.3.2 并行查询优化示例

-- 大表聚合（启用并行）
EXPLAIN ANALYZE
SELECT
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM orders
GROUP BY DATE_TRUNC('month', created_at);

-- 预期输出：
/*
Finalize GroupAggregate
  -> Gather Motion (4 slices)
     -> Partial GroupAggregate
        -> Parallel Seq Scan on orders
*/

-- 5.3.3 控制worker进程数

-- 为特定查询设置并行度
SET max_parallel_workers_per_gather = 8;
SET max_parallel_workers = 16;

-- 大表JOIN并行化
EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.total_amount,
    u.username
FROM orders o
INNER JOIN users u ON o.user_id = u.user_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '7 days';

-- 预期输出显示 Parallel Hash Join
```

---

## 6. 实际性能调优案例

### 6.1 案例1：亿级订单表查询优化

```sql
-- 6.1.1 环境信息
-- 表大小：1亿+ 订单记录
-- 表结构：orders (order_id, user_id, total_amount, status, created_at, ...)
-- 原始查询耗时：45秒

-- 6.1.2 问题分析

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    DATE(created_at) as date,
    COUNT(*) as orders,
    SUM(total_amount) as revenue
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
AND status = 'completed'
GROUP BY DATE(created_at);

-- 执行计划问题：
-- • Seq Scan on orders (全表扫描)
-- • Filter: status = 'completed' (过滤效率低)
-- • Sort: order by date (内存排序溢出)

-- 6.1.3 优化措施

-- Step 1: 添加筛选列索引
CREATE INDEX CONCURRENTLY idx_orders_status_created
ON orders(status, created_at DESC)
WHERE status = 'completed';

-- Step 2: 添加统计信息收集
ANALYZE orders;

-- Step 3: 创建物化视图
CREATE MATERIALIZED VIEW mv_orders_daily_stats AS
SELECT
    DATE(created_at) as sale_date,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM orders
WHERE status = 'completed'
GROUP BY DATE(created_at);

CREATE UNIQUE INDEX ON mv_orders_daily_stats(sale_date);

-- Step 4: 验证优化效果
EXPLAIN (ANALYZE, TIMING)
SELECT * FROM mv_orders_daily_stats
WHERE sale_date >= CURRENT_DATE - INTERVAL '90 days';

-- 优化后耗时：15毫秒（性能提升 3000x）
```

### 6.2 案例2：复杂JOIN优化

```sql
-- 6.2.1 问题查询
-- 三表JOIN，涉及订单、用户、产品
-- 原始耗时：28秒

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT
    o.order_id,
    u.username,
    u.email,
    p.product_name,
    oi.quantity,
    oi.subtotal
FROM orders o
INNER JOIN users u ON o.user_id = u.user_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
AND p.category = 'electronics'
ORDER BY o.created_at DESC
LIMIT 100;

-- 问题分析：
-- • Nested Loop with function scans (低效)
-- • 驱动表选择不当
-- • 缺少排序列索引

-- 6.2.2 优化措施

-- Step 1: 优化JOIN顺序（确保小表驱动大表）
-- 添加hint（如果使用pg_hint_plan）

-- Step 2: 添加必要索引
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
CREATE INDEX CONCURRENTLY idx_order_items_order_id ON order_items(order_id);
CREATE INDEX CONCURRENTLY idx_order_items_product_id ON order_items(product_id);
CREATE INDEX CONCURRENTLY idx_products_category ON products(category);

-- Step 3: 创建覆盖索引
CREATE INDEX CONCURRENTLY idx_orders_covering
ON orders(created_at DESC)
INCLUDE (order_id, user_id, status);

-- Step 4: 优化排序列
CREATE INDEX CONCURRENTLY idx_orders_created ON orders(created_at DESC);

-- 优化后耗时：120毫秒（性能提升 230x）
```

### 6.3 案例3：实时分析看板优化

```sql
-- 6.3.1 原始需求
-- 实时展示：今日订单数、销售额、客单价、TOP商品
-- 数据量：实时增长，每分钟刷新
-- 原始方案：每次查询都执行聚合

-- 6.3.2 优化方案：分层缓存

-- Layer 1: 今日实时数据（增量更新）
CREATE TABLE real_time_stats (
    stat_key VARCHAR(50) PRIMARY KEY,
    stat_value JSONB,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Layer 2: 历史数据物化视图（每小时刷新）
CREATE MATERIALIZED VIEW mv_hourly_stats AS
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM orders
GROUP BY DATE_TRUNC('hour', created_at);

-- 6.3.3 查询实现

CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    today_realtime JSONB;
    history_data JSONB;
BEGIN
    -- 获取今日实时数据
    SELECT stat_value INTO today_realtime
    FROM real_time_stats
    WHERE stat_key = 'today_stats';

    -- 获取历史数据（过去24小时）
    SELECT jsonb_agg(jsonb_build_object(
        'hour', hour,
        'orders', order_count,
        'revenue', revenue
    )) INTO history_data
    FROM mv_hourly_stats
    WHERE hour >= CURRENT_DATE - INTERVAL '24 hours';

    -- 组合结果
    result := jsonb_build_object(
        'today', today_realtime,
        'hourly_history', history_data,
        'generated_at', NOW()
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 调用：SELECT get_dashboard_stats();
-- 响应时间：< 50毫秒
```

---

## 7. 监控与诊断

### 7.1 关键监控指标

```sql
-- 7.1.1 查询性能监控

-- 启用 pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 最耗时查询 TOP 20
SELECT
    substring(query, 1, 100) as query_preview,
    calls,
    total_exec_time / 1000 as total_seconds,
    mean_exec_time as avg_ms,
    rows,
    ROUND(mean_exec_time * calls / 1000, 2) as estimated_cost
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- 最频繁查询 TOP 10
SELECT
    substring(query, 1, 100),
    calls,
    rows,
    mean_exec_time
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;

-- IO密集查询
SELECT
    query,
    shared_blks_read,
    shared_blks_hit,
    ROUND(shared_blks_hit * 100.0 / NULLIF(shared_blks_hit + shared_blks_read, 0), 2) as cache_hit_pct
FROM pg_stat_statements
WHERE shared_blks_read > 0
ORDER BY shared_blks_read DESC
LIMIT 10;
```

### 7.2 性能诊断SQL

```sql
-- 7.2.1 诊断长时间运行的查询

SELECT
    pid,
    usename,
    application_name,
    state,
    now() - query_start as duration,
    substring(query, 1, 80) as query_preview
FROM pg_stat_activity
WHERE state != 'idle'
AND query_start < NOW() - INTERVAL '5 minutes'
ORDER BY duration DESC;

-- 7.2.2 诊断锁等待

SELECT
    l.locktype,
    l.relation::regclass,
    l.mode,
    l.granted,
    l.pid,
    a.usename,
    a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.granted
ORDER BY l.pid;

-- 7.2.3 诊断表膨胀

SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    n_dead_tup,
    n_live_tup,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_pct,
    last_autovacuum,
    last_vacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;
```

### 7.3 性能基准测试

```sql
-- 7.3.1 标准基准测试查询

-- TPC-H Query 1 (订单统计)
EXPLAIN (ANALYZE, TIMING)
SELECT
    l_returnflag,
    l_linestatus,
    SUM(l_quantity) as sum_qty,
    SUM(l_extendedprice) as sum_base_price,
    SUM(l_extendedprice * (1 - l_discount)) as sum_disc_price,
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
    AVG(l_quantity) as avg_qty,
    AVG(l_extendedprice) as avg_price,
    AVG(l_discount) as avg_disc,
    COUNT(*) as count_order
FROM order_lineitems
WHERE l_shipdate <= DATE '1998-12-01' - INTERVAL '90 days'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;

-- 7.3.2 写入基准测试

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_count INT := 100;
    batch_size INT := 1000;
BEGIN
    start_time := clock_timestamp();

    FOR i IN 1..batch_count LOOP
        INSERT INTO test_records (user_id, event_type, event_data)
        SELECT
            gen_random_uuid(),
            'benchmark',
            jsonb_build_object('batch', i)
        FROM generate_series(1, batch_size);
    END LOOP;

    end_time := clock_timestamp();

    RAISE NOTICE 'Inserted % rows in % seconds',
        batch_count * batch_size,
        EXTRACT(EPOCH FROM (end_time - start_time));
END $$;

-- 7.3.3 基准测试结果解读

-- 写入性能参考：
-- • COPY: 50,000-100,000 行/秒
-- • 批量INSERT: 10,000-50,000 行/秒
-- • 单行INSERT: 1,000-5,000 行/秒

-- 查询性能参考：
-- • 简单SELECT (有索引): < 10 毫秒
-- • 聚合查询 (无优化): 1-10 秒
-- • 聚合查询 (物化视图): < 100 毫秒
-- • JOIN查询 (有索引): 10-500 毫秒
```

---

[← 返回目录](../README.md#目录)
