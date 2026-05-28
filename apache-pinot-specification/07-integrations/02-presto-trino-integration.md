# Pinot 与 Presto/Trino 集成

## 概述

本文档介绍 Apache Pinot 与 Presto/Trino 的集成，实现联邦查询和更丰富的 SQL 功能。

---

## 1. 集成架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot + Trino 集成架构                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │  客户端  │────>│  Trino   │────>│  Pinot   │────>│  数据源  │      │
│  │          │     │  Coordinator│  │  Connector│     │          │      │
│  └──────────┘     └──────────┘     └──────────┘     └──────────┘      │
│                                                                          │
│  优势：                                                                  │
│  ─────────────────                                                      │
│  ├── 联邦查询：跨多个数据源查询                                          │
│  ├── 丰富 SQL：支持 JOIN、子查询、窗口函数                               │
│  ├── 统一接口：一个查询引擎访问所有数据                                  │
│  └── 性能优化：Trino 优化器 + Pinot 索引                                 │
│                                                                          │
│  支持的数据源：                                                          │
│  ─────────────────                                                      │
│  ├── Pinot（OLAP）                                                       │
│  ├── Hive（数据仓库）                                                    │
│  ├── MySQL/PostgreSQL（关系型数据库）                                    │
│  ├── MongoDB（文档数据库）                                               │
│  └── 其他 JDBC/Connector 支持的数据源                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Trino 配置

### 2.1 安装 Pinot Connector

```bash
# 下载 Pinot Connector
cd $TRINO_HOME/plugin
mkdir pinot

cp pinot-trino-plugin-*.jar pinot/
cp pinot-all-*.jar pinot/

# 添加依赖
cp guava-*.jar pinot/
cp jackson-*.jar pinot/
cp slf4j-*.jar pinot/
cp grpc-*.jar pinot/
cp protobuf-*.jar pinot/
cp netty-*.jar pinot/
cp commons-lang3-*.jar pinot/
```

### 2.2 配置 Catalog

```properties
# etc/catalog/pinot.properties
connector.name=pinot
pinot.controller-urls=pinot-controller:9000

# 可选配置
pinot.broker-url=pinot-broker:8099
pinot.segments-per-split=10
pinot.request-timeout=30s
pinot.connection-timeout=10s
```

### 2.3 高级配置

```properties
# etc/catalog/pinot.properties
connector.name=pinot
pinot.controller-urls=pinot-controller-0:9000,pinot-controller-1:9000

# 查询优化
pinot.pushdown-topn-broker-queries=true
pinot.pushdown-aggregate-broker-queries=true
pinot.pushdown-project-expressions=true

# 连接池
pinot.connection-timeout=10s
pinot.request-timeout=60s
pinot.metadata-expiry=2m

# 认证（如需要）
pinot.controller.authentication.type=token
pinot.controller.authentication.token=secret-token
```

---

## 3. 查询示例

### 3.1 基础查询

```sql
-- 查询 Pinot 表
SELECT * FROM pinot.default.user_events LIMIT 10;

-- 聚合查询
SELECT 
  country,
  COUNT(*) AS total_events,
  SUM(revenue) AS total_revenue
FROM pinot.default.user_events
WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '1' DAY
GROUP BY country;

-- 时间序列查询
SELECT 
  DATE_TRUNC('hour', FROM_UNIXTIME(timestamp / 1000)) AS hour,
  COUNT(*) AS event_count,
  SUM(revenue) AS revenue
FROM pinot.default.user_events
WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '7' DAY
GROUP BY hour
ORDER BY hour;
```

### 3.2 联邦查询

