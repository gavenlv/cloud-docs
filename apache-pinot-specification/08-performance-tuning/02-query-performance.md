# Pinot 查询性能优化

## 概述

本文档介绍 Apache Pinot 的查询性能优化方法和最佳实践。

---

## 1. 查询优化原则

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 查询优化原则                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. 减少数据扫描                                                         │
│  ─────────────────                                                      │
│  ├── 使用合适的索引                                                      │
│  ├── 添加时间范围过滤                                                    │
│  ├── 使用分区键过滤                                                      │
│  └── 避免全表扫描                                                        │
│                                                                          │
│  2. 减少网络传输                                                         │
│  ─────────────────                                                      │
│  ├── 只查询需要的列                                                      │
│  ├── 使用 LIMIT 限制返回行数                                             │
│  ├── 在 Server 端完成聚合                                                │
│  └── 避免大结果集                                                        │
│                                                                          │
│  3. 利用预计算                                                           │
│  ─────────────────                                                      │
│  ├── 使用 Star-Tree 索引                                                 │
│  ├── 使用物化视图                                                        │
│  ├── 预计算常用聚合                                                      │
│  └── 使用字典编码                                                        │
│                                                                          │
│  4. 优化查询结构                                                         │
│  ─────────────────                                                      │
│  ├── 简化复杂查询                                                        │
│  ├── 避免嵌套子查询                                                      │
│  ├── 使用合适的 JOIN 类型                                                │
│  └── 避免笛卡尔积                                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 过滤优化

### 2.1 时间过滤

```sql
-- 好的做法：使用时间范围过滤
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM orders
WHERE timestamp > now() - 86400000  -- 最近 1 天
GROUP BY country;

-- 避免：无时间过滤
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY country;
```

### 2.2 索引列过滤

```sql
-- 好的做法：使用有索引的列
SELECT * FROM orders 
WHERE user_id = 'user123'  -- 有倒排索引
  AND timestamp > now() - 3600000;  -- 有排序索引

-- 避免：对无索引列过滤
SELECT * FROM orders 
WHERE description LIKE '%keyword%';  -- 无索引，全表扫描
```

### 2.3 复合过滤

```sql
-- 好的做法：索引列在前
SELECT * FROM orders 
WHERE country = 'US'  -- 有倒排索引
  AND timestamp > now() - 3600000  -- 有排序索引
  AND revenue > 100;  -- 无索引，但数据已减少

-- 避免：非索引列在前
SELECT * FROM orders 
WHERE revenue > 100  -- 无索引
  AND country = 'US';  -- 有索引，但已扫描大量数据
```

---

## 3. 聚合优化

### 3.1 使用 Star-Tree 索引

```sql
-- 创建 Star-Tree 索引
{
  "tableIndexConfig": {
    "starTreeIndexConfigs": [
      {
        "dimensionsSplitOrder": ["country", "event_type"],
        "functionColumnPairs": ["SUM__revenue", "COUNT__*"]
      }
    ]
  }
}

-- 查询自动使用 Star-Tree
SELECT 
  country,
  event_type,
  SUM(revenue) AS total_revenue,
  COUNT(*) AS total_orders
FROM orders
WHERE timestamp > now() - 86400000
GROUP BY country, event_type;
```

### 3.2 减少分组维度

```sql
-- 好的做法：减少 GROUP BY 列
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY country;

-- 避免：过多分组列
SELECT 
  country,
  city,
  device_type,
  event_type,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY country, city, device_type, event_type;
```

---

## 4. JOIN 优化

### 4.1 小表驱动

```sql
-- 好的做法：小表在左
SELECT 
  o.user_id,
  o.revenue,
  u.country
FROM small_table u  -- 小表
JOIN large_table o ON u.user_id = o.user_id  -- 大表
WHERE o.timestamp > now() - 86400000;

-- 避免：大表在左
SELECT 
  o.user_id,
  o.revenue,
  u.country
FROM large_table o  -- 大表
JOIN small_table u ON u.user_id = o.user_id  -- 小表
WHERE o.timestamp > now() - 86400000;
```

### 4.2 过滤下推

```sql
-- 好的做法：先过滤再 JOIN
SELECT 
  o.user_id,
  o.revenue,
  u.country
FROM (
  SELECT user_id, revenue 
  FROM orders 
  WHERE timestamp > now() - 86400000
) o
JOIN users u ON o.user_id = u.user_id;

-- 避免：先 JOIN 再过滤
SELECT 
  o.user_id,
  o.revenue,
  u.country
FROM orders o
JOIN users u ON o.user_id = u.user_id
WHERE o.timestamp > now() - 86400000;
```

---

## 5. 查询提示

### 5.1 超时设置

```sql
-- 设置查询超时
SELECT /*+ timeoutMs(30000) */ 
  country, SUM(revenue) 
FROM orders 
GROUP BY country;
```

### 5.2 禁用 Star-Tree

```sql
-- 强制不使用 Star-Tree（用于测试）
SELECT /*+ useStarTree(false) */ 
  country, SUM(revenue) 
FROM orders 
GROUP BY country;
```

### 5.3 最大行数限制

```sql
-- 限制返回行数
SELECT /*+ maxLimit(1000) */ 
  * FROM orders;
```

---

## 6. 性能监控

### 6.1 查询统计

```bash
# 查看查询统计
curl -X POST http://pinot-broker:8099/query/sql \
  -H "Content-Type: application/json" \
  -d '{
    "sql": "SELECT * FROM orders LIMIT 10",
    "trace": true
  }'

# 查看 Server 查询统计
curl http://pinot-server:8097/debug/queries
```

### 6.2 慢查询分析

```sql
-- 启用查询跟踪
SET trace = true;

SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM orders
WHERE timestamp > now() - 86400000
GROUP BY country;

-- 查看执行计划
EXPLAIN PLAN FOR
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM orders
WHERE timestamp > now() - 86400000
GROUP BY country;
```

---

## 参考链接

- [Pinot Query Optimization](https://docs.pinot.apache.org/users/user-guide-query/query-optimization)
- [Pinot Query Syntax](https://docs.pinot.apache.org/users/user-guide-query/query-syntax)
- [Pinot Performance Tuning](https://docs.pinot.apache.org/operators/operating-pinot/tuning-pinot)
