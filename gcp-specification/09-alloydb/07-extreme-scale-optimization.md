# AlloyDB 千亿级数据优化

## 本章概述

本章专门针对单表超过1000亿行（万亿级数据）的极端场景，介绍分区策略、数据归档、分层存储、时间序列优化和查询优化实践。

## 学习目标

- 掌握超大规模数据的分区设计
- 理解冷热数据分离和归档策略
- 学会实现分层存储架构
- 掌握极端规模下的查询优化技巧

---

## 1. 千亿级数据挑战分析

### 1.1 规模换算

```
1000亿行数据规模分析

┌─────────────────────────────────────────────────────────────────────────┐
│                        数据规模参考                                     │
│                                                                         │
│  1000亿行 (1 Trillion Rows)                                            │
│  ─────────────────────────────────────                                 │
│                                                                         │
│  估算存储：                                                              │
│  • 平均每行 200 字节 → 约 2 TB 原始数据                                │
│  • 列式存储压缩 (5-10x) → 200-400 GB 压缩后                           │
│  • 索引开销 (20-30%) → 240-520 GB 总存储                             │
│                                                                         │
│  估算内存：                                                              │
│  • 索引缓存建议: 64-128 GB                                             │
│  • 工作内存: 32-64 GB                                                  │
│                                                                         │
│  估算查询时间：                                                          │
│  • 全表聚合: 30-120 秒 (无优化)                                       │
│  • 分区裁剪后: 0.5-5 秒                                               │
│  • 物化视图: < 1 秒                                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 核心挑战

```
千亿级数据核心挑战

┌─────────────────────────────────────────────────────────────────────────┐
│                        挑战矩阵                                         │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 1. 索引失效                                                      │   │
│  │    • B-tree 索引过大，内存无法完全缓存                            │   │
│  │    • 索引深度增加，查询延迟上升                                   │   │
│  │    • 解决: 分区 + 局部索引                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 2. 统计信息不准确                                                │   │
│  │    • ANALYZE 采样不充分                                          │   │
│  │    • 查询计划选择错误                                             │   │
│  │    解决: 增强统计、自适应查询                                     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 3. VACUUM 开销大                                                 │   │
│  │    • 死元组积累多，清理时间长                                     │   │
│  │    • 影响写入性能                                                 │   │
│  │    解决: 频繁归档、及时清理                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 4. 备份/恢复时间长                                               │   │
│  │    • 全量备份可能需要数小时                                        │   │
│  │    解决: 增量备份 + 分区备份                                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 分区策略设计

### 2.1 分区方案选择

```sql
-- 2.1.1 分区策略对比

/*
┌─────────────────────────────────────────────────────────────────────────┐
│                        分区策略选择                                      │
│                                                                         │
│  ┌─────────────────┬─────────────────┬─────────────────┐               │
│  │    策略         │     优点        │      缺点       │               │
│  ├─────────────────┼─────────────────┼─────────────────┤               │
│  │ 按时间分区      │ 管理简单         │ 热数据不均匀     │               │
│  │ (最推荐)        │ 自动归档方便     │ 可能产生碎片     │               │
│  ├─────────────────┼─────────────────┼─────────────────┤               │
│  │ 按哈希分区      │ 数据均匀分布     │ 范围查询需扫描   │               │
│  │                 │ 并行度高         │ 所有分区         │               │
│  ├─────────────────┼─────────────────┼─────────────────┤               │
│  │ 按列表分区      │ 按业务分类      │ 需预先定义       │               │
│  │                 │ 查询定向         │ 不够灵活         │               │
│  ├─────────────────┼─────────────────┼─────────────────┤               │
│  │ 复合分区        │ 灵活性高        │ 复杂性高         │               │
│  │ (时间+哈希)     │ 适应多种查询    │ 维护成本高       │               │
│  └─────────────────┴─────────────────┴─────────────────┘               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
*/

-- 2.1.2 推荐分区方案：按月分区

CREATE TABLE events_100b (
    event_id UUID NOT NULL,
    user_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
) PARTITION BY RANGE (created_at);

-- 创建月度分区 (保留3年 = 36个分区)
DO $$
DECLARE
    start_date DATE := '2024-01-01';
    end_date DATE := '2024-02-01';
    partition_name TEXT;
BEGIN
    FOR i IN 0..35 LOOP
        partition_name := 'events_' || TO_CHAR(start_date + (i || ' months')::interval, 'YYYY_MM');

        EXECUTE format(
            'CREATE TABLE %I PARTITION OF events_100b FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            start_date + (i || ' months')::interval,
            start_date + ((i + 1) || ' months')::interval
        );
    END LOOP;
END $$;

-- 2.1.3 验证分区
SELECT
    relname,
    reltuples::bigint as estimated_rows
FROM pg_class
WHERE relname LIKE 'events_202%'
ORDER BY relname;
```

