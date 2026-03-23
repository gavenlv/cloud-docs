# Doris性能调优

## 概述

本文档介绍Doris的性能调优技巧，包括SQL调优、集群配置优化、物化视图和资源管理。

## SQL调优

### 分析执行计划

```sql
-- 查看查询执行计划
EXPLAIN SELECT * FROM table_name WHERE condition;

-- 详细执行计划
EXPLAIN ANALYZE SELECT * FROM table_name WHERE condition;

-- 查看分布式执行计划
EXPLAIN VERTICAL SELECT * FROM table_name WHERE condition;
```

### 常见SQL调优技巧

#### 1. 避免SELECT *

```sql
-- 错误：查询所有列
SELECT * FROM large_table WHERE condition;

-- 正确：只查询需要的列
SELECT col1, col2, col3 FROM large_table WHERE condition;
```

#### 2. 使用预聚合函数

```sql
-- 错误：在应用层计算
SELECT
    SUM(col1) as total,
    COUNT(DISTINCT col2) as unique_count
FROM table_name;

-- 正确：使用近似函数
SELECT
    SUM(col1) as total,
    APPROX_COUNT_DISTINCT(col2) as unique_count
FROM table_name;
```

#### 3. 利用分区裁剪

```sql
-- 错误：全表扫描
SELECT * FROM table_name WHERE year = 2024;

-- 正确：利用分区裁剪
SELECT * FROM table_name WHERE partition_column = '2024-01-01';
```

#### 4. 优化JOIN

```sql
-- 错误：大表JOIN大表
SELECT a.*, b.*
FROM large_table1 a
JOIN large_table2 b ON a.id = b.id;

-- 正确：先过滤再JOIN
SELECT a.*, b.*
FROM (SELECT * FROM large_table1 WHERE condition) a
JOIN (SELECT * FROM large_table2 WHERE condition) b ON a.id = b.id;

-- 使用broadcast JOIN
SET enable_broadcast_join = true;
```

### 索引优化

```sql
-- 创建Bloom Filter索引
ALTER TABLE table_name SET ("bloom_filter_columns" = "col1,col2");

-- 查看表的索引信息
SHOW INDEX FROM table_name;
```

## 集群配置优化

### BE配置优化

```bash
# be.conf 配置示例
# 读取并发数（根据CPU核心数调整）
streaming_loader_count = 10
tablet_writer_count = 16

# 查询并发数
query_load_count = 32

# 内存配置
mem_limit = 32G

# Tablet数量限制
max_tablet_num = 1000
```

### FE配置优化

```sql
-- 动态配置
ADMIN SET FRONTEND CONFIG ("max_connections_per_user" = "100");
ADMIN SET FRONTEND CONFIG ("query_timeout" = "3600");
ADMIN SET FRONTEND CONFIG ("max_execution_time" = "3600");
```

### 常用配置项

| 配置项 | 说明 | 默认值 | 建议值 |
|--------|------|--------|--------|
| parallel_fragment_exec_instance_num | 单节点并行数 | 1 | CPU核心数/2 |
| parallel_pipeline_task_num | Pipeline并发数 | 0 | CPU核心数 |
| batch_size | 批处理大小 | 4096 | 8192-16384 |
| query_timeout | 查询超时(秒) | 300 | 3600 |

## 物化视图

### 创建物化视图

```sql
-- 创建聚合物化视图
CREATE MATERIALIZED VIEW mv_agg
AS
SELECT
    date,
    SUM(revenue) as total_revenue,
    COUNT(DISTINCT user_id) as unique_users
FROM order_table
GROUP BY date;

-- 创建明细物化视图
CREATE MATERIALIZED VIEW mv_detail
AS
SELECT
    o.order_id,
    o.user_id,
    o.date,
    u.username,
    u.email
FROM order_table o
JOIN user_table u ON o.user_id = u.user_id;

-- 创建预计算物化视图
CREATE MATERIALIZED VIEW mv_monthly
AS
SELECT
    DATE_TRUNC(date, 'month') as month,
    category,
    SUM(amount) as total_amount
FROM sales_table
GROUP BY 1, 2;
```

### 物化视图管理

```sql
-- 查看物化视图
SHOW ALTER TABLE MATERIALIZED VIEW;

-- 查看物化视图状态
SHOW MATERIALIZED VIEW;

-- 删除物化视图
DROP MATERIALIZED VIEW mv_name;
```

### 物化视图自动匹配

```sql
-- 物化视图会被自动选择
-- 原始查询
SELECT date, SUM(revenue) FROM order_table GROUP BY date;

-- Doris会自动使用mv_agg物化视图
EXPLAIN SELECT date, SUM(revenue) FROM order_table GROUP BY date;
```

## 资源管理

### 查询队列

```sql
-- 创建资源组
CREATE RESOURCE GROUP resource_group_1
PROPERTIES (
    "cpu_share" = "10",
    "memory_limit" = "10G",
    "max_concurrency" = "100"
);

-- 分配查询到资源组
SET PROPERTY 'default_resource_group' = 'resource_group_1';
```

### 内存管理

```sql
-- 查看内存使用
SHOW PROC '/mem_tracker';

-- 设置查询内存限制
SET GLOBAL exec_mem_limit = 8589934592;  -- 8GB
```

### 并发控制

```sql
-- 设置用户并发限制
ALTER USER 'user_name' DEFAULT ROLE
PROPERTIES (
    'max_user_connections' = '100'
);

-- 查看当前连接
SHOW PROCESSLIST;

-- 杀死慢查询
KILL QUERY 'query_id';
```

## 统计信息

### 收集统计信息

```sql
-- 收集表统计信息
ANALYZE TABLE table_name;

-- 收集列统计信息
ANALYZE TABLE table_name (col1, col2);

-- 查看统计信息
SHOW TABLE STATS table_name;
SHOW COLUMN STATS table_name;
```

### 自动统计信息

```sql
-- 开启自动统计信息收集
SET GLOBAL enable_auto_sample = true;

-- 设置收集策略
ADMIN SET FRONTEND CONFIG ("auto_collect_large_table_statistics_row_count_threshold" = "100000000");
```

## 性能调优最佳实践

### 表设计优化

1. **合理使用数据模型**
   - Aggregate模型：预聚合场景
   - Unique模型：实时更新场景
   - Duplicate模型：日志分析场景

2. **分区设计**
   - 按时间分区
   - 单分区数据量控制在10GB-100GB
   - 历史数据可按月/季度分区

3. **分桶设计**
   - 选择高基列
   - Bucket数量 = BE节点数 × 10
   - 避免数据倾斜

### 查询优化

1. **预热数据**
```sql
-- 触发热点数据加载
SELECT * FROM hot_table LIMIT 1;
```

2. **使用CBO优化器**
```sql
SET enable_cost_based_join_reorder = true;
SET enable_rewrite_rules = true;
```

3. **批量操作**
```sql
-- 批量插入
INSERT INTO table_name SELECT * FROM source_table;

-- 批量删除
DELETE FROM table_name WHERE id IN (1, 2, 3, 4, 5);
```
