# Pinot 高级查询

## 概述

本文档介绍 Apache Pinot 的高级查询功能，包括 JOIN、窗口函数、子查询、集合操作等。

---

## 1. JOIN 查询

### 1.1 内连接

```sql
-- 基础 JOIN
SELECT 
  o.user_id,
  o.revenue,
  u.country,
  u.user_type
FROM orders AS o
INNER JOIN users AS u ON o.user_id = u.user_id
WHERE o.timestamp > now() - 86400000;

-- 多表 JOIN
SELECT 
  o.order_id,
  o.revenue,
  u.user_name,
  p.product_name
FROM orders AS o
INNER JOIN users AS u ON o.user_id = u.user_id
INNER JOIN products AS p ON o.product_id = p.product_id
WHERE o.timestamp > now() - 86400000;
```

### 1.2 外连接

```sql
-- LEFT JOIN
SELECT 
  u.user_id,
  u.user_name,
  COUNT(o.order_id) AS order_count,
  COALESCE(SUM(o.revenue), 0) AS total_revenue
FROM users AS u
LEFT JOIN orders AS o ON u.user_id = o.user_id
GROUP BY u.user_id, u.user_name;

-- RIGHT JOIN
SELECT 
  o.order_id,
  o.revenue,
  u.user_name
FROM orders AS o
RIGHT JOIN users AS u ON o.user_id = u.user_id;
```

### 1.3 半连接和反连接

```sql
-- 半连接（EXISTS）
SELECT 
  u.user_id,
  u.user_name
FROM users AS u
WHERE EXISTS (
  SELECT 1 FROM orders AS o 
  WHERE o.user_id = u.user_id 
    AND o.timestamp > now() - 86400000
);

-- 反连接（NOT EXISTS）
SELECT 
  u.user_id,
  u.user_name
FROM users AS u
WHERE NOT EXISTS (
  SELECT 1 FROM orders AS o 
  WHERE o.user_id = u.user_id
);
```

---

## 2. 窗口函数

### 2.1 排名函数

```sql
-- ROW_NUMBER
SELECT 
  user_id,
  revenue,
  ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rank
FROM orders;

-- RANK
SELECT 
  user_id,
  revenue,
  RANK() OVER (ORDER BY revenue DESC) AS rank
FROM orders;

-- DENSE_RANK
SELECT 
  user_id,
  revenue,
  DENSE_RANK() OVER (ORDER BY revenue DESC) AS rank
FROM orders;

-- 分组排名
SELECT 
  country,
  user_id,
  revenue,
  ROW_NUMBER() OVER (PARTITION BY country ORDER BY revenue DESC) AS country_rank
FROM orders;
```

### 2.2 聚合窗口函数

```sql
-- 累计和
SELECT 
  date,
  revenue,
  SUM(revenue) OVER (ORDER BY date) AS cumulative_revenue
FROM daily_revenue;

-- 移动平均
SELECT 
  date,
  revenue,
  AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma7
FROM daily_revenue;

-- 分组累计
SELECT 
  country,
  date,
  revenue,
  SUM(revenue) OVER (PARTITION BY country ORDER BY date) AS country_cumulative
FROM daily_revenue;
```

### 2.3 取值窗口函数

```sql
-- LAG/LEAD
SELECT 
  date,
  revenue,
  LAG(revenue, 1) OVER (ORDER BY date) AS prev_day_revenue,
  LEAD(revenue, 1) OVER (ORDER BY date) AS next_day_revenue,
  revenue - LAG(revenue, 1) OVER (ORDER BY date) AS day_over_day_change
FROM daily_revenue;

-- FIRST_VALUE/LAST_VALUE
SELECT 
  country,
  date,
  revenue,
  FIRST_VALUE(revenue) OVER (PARTITION BY country ORDER BY date) AS first_revenue,
  LAST_VALUE(revenue) OVER (PARTITION BY country ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_revenue
FROM daily_revenue;
```

---

## 3. 子查询

### 3.1 标量子查询

```sql
-- SELECT 子查询
SELECT 
  user_id,
  revenue,
  (SELECT AVG(revenue) FROM orders) AS avg_revenue,
  revenue / (SELECT AVG(revenue) FROM orders) AS revenue_ratio
FROM orders;

-- WHERE 子查询
SELECT * FROM orders
WHERE revenue > (SELECT AVG(revenue) FROM orders);
```

### 3.2 表子查询

```sql
-- FROM 子查询
SELECT 
  country,
  AVG(total_revenue) AS avg_revenue
FROM (
  SELECT 
    country,
    user_id,
    SUM(revenue) AS total_revenue
  FROM orders
  GROUP BY country, user_id
) AS user_revenue
GROUP BY country;

-- 关联子查询
SELECT 
  o.user_id,
  o.revenue,
  (SELECT AVG(revenue) 
   FROM orders AS o2 
   WHERE o2.user_id = o.user_id) AS user_avg_revenue
FROM orders AS o;
```