### 2.2 分区表索引设计

```sql
-- 2.2.1 分区表全局索引 vs 局部索引

-- 全局索引 (所有分区共享)
-- 优点: 查询不需要知道分区键
-- 缺点: 索引庞大，跨分区查询可能使用全局索引

CREATE INDEX idx_events_global ON events_100b(user_id);

-- 局部索引 (每个分区独立)
-- 优点: 索引小，查询只扫描相关分区
-- 缺点: 创建/维护需在每个分区执行

CREATE INDEX idx_events_local ON events_2024_01(created_at);

-- 为每个分区创建相同索引 (自动化脚本)
DO $$
DECLARE
    partition_name TEXT;
BEGIN
    FOR partition_name IN
        SELECT relname FROM pg_class WHERE relname LIKE 'events_202%'
    LOOP
        EXECUTE format(
            'CREATE INDEX IF NOT EXISTS %I ON %I(created_at, event_type)',
            'idx_' || partition_name || '_ct',
            partition_name
        );
    END LOOP;
END $$;

-- 2.2.2 分区索引优化：覆盖索引

-- 只查询分区局部索引即可满足，避免回表
CREATE INDEX idx_events_covering
ON events_100b(event_type, created_at)
INCLUDE (event_id, user_id, event_data);

-- 2.2.3 条件索引（只索引热点数据）

-- 只索引最近6个月的数据
CREATE INDEX idx_events_hot
ON events_100b(created_at DESC)
WHERE created_at >= CURRENT_DATE - INTERVAL '6 months';
```

### 2.3 分区裁剪验证

```sql
-- 2.3.1 验证分区裁剪

EXPLAIN
SELECT *
FROM events_100b
WHERE created_at >= '2024-06-01'
AND created_at < '2024-07-01';

-- 期望输出 (只扫描一个分区):
/*
Append
  -> Index Scan using events_2024_06_created_at_idx on events_2024_06
        Index Cond: (created_at >= '2024-06-01' AND created_at < '2024-07-01')
*/

-- 2.3.2 多分区查询

EXPLAIN
SELECT
    DATE_TRUNC('day', created_at) as day,
    COUNT(*) as event_count
FROM events_100b
WHERE created_at >= '2024-01-01'
AND created_at < '2024-04-01'
GROUP BY DATE_TRUNC('day', created_at);

-- 期望输出 (分区裁剪后扫描3个分区):
/*
Append
  -> Index Scan using events_2024_01_created_at_idx on events_2024_01
  -> Index Scan using events_2024_02_created_at_idx on events_2024_02
  -> Index Scan using events_2024_03_created_at_idx on events_2024_03
*/
```

---

## 3. 数据归档策略

### 3.1 冷热数据分离

```
冷热数据分离架构

┌─────────────────────────────────────────────────────────────────────────┐
│                        分层存储架构                                      │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      热数据层 (Hot)                               │   │
│  │  • 最近 1-3 个月                                                 │   │
│  │  • SSD 存储                                                     │   │
│  │  • 完整功能访问                                                 │   │
│  │  • 内存缓存                                                      │   │
│  │  • SLA: < 100ms 查询延迟                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      温数据层 (Warm)                             │   │
│  │  • 3-12 个月                                                     │   │
│  │  • 标准存储                                                      │   │
│  │  • 索引查询                                                      │   │
│  │  • SLA: < 1s 查询延迟                                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      冷数据层 (Cold)                              │   │
│  │  • 1-3 年                                                        │   │
│  │  • 低成本存储                                                    │   │
│  │  • 可能需要重建索引                                              │   │
│  │  • SLA: < 1min 查询延迟                                         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      归档层 (Archive)                            │   │
│  │  • 3 年以上                                                      │   │
│  │  • 压缩文件/对象存储                                            │   │
│  │  • 按需恢复                                                      │   │
│  │  • SLA: 小时级恢复                                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 自动化归档实现

```sql
-- 3.2.1 创建归档表结构

