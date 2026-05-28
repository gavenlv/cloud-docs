# Pinot 与 Apache Superset 集成

## 概述

本文档介绍 Apache Pinot 与 Apache Superset 的集成，实现数据可视化和仪表盘。

---

## 1. 集成架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot + Superset 集成架构                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │  用户    │────>│ Superset │────>│  Pinot   │────>│  数据源  │      │
│  │          │     │  Dashboard│    │  Broker  │     │          │      │
│  └──────────┘     └──────────┘     └──────────┘     └──────────┘      │
│                                                                          │
│  连接方式：                                                              │
│  ─────────────────                                                      │
│  ├── Pinot DBAPI（原生支持）                                             │
│  ├── SQLAlchemy URI                                                      │
│  └── Trino/Presto（联邦查询）                                            │
│                                                                          │
│  可视化功能：                                                            │
│  ─────────────────                                                      │
│  ├── 图表：Table、Bar、Line、Pie 等                                      │
│  ├── 仪表盘：多图表组合                                                  │
│  ├── 过滤器：时间、维度                                                  │
│  └── 实时刷新：自动数据更新                                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 配置连接

### 2.1 使用 Pinot DBAPI

```python
# superset_config.py
# 安装 Pinot 依赖
# pip install pinotdb

# 数据库连接
DATABASES = {
    'pinot': {
        'SQLALCHEMY_DATABASE_URI': 'pinot://pinot-broker:8099/query/sql?controller=pinot-controller:9000'
    }
}
```

### 2.2 Superset UI 配置

```
1. 登录 Superset
2. 导航到 Data > Databases
3. 点击 + Database
4. 填写连接信息：
   - Database Name: Pinot
   - SQLAlchemy URI: pinot://pinot-broker:8099/query/sql?controller=pinot-controller:9000
5. 点击 Test Connection
6. 保存
```

### 2.3 高级配置

```
SQLAlchemy URI 格式：
pinot://<broker_host>:<broker_port>/query/sql?controller=<controller_host>:<controller_port>&scheme=http

示例：
pinot://pinot-broker:8099/query/sql?controller=pinot-controller:9000

带认证：
pinot://username:password@pinot-broker:8099/query/sql?controller=pinot-controller:9000
```

---

## 3. 数据集配置

### 3.1 创建数据集

```sql
-- 在 Superset 中创建数据集
-- 导航到 Data > Datasets
-- 点击 + Dataset
-- 选择 Pinot 数据库
-- 选择 Schema 和 Table

-- 或者使用 SQL Lab
SELECT 
  country,
  event_type,
  COUNT(*) AS total_events,
  SUM(revenue) AS total_revenue,
  AVG(revenue) AS avg_revenue
FROM user_events
GROUP BY country, event_type;
```

### 3.2 虚拟数据集

```sql
-- 创建虚拟数据集（复杂查询）
SELECT 
  DATE_TRUNC('hour', TO_TIMESTAMP(timestamp / 1000)) AS hour,
  country,
  COUNT(*) AS events,
  SUM(revenue) AS revenue,
  COUNT(DISTINCT user_id) AS unique_users
FROM user_events
WHERE timestamp > EXTRACT(EPOCH FROM NOW() - INTERVAL '7 days') * 1000
GROUP BY hour, country;
```

---

## 4. 图表配置

### 4.1 时间序列图表

```
图表类型：Line Chart

配置：
- Time Column: hour
- Metrics: SUM(revenue)
- Dimensions: country
- Filters: 
  - timestamp > now - 7 days

SQL：
SELECT 
  DATE_TRUNC('hour', TO_TIMESTAMP(timestamp / 1000)) AS hour,
  country,
  SUM(revenue) AS revenue
FROM user_events
WHERE timestamp > EXTRACT(EPOCH FROM NOW() - INTERVAL '7 days') * 1000
GROUP BY hour, country
ORDER BY hour;
```

### 4.2 表格图表

```
图表类型：Table

配置：
- Dimensions: country, event_type
- Metrics: COUNT(*), SUM(revenue), AVG(revenue)
- Sort: SUM(revenue) DESC
- Row Limit: 100

SQL：
SELECT 
  country,
  event_type,
  COUNT(*) AS total_events,
  SUM(revenue) AS total_revenue,
  AVG(revenue) AS avg_revenue
FROM user_events
WHERE timestamp > EXTRACT(EPOCH FROM NOW() - INTERVAL '1 day') * 1000
GROUP BY country, event_type
ORDER BY total_revenue DESC
LIMIT 100;
```

### 4.3 地图图表

```
图表类型：World Map

配置：
- Country Column: country
- Metric: SUM(revenue)
- Filters: timestamp > now - 1 day

SQL：
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM user_events
WHERE timestamp > EXTRACT(EPOCH FROM NOW() - INTERVAL '1 day') * 1000
GROUP BY country;
```

---

## 5. 仪表盘配置

### 5.1 创建仪表盘

```
1. 导航到 Dashboards
2. 点击 + Dashboard
3. 添加图表：
   - 实时收入趋势（Line Chart）
   - 国家分布（World Map）
   - 事件类型分布（Pie Chart）
   - Top 10 用户（Table）
4. 添加过滤器：
   - 时间范围
   - 国家
   - 事件类型
5. 设置自动刷新：10 秒
```

### 5.2 实时仪表盘

```
实时配置：
- 刷新间隔：10 秒
- 查询时间范围：最近 1 小时
- 使用 Pinot 实时表

过滤器配置：
- 时间范围：Last hour
- 国家：多选
- 事件类型：多选

图表联动：
- 点击地图国家 -> 过滤其他图表
- 点击饼图事件类型 -> 过滤其他图表
```

---

## 6. 性能优化

### 6.1 查询优化

```sql
-- 使用 Pinot 索引
SELECT 
  country,
  SUM(revenue) AS total_revenue
FROM user_events
WHERE timestamp > EXTRACT(EPOCH FROM NOW() - INTERVAL '1 hour') * 1000
  AND country IN ('US', 'UK', 'CA')
GROUP BY country;

-- 限制返回行数
SELECT * FROM user_events LIMIT 1000;

-- 使用预计算指标
SELECT 
  country,
  precomputed_revenue
FROM user_events_star_tree;
```

### 6.2 缓存配置

```python
# superset_config.py
# 启用缓存
CACHE_CONFIG = {
    'CACHE_TYPE': 'redis',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_HOST': 'redis',
    'CACHE_REDIS_PORT': 6379,
    'CACHE_REDIS_DB': 1,
    'CACHE_REDIS_URL': 'redis://redis:6379/1'
}

# 数据集缓存
DATASET_CACHE_CONFIG = {
    'CACHE_TYPE': 'redis',
    'CACHE_DEFAULT_TIMEOUT': 600,
    'CACHE_KEY_PREFIX': 'superset_dataset_',
    'CACHE_REDIS_URL': 'redis://redis:6379/2'
}
```

---

## 参考链接

- [Apache Superset](https://superset.apache.org/)
- [Pinot DBAPI](https://github.com/python-pinot-dbapi/pinot-dbapi)
- [Superset Documentation](https://superset.apache.org/docs/intro)
