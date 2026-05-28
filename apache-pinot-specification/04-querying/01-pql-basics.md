# Pinot 查询语言基础

## 概述

本文档介绍 Apache Pinot 的查询语言，包括 PQL（Pinot Query Language）和 ANSI SQL 支持。

---

## 1. 查询语言选择

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 查询语言对比                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  PQL (Pinot Query Language)                                              │
│  ─────────────────────────────                                          │
│  ├── Pinot 原生查询语言                                                   │
│  ├── 语法简单，易于上手                                                   │
│  ├── 支持基本聚合和过滤                                                   │
│  └── 不支持 JOIN、子查询等复杂操作                                        │
│                                                                          │
│  ANSI SQL                                                                │
│  ─────────────────                                                      │
│  ├── 标准 SQL 语法                                                        │
│  ├── 功能丰富，支持复杂查询                                               │
│  ├── 支持 JOIN、子查询、窗口函数等                                        │
│  └── 推荐使用                                                            │
│                                                                          │
│  本文档主要介绍 ANSI SQL 语法                                            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 基础查询

### 2.1 SELECT 语句

```sql
-- 查询所有列
SELECT * FROM orders LIMIT 10;

-- 查询指定列
SELECT user_id, event_type, revenue FROM orders LIMIT 10;

-- 去重查询
SELECT DISTINCT country FROM orders;

-- 别名
SELECT 
  user_id AS user,
  revenue AS amount
FROM orders;
```

### 2.2 WHERE 子句

```sql
-- 等值过滤
SELECT * FROM orders WHERE country = 'US';

-- 范围过滤
SELECT * FROM orders WHERE revenue BETWEEN 100 AND 500;
SELECT * FROM orders WHERE timestamp > 1704067200000;

-- IN 操作
SELECT * FROM orders WHERE country IN ('US', 'UK', 'CA');

-- LIKE 操作
SELECT * FROM orders WHERE user_id LIKE 'user%';

-- 多条件组合
SELECT * FROM orders 
WHERE country = 'US' 
  AND revenue > 100 
  AND timestamp > now() - 86400000;

-- NULL 检查
SELECT * FROM orders WHERE device_type IS NULL;
SELECT * FROM orders WHERE device_type IS NOT NULL;
```

### 2.3 ORDER BY 和 LIMIT

```sql
-- 排序
SELECT * FROM orders ORDER BY revenue DESC LIMIT 10;

-- 多列排序
SELECT * FROM orders ORDER BY country ASC, revenue DESC LIMIT 10;

-- 分页（Offset）
SELECT * FROM orders ORDER BY timestamp DESC LIMIT 10 OFFSET 20;
```

---

## 3. 聚合查询

### 3.1 基础聚合函数

```sql
-- 计数
SELECT COUNT(*) AS total_orders FROM orders;

-- 去重计数
SELECT COUNT(DISTINCT user_id) AS unique_users FROM orders;

-- 求和
SELECT SUM(revenue) AS total_revenue FROM orders;

-- 平均值
SELECT AVG(revenue) AS avg_revenue FROM orders;

-- 最大/最小值
SELECT MAX(revenue) AS max_revenue, MIN(revenue) AS min_revenue FROM orders;

-- 组合聚合
SELECT 
  COUNT(*) AS total_orders,
  COUNT(DISTINCT user_id) AS unique_users,
  SUM(revenue) AS total_revenue,
  AVG(revenue) AS avg_revenue,
  MAX(revenue) AS max_revenue,
  MIN(revenue) AS min_revenue
FROM orders;
```

### 3.2 GROUP BY

```sql
-- 单维度分组
SELECT 
  country,
  COUNT(*) AS total_orders,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY country;

-- 多维度分组
SELECT 
  country,
  device_type,
  COUNT(*) AS total_orders,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY country, device_type;

-- HAVING 过滤
SELECT 
  country,
  COUNT(*) AS total_orders,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY country
HAVING COUNT(*) > 1000
ORDER BY total_revenue DESC;
```

---

## 4. 时间查询

### 4.1 时间函数