-- 归档表（存储冷数据）
CREATE TABLE events_archive (
    event_id UUID NOT NULL,
    user_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
) PARTITION BY RANGE (created_at);

-- 3.2.2 归档存储过程

CREATE OR REPLACE FUNCTION archive_old_events(
    archive_before_date DATE,
    batch_size INT DEFAULT 100000
) RETURNS TABLE(archived_count BIGINT) AS $$
DECLARE
    archived BIGINT := 0;
    partition_name TEXT;
BEGIN
    -- 为归档数据创建分区
    partition_name := 'events_archive_' || TO_CHAR(archive_before_date, 'YYYY_MM');

    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF events_archive
         FOR VALUES FROM (%L) TO (%L)',
        partition_name,
        DATE_TRUNC('month', archive_before_date),
        DATE_TRUNC('month', archive_before_date) + INTERVAL '1 month'
    );

    -- 分批移动数据
    LOOP
        WITH moved AS (
            DELETE FROM events_100b
            WHERE created_at < archive_before_date
            LIMIT batch_size
            RETURNING *
        )
        INSERT INTO events_archive
        SELECT * FROM moved;

        GET DIAGNOSTICS archived = ROW_COUNT;
        EXIT WHEN archived = 0;

        RAISE NOTICE 'Archived % rows', archived;
    END LOOP;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- 3.2.3 执行归档

-- 归档2023年之前的数据
SELECT * FROM archive_old_events('2024-01-01'::DATE, 500000);

-- 3.2.4 归档验证

-- 查看主表和归档表的记录数
SELECT
    'events_100b' as table_name,
    COUNT(*) as row_count
FROM events_100b
UNION ALL
SELECT
    'events_archive' as table_name,
    COUNT(*) as row_count
FROM events_archive;
```

### 3.3 分区 detach/attach 操作

```sql
-- 3.3.1 Detach 分区（快速归档）

-- 将月度分区转为独立表
ALTER TABLE events_100b DETACH PARTITION events_2023_01;

-- 将独立表 attach 到归档表
ALTER TABLE events_archive ATTACH PARTITION events_2023_01
    FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');

-- 3.3.2 完整归档流程

-- 1. 创建归档表月度分区
CREATE TABLE events_archive_2023_01
PARTITION OF events_archive
FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');

-- 2. 将数据从一个分区移动到另一个
INSERT INTO events_archive_2023_01
SELECT * FROM events_100b_2023_01;

-- 3. 删除原分区
DROP TABLE events_100b_2023_01;

-- 4. 验证
SELECT COUNT(*) FROM events_archive_2023_01;
```

---

## 4. 物化视图分层架构

### 4.1 预计算分层

```sql
-- 4.1.1 实时预聚合视图

-- 分钟级聚合（保留7天）
CREATE MATERIALIZED VIEW mv_events_minute_recent AS
SELECT
    DATE_TRUNC('minute', created_at) as minute,
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM events_100b
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE_TRUNC('minute', created_at), event_type
WITH DATA;

CREATE UNIQUE INDEX ON mv_events_minute_recent(minute, event_type);

-- 4.1.2 小时级聚合（保留30天）

CREATE MATERIALIZED VIEW mv_events_hourly_recent AS
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM events_100b
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('hour', created_at), event_type
WITH DATA;

CREATE UNIQUE INDEX ON mv_events_hourly_recent(hour, event_type);

-- 4.1.3 天级聚合（保留1年）

CREATE MATERIALIZED VIEW mv_events_daily_recent AS
SELECT
    DATE_TRUNC('day', created_at) as day,
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM events_100b
WHERE created_at >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY DATE_TRUNC('day', created_at), event_type
WITH DATA;