```sql
-- Pinot + MySQL 联邦查询
SELECT 
  p.user_id,
  p.total_revenue,
  u.user_name,
  u.email
FROM (
  SELECT 
    user_id,
    SUM(revenue) AS total_revenue
  FROM pinot.default.user_events
  WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '30' DAY
  GROUP BY user_id
) p
JOIN mysql.default.users u ON p.user_id = u.user_id;

-- Pinot + Hive 联邦查询
SELECT 
  p.country,
  p.today_revenue,
  h.yesterday_revenue,
  p.today_revenue - h.yesterday_revenue AS revenue_change
FROM (
  SELECT 
    country,
    SUM(revenue) AS today_revenue
  FROM pinot.default.user_events
  WHERE DATE(FROM_UNIXTIME(timestamp / 1000)) = CURRENT_DATE
  GROUP BY country
) p
JOIN (
  SELECT 
    country,
    SUM(revenue) AS yesterday_revenue
  FROM hive.default.daily_revenue
  WHERE dt = DATE_FORMAT(CURRENT_DATE - INTERVAL '1' DAY, '%Y-%m-%d')
  GROUP BY country
) h ON p.country = h.country;
```

### 3.3 复杂查询

```sql
-- 窗口函数
SELECT 
  user_id,
  event_time,
  revenue,
  SUM(revenue) OVER (
    PARTITION BY user_id 
    ORDER BY event_time 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_revenue,
  AVG(revenue) OVER (
    PARTITION BY user_id 
    ORDER BY event_time 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_avg
FROM pinot.default.user_events;

-- 复杂 JOIN
SELECT 
  p.user_id,
  p.event_type,
  p.revenue,
  u.user_segment,
  c.campaign_name
FROM pinot.default.user_events p
JOIN mysql.default.users u ON p.user_id = u.user_id
LEFT JOIN mysql.default.campaigns c ON p.campaign_id = c.campaign_id
WHERE p.timestamp > CURRENT_TIMESTAMP - INTERVAL '1' DAY;
```

---

## 4. 性能优化

### 4.1 查询下推

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Trino 查询下推优化                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  下推类型：                                                              │
│  ─────────────────                                                      │
│  ├── 聚合下推：SUM、COUNT、AVG 等                                        │
│  ├── 过滤下推：WHERE 条件                                                │
│  ├── 投影下推：SELECT 列                                                 │
│  ├── LIMIT 下推                                                          │
│  └── TOPN 下推：ORDER BY + LIMIT                                         │
│                                                                          │
│  配置：                                                                  │
│  ─────────────────                                                      │
│  pinot.pushdown-topn-broker-queries=true                                │
│  pinot.pushdown-aggregate-broker-queries=true                           │
│  pinot.pushdown-project-expressions=true                                │
│                                                                          │
│  验证下推：                                                              │
│  ─────────────────                                                      │
│  EXPLAIN ANALYZE                                                        │
│  SELECT country, SUM(revenue)                                           │
│  FROM pinot.default.user_events                                         │
│  WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '1' DAY                 │
│  GROUP BY country;                                                      │
│                                                                          │
│  查看执行计划中的 Fragment 是否包含 PinotTableHandle                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 连接池配置

```properties
# etc/catalog/pinot.properties
pinot.controller-urls=pinot-controller:9000

# 连接池
pinot.connection-timeout=10s
pinot.request-timeout=60s
pinot.metadata-expiry=2m

# 并发控制
pinot.segments-per-split=10
pinot.max-connections-per-server=10
```

---

## 5. 监控

### 5.1 Trino 指标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Trino + Pinot 监控指标                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  指标名称                          │  说明                              │
│  ──────────────────────────────────┼────────────────────────────────────│
│  trino_pinot_request_latency       │  Pinot 请求延迟                    │
│  trino_pinot_request_error_count   │  Pinot 请求错误数                  │
│  trino_pinot_segments_queried      │  查询的 Segment 数                 │
│  trino_pinot_rows_returned         │  返回的行数                        │
│  trino_pinot_bytes_returned        │  返回的字节数                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 参考链接

- [Trino Pinot Connector](https://trino.io/docs/current/connector/pinot.html)
- [Presto Pinot Connector](https://prestodb.io/docs/current/connector/pinot.html)
- [Pinot Querying](https://docs.pinot.apache.org/users/user-guide-query/querying-pinot)