---

## 4. 集合操作

### 4.1 UNION

```sql
-- UNION（去重）
SELECT user_id FROM orders_2023
UNION
SELECT user_id FROM orders_2024;

-- UNION ALL（不去重）
SELECT user_id, revenue, timestamp FROM orders_2023
UNION ALL
SELECT user_id, revenue, timestamp FROM orders_2024;
```

### 4.2 INTERSECT 和 EXCEPT

```sql
-- INTERSECT（交集）
SELECT user_id FROM orders_2023
INTERSECT
SELECT user_id FROM orders_2024;

-- EXCEPT（差集）
SELECT user_id FROM orders_2023
EXCEPT
SELECT user_id FROM orders_2024;
```

---

## 5. 高级聚合

### 5.1 GROUPING SETS

```sql
-- 多维度聚合
SELECT 
  COALESCE(country, 'ALL') AS country,
  COALESCE(device_type, 'ALL') AS device_type,
  COUNT(*) AS total_orders,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY GROUPING SETS (
  (country, device_type),
  (country),
  (device_type),
  ()
);
```

### 5.2 ROLLUP

```sql
-- 层级聚合
SELECT 
  COALESCE(year, 'ALL') AS year,
  COALESCE(month, 'ALL') AS month,
  COALESCE(day, 'ALL') AS day,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY ROLLUP (year, month, day);
```

### 5.3 CUBE

```sql
-- 所有组合聚合
SELECT 
  COALESCE(country, 'ALL') AS country,
  COALESCE(device_type, 'ALL') AS device_type,
  COALESCE(event_type, 'ALL') AS event_type,
  COUNT(*) AS total_orders,
  SUM(revenue) AS total_revenue
FROM orders
GROUP BY CUBE (country, device_type, event_type);
```

---

## 6. 近似计算

### 6.1 近似去重计数

```sql
-- HyperLogLog 近似去重
SELECT 
  country,
  DISTINCTCOUNTHLL(user_id) AS approx_unique_users
FROM orders
GROUP BY country;

-- 设置精度（更高精度 = 更多内存）
SELECT 
  country,
  DISTINCTCOUNTHLL(user_id, 12) AS approx_unique_users
FROM orders
GROUP BY country;
```

### 6.2 百分位计算

```sql
-- 精确百分位
SELECT 
  country,
  PERCENTILE(revenue, 50) AS median_revenue,
  PERCENTILE(revenue, 90) AS p90_revenue,
  PERCENTILE(revenue, 95) AS p95_revenue,
  PERCENTILE(revenue, 99) AS p99_revenue
FROM orders
GROUP BY country;

-- 近似百分位（更快）
SELECT 
  country,
  PERCENTILEEST(revenue, 50) AS approx_median,
  PERCENTILEEST(revenue, 95) AS approx_p95
FROM orders
GROUP BY country;
```

### 6.3 近似直方图

```sql
-- 生成直方图
SELECT 
  country,
  HISTOGRAM(revenue, 0, 1000, 10) AS revenue_histogram
FROM orders
GROUP BY country;
```

---

## 7. 地理空间查询

### 7.1 距离计算

```sql
-- 计算两点距离（米）
SELECT 
  ST_Distance(
    ST_GeogFromText('POINT(116.4074 39.9042)'),  -- 北京
    ST_GeogFromText('POINT(121.4737 31.2304)')   -- 上海
  ) AS distance_meters;

-- 查找附近点
SELECT 
  store_id,
  store_name,
  ST_Distance(
    ST_GeogFromText('POINT(116.4074 39.9042)'),
    ST_GeogFromText(CONCAT('POINT(', longitude, ' ', latitude, ')'))
  ) AS distance
FROM stores
WHERE ST_Distance(
  ST_GeogFromText('POINT(116.4074 39.9042)'),
  ST_GeogFromText(CONCAT('POINT(', longitude, ' ', latitude, ')'))
) < 10000  -- 10km 内
ORDER BY distance;
```

---

## 8. 查询提示

### 8.1 查询选项

```sql
-- 设置超时
SELECT /*+ timeoutMs(5000) */ * FROM orders;

-- 设置最大行数
SELECT /*+ maxLimit(1000) */ * FROM orders;

-- 禁用 Star-Tree
SELECT /*+ useStarTree(false) */ 
  country, SUM(revenue) 
FROM orders 
GROUP BY country;

-- 强制使用特定索引
SELECT /*+ useInvertedIndex(user_id) */ 
  * FROM orders 
WHERE user_id = 'user123';
```

---

## 参考链接

- [Pinot Advanced Querying](https://docs.pinot.apache.org/users/user-guide-query/query-syntax)
- [Pinot Window Functions](https://docs.pinot.apache.org/users/user-guide-query/window-functions)
- [Pinot Geospatial](https://docs.pinot.apache.org/users/user-guide-query/geospatial-data-support)