CREATE UNIQUE INDEX ON mv_events_daily_recent(day, event_type);

-- 4.1.4 月级聚合（永久保留）

CREATE MATERIALIZED VIEW mv_events_monthly AS
SELECT
    DATE_TRUNC('month', created_at) as month,
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users
FROM events_100b
GROUP BY DATE_TRUNC('month', created_at), event_type
WITH DATA;

CREATE UNIQUE INDEX ON mv_events_monthly(month, event_type);
```

### 4.2 分层查询路由

```sql
-- 4.2.1 智能查询路由函数

CREATE OR REPLACE FUNCTION query_events_analytics(
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    event_type VARCHAR DEFAULT NULL
) RETURNS TABLE(
    period TIMESTAMP WITH TIME ZONE,
    event_type VARCHAR,
    event_count BIGINT,
    unique_users BIGINT
) AS $$
BEGIN
    -- 策略：按时间范围选择最合适的物化视图
    -- 实时 (< 7天): 直接查分区表
    -- 分钟级 (7-30天): mv_events_minute_recent
    -- 小时级 (30天-1年): mv_events_hourly_recent
    -- 天级 (1年+): mv_events_daily_recent
    -- 月级 (全量统计): mv_events_monthly

    IF end_date - start_date <= INTERVAL '7 days' THEN
        -- 直接查询分区表
        RETURN QUERY
        SELECT
            DATE_TRUNC('minute', e.created_at) as period,
            e.event_type,
            COUNT(*) as event_count,
            COUNT(DISTINCT e.user_id) as unique_users
        FROM events_100b e
        WHERE e.created_at >= start_date AND e.created_at < end_date
        AND (event_type IS NULL OR e.event_type = query_events_analytics.event_type)
        GROUP BY DATE_TRUNC('minute', e.created_at), e.event_type;

    ELSIF end_date - start_date <= INTERVAL '30 days' THEN
        -- 查询分钟物化视图
        RETURN QUERY
        SELECT
            m.minute as period,
            m.event_type,
            m.event_count,
            m.unique_users
        FROM mv_events_minute_recent m
        WHERE m.minute >= start_date AND m.minute < end_date
        AND (event_type IS NULL OR m.event_type = query_events_analytics.event_type);

    ELSIF end_date - start_date <= INTERVAL '1 year' THEN
        -- 查询小时物化视图
        RETURN QUERY
        SELECT
            m.hour as period,
            m.event_type,
            m.event_count,
            m.unique_users
        FROM mv_events_hourly_recent m
        WHERE m.hour >= start_date AND m.hour < end_date
        AND (event_type IS NULL OR m.event_type = query_events_analytics.event_type);

    ELSE
        -- 查询天级物化视图
        RETURN QUERY
        SELECT
            m.day as period,
            m.event_type,
            m.event_count,
            m.unique_users
        FROM mv_events_daily_recent m
        WHERE m.day >= start_date AND m.day < end_date
        AND (event_type IS NULL OR m.event_type = query_events_analytics.event_type);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 4.2.2 使用示例

-- 查询最近7天（自动选择最佳路径）
SELECT * FROM query_events_analytics(
    CURRENT_DATE - INTERVAL '7 days',
    CURRENT_DATE,
    'page_view'
);

-- 查询最近6个月（自动选择小时物化视图）
SELECT * FROM query_events_analytics(
    CURRENT_DATE - INTERVAL '6 months',
    CURRENT_DATE,
    NULL
);
```

---

## 5. 极限查询优化

### 5.1 采样查询

```sql
-- 5.1.1 近似计数（适用于大表）

-- 使用 TABLESAMPLE 减少扫描量
SELECT
    event_type,
    COUNT(*) * 10 as estimated_count  -- 假设 10% 采样
FROM events_100b TABLESAMPLE SYSTEM (10)
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY event_type;

-- 5.1.2 近似聚合函数

-- 安装 pg_sampletalk 扩展（如果可用）
-- 或使用 HyperLogLog 近似计数

-- 创建 HyperLogLog 状态表
CREATE TABLE hll_events (
    day DATE,
    event_type VARCHAR(50),
    users_hll BYTEA
);