```sql
-- 当前时间
SELECT now() AS current_time;

-- 时间转换
SELECT 
  ToDateTime(timestamp, 'yyyy-MM-dd HH:mm:ss') AS formatted_time,
  ToDateTime(timestamp, 'yyyy-MM-dd') AS date_only
FROM orders;

-- 时间提取
SELECT 
  year(timestamp) AS year,
  month(timestamp) AS month,
  day(timestamp) AS day,
  hour(timestamp) AS hour,
  dayOfWeek(timestamp) AS day_of_week
FROM orders;

-- 时间 bucket
SELECT 
  ToDateTime(timestamp, 'yyyy-MM-dd HH') AS hour_bucket,
  COUNT(*) AS events
FROM orders
GROUP BY hour_bucket
ORDER BY hour_bucket;
```

### 4.2 时间范围查询

```sql
-- 最近 1 小时
SELECT * FROM orders WHERE timestamp > now() - 3600000;

-- 最近 1 天
SELECT * FROM orders WHERE timestamp > now() - 86400000;

-- 最近 7 天
SELECT * FROM orders WHERE timestamp > now() - 604800000;

-- 指定日期范围
SELECT * FROM orders 
WHERE timestamp BETWEEN 1704067200000 AND 1706745600000;

-- 昨天数据
SELECT * FROM orders 
WHERE timestamp > now() - 172800000 
  AND timestamp < now() - 86400000;
```

---

## 5. 高级函数

### 5.1 字符串函数

```sql
-- 字符串连接
SELECT concat(first_name, ' ', last_name) AS full_name FROM users;

-- 子串
SELECT substring(user_id, 1, 4) AS user_prefix FROM orders;

-- 长度
SELECT length(user_id) AS id_length FROM orders;

-- 替换
SELECT replace(country, 'USA', 'US') AS normalized_country FROM orders;

-- 大小写转换
SELECT lower(country), upper(country) FROM orders;

-- 分割
SELECT split(user_id, '_', 0) AS user_type FROM orders;
```

### 5.2 数学函数

```sql
-- 四舍五入
SELECT round(revenue, 2) AS rounded_revenue FROM orders;

-- 取整
SELECT floor(revenue), ceil(revenue) FROM orders;

-- 绝对值
SELECT abs(revenue_change) FROM orders;

-- 取模
SELECT mod(user_id_hash, 100) AS bucket FROM orders;

-- 随机数
SELECT rand() AS random_value FROM orders;
```

### 5.3 JSON 函数

```sql
-- 提取 JSON 字段
SELECT 
  JSONEXTRACTSCALAR(properties, '$.device.os', 'STRING') AS os,
  JSONEXTRACTSCALAR(properties, '$.device.browser', 'STRING') AS browser
FROM events;

-- 提取 JSON 数组
SELECT 
  JSONEXTRACTARRAY(tags, 'STRING') AS tag_list
FROM events;

-- JSON 路径查询
SELECT 
  JSONEXTRACTSCALAR(metadata, '$.user.preferences.language', 'STRING') AS language
FROM events;
```

---

## 6. 查询优化提示

### 6.1 过滤优化

```sql
-- 好的做法：先过滤再聚合
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM orders
WHERE timestamp > now() - 86400000  -- 先过滤时间
GROUP BY country;

-- 避免：全表扫描
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY country;
```

### 6.2 索引使用

```sql
-- 使用有索引的列过滤
SELECT * FROM orders 
WHERE user_id = 'user123'  -- 有倒排索引
  AND timestamp > now() - 3600000;  -- 有排序索引

-- 避免：对无索引列过滤
SELECT * FROM orders 
WHERE description LIKE '%keyword%';  -- 无索引，全表扫描
```

---

## 参考链接

- [Pinot Query Language](https://docs.pinot.apache.org/users/user-guide-query/pinot-query-language)
- [Pinot SQL Support](https://docs.pinot.apache.org/users/user-guide-query/query-syntax)
- [Pinot Query Optimizations](https://docs.pinot.apache.org/users/user-guide-query/query-optimization)