-- 插入 HyperLogLog 数据
INSERT INTO hll_events
SELECT
    DATE(created_at),
    event_type,
    hll_empty() || hll_add_element(hll_empty(), user_id::text)
FROM events_100b
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at), event_type, user_id;

-- 查询近似去重计数
SELECT
    day,
    event_type,
    hll_cardinality(hll_union_agg(users_hll)) as unique_users
FROM hll_events
GROUP BY day, event_type;
```

### 5.2 并行查询优化

```sql
-- 5.2.1 强制并行查询

-- 设置最大并行度
SET max_parallel_workers_per_gather = 8;
SET parallel_leader_participation = off;
SET max_parallel_maintenance_workers = 4;

-- 5.2.2 大表并行聚合

EXPLAIN (ANALYZE, TIMING)
SELECT
    event_type,
    COUNT(*) as cnt,
    COUNT(DISTINCT user_id) as users
FROM events_100b
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY event_type;

-- 期望输出显示 Parallel Append
/*
Finalize GroupAggregate
  -> Parallel Append
     -> Partial GroupAggregate
        -> Parallel Index Scan using events_2024_06_created_at_idx on events_2024_06
     -> Partial GroupAggregate
        -> Parallel Index Scan using events_2024_07_created_at_idx on events_2024_07
*/

-- 5.2.3 并行 COPY 导入

COPY events_100b FROM '/data/events_2024_06.csv' WITH (
    FORMAT csv,
    PARALLEL TRUE  -- 如果数据源支持并行
);
```

### 5.3 增量查询模式

```sql
-- 5.3.1 基线 + 增量查询

-- 创建基线快照（每日凌晨）
CREATE TABLE events_baseline AS
SELECT
    event_type,
    DATE_TRUNC('day', created_at) as day,
    COUNT(*) as base_count,
    COUNT(DISTINCT user_id) as base_users
FROM events_100b
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY event_type, DATE_TRUNC('day', created_at);

CREATE UNIQUE INDEX ON events_baseline(event_type, day);

-- 增量查询
CREATE OR REPLACE FUNCTION get_daily_stats(
    target_date DATE
) RETURNS TABLE(event_type VARCHAR, count BIGINT, users BIGINT) AS $$
DECLARE
    baseline_count BIGINT;
    baseline_users BIGINT;
    current_count BIGINT;
    current_users BIGINT;
BEGIN
    -- 获取基线数据
    SELECT base_count, base_users INTO baseline_count, baseline_users
    FROM events_baseline
    WHERE day = target_date;

    -- 获取当日数据
    SELECT COUNT(*), COUNT(DISTINCT user_id)
    INTO current_count, current_users
    FROM events_100b
    WHERE DATE(created_at) = target_date;

    -- 如果有增量，返回增量；否则返回基线
    IF current_count > 0 THEN
        RETURN QUERY
        SELECT event_type, current_count, current_users;
    ELSE
        RETURN QUERY
        SELECT event_type, baseline_count, baseline_users
        FROM events_baseline
        WHERE day = target_date;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 5.3.2 物化视图增量刷新

CREATE OR REPLACE FUNCTION refresh_incremental_mv(
    target_date DATE
) RETURNS VOID AS $$
BEGIN
    -- 删除旧数据
    DELETE FROM mv_events_daily_recent
    WHERE day = target_date;

    -- 插入新数据
    INSERT INTO mv_events_daily_recent
    SELECT
        DATE_TRUNC('day', created_at) as day,
        event_type,
        COUNT(*) as event_count,
        COUNT(DISTINCT user_id) as unique_users
    FROM events_100b
    WHERE DATE(created_at) = target_date
    GROUP BY DATE_TRUNC('day', created_at), event_type;
END;
$$ LANGUAGE plpgsql;
```

---

## 6. 监控与容量规划

### 6.1 分区级监控

```sql
-- 6.1.1 各分区数据量统计

SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    reltuples::bigint as row_count,
    (reltuples / pg_relation_size(schemaname||'.'||tablename) * 8192)::bigint as bytes_per_row
FROM pg_class
WHERE relname LIKE 'events_202%'
ORDER BY relname;

-- 6.1.2 分区增长趋势

SELECT
    partition_name,
    row_count,
    size_bytes,
    size_bytes - LAG(size_bytes) OVER (ORDER BY partition_name) as growth
FROM (
    SELECT
        relname as partition_name,
        reltuples::bigint as row_count,
        pg_total_relation_size(relid) as size_bytes
    FROM pg_class
    WHERE relname LIKE 'events_202%'
) sub
ORDER BY partition_name;

-- 6.1.3 归档进度监控

SELECT
    'events_100b' as table_name,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE created_at < CURRENT_DATE - INTERVAL '1 year') as old_rows
FROM events_100b;
```

### 6.2 容量规划SQL

```sql
-- 6.2.1 存储容量预测

WITH daily_stats AS (
    SELECT
        DATE_TRUNC('day', created_at) as day,
        COUNT(*) as daily_rows,
        pg_total_relation_size('events_100b') / 
            NULLIF(COUNT(*), 0) as bytes_per_row
    FROM events_100b
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE_TRUNC('day', created_at)
)
SELECT
    AVG(daily_rows) as avg_daily_rows,
    AVG(bytes_per_row) as avg_bytes_per_row,
    AVG(daily_rows) * 365 * AVG(bytes_per_row) / 1024 / 1024 / 1024 as yearly_storage_gb
FROM daily_stats;

-- 6.2.2 索引容量评估

SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    idx_scan,
    idx_tup_read,
    ROUND(idx_tup_read::numeric / NULLIF(idx_scan, 0), 2) as avg_tuples_per_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
AND relname LIKE 'events%'
ORDER BY pg_relation_size(indexrelid) DESC;
```

### 6.3 自动告警阈值

```sql
-- 6.3.1 分区大小监控

CREATE OR REPLACE FUNCTION check_partition_sizes()
RETURNS TABLE(partition_name TEXT, size_gb NUMERIC, rows BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        relname::TEXT,
        ROUND(pg_total_relation_size(relid) / 1024 / 1024 / 1024, 2),
        reltuples::bigint
    FROM pg_class
    WHERE relname LIKE 'events_202%'
    AND pg_total_relation_size(relid) > 100 * 1024 * 1024 * 1024  -- > 100GB
    ORDER BY pg_total_relation_size(relid) DESC;
END;
$$ LANGUAGE plpgsql;

-- 6.3.2 死元组监控

SELECT
    schemaname,
    tablename,
    n_dead_tup,
    n_live_tup,
    ROUND(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) as dead_pct,
    last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000000  -- 超过100万死元组
ORDER BY n_dead_tup DESC;
```

---

## 7. 极端场景最佳实践总结

```
千亿级数据最佳实践

┌─────────────────────────────────────────────────────────────────────────┐
│                        实践检查清单                                     │
│                                                                         │
│  □ 分区设计                                                              │
│    ├─ 按时间分区 (月度或周刊)                                            │
│    ├─ 每个分区 < 10亿行                                                  │
│    ├─ 分区索引局部化                                                     │
│    └─ 验证分区裁剪生效                                                   │
│                                                                         │
│  □ 索引策略                                                              │
│    ├─ 只创建必要的索引                                                   │
│    ├─ 使用覆盖索引减少回表                                               │
│    ├─ 考虑条件索引 (只索引热点数据)                                      │
│    └─ 定期分析索引使用率，删除无用索引                                    │
│                                                                         │
│  □ 数据管理                                                              │
│    ├─ 实施冷热数据分离                                                   │
│    ├─ 自动化数据归档流程                                                 │
│    ├─ 及时 detach 旧分区                                                 │
│    └─ 定期清理死元组                                                     │
│                                                                         │
│  □ 查询优化                                                              │
│    ├─ 使用物化视图预计算                                                 │
│    ├─ 实现智能查询路由                                                   │
│    ├─ 使用采样查询近似计算 (大表)                                        │
│    └─ 避免 SELECT *                                                      │
│                                                                         │
│  □ 监控运维                                                              │
│    ├─ 分区级监控粒度                                                     │
│    ├─ 设置容量告警阈值                                                   │
│    ├─ 定期评估索引效率                                                   │
│    └─ 备份策略分区化                                                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

[← 返回目录](../README.md#目录)
