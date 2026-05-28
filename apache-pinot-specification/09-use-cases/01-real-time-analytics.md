# Pinot 实时分析案例

## 概述

本文档介绍使用 Apache Pinot 构建实时分析平台的完整案例。

---

## 1. 场景描述

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        实时用户行为分析                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  业务场景：电商平台实时用户行为分析                                      │
│                                                                          │
│  需求：                                                                  │
│  ─────────────────                                                      │
│  ├── 实时监控用户行为                                                    │
│  ├── 实时计算 UV/PV/转化率                                               │
│  ├── 实时推荐系统支持                                                    │
│  └── 实时异常检测                                                        │
│                                                                          │
│  数据规模：                                                              │
│  ─────────────────                                                      │
│  ├── 日活用户：1000 万                                                   │
│  ├── 日事件量：10 亿                                                     │
│  ├── 峰值 QPS：50000                                                     │
│  └── 查询延迟：< 1 秒                                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 架构设计

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        实时分析架构                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  数据流：                                                                │
│  ─────────────────                                                      │
│                                                                          │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐        │
│  │ 应用日志  │───>│  Kafka   │───>│  Pinot   │───>│  实时看板  │        │
│  │ 用户事件  │    │  消息队列 │    │  实时分析 │    │  告警     │        │
│  │ 交易数据  │    └──────────┘    └──────────┘    └──────────┘        │
│  └──────────┘                                                          │
│                                                                          │
│  Pinot 集群：                                                            │
│  ─────────────────                                                      │
│  ├── Controller：3 节点（高可用）                                        │
│  ├── Broker：3 节点（查询路由）                                          │
│  ├── Server：6 节点（数据存储）                                          │
│  └── Minion：2 节点（后台任务）                                          │
│                                                                          │
│  存储：                                                                  │
│  ─────────────────                                                      │
│  ├── 本地 SSD：热数据                                                    │
│  └── S3：冷数据备份                                                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 数据模型

### 3.1 Schema 设计

```json
{
  "schemaName": "user_events",
  "enableColumnBasedNullHandling": true,
  "dimensionFieldSpecs": [
    {"name": "user_id", "dataType": "STRING", "notNull": true},
    {"name": "event_type", "dataType": "STRING", "notNull": true},
    {"name": "country", "dataType": "STRING", "notNull": false},
    {"name": "city", "dataType": "STRING", "notNull": false},
    {"name": "device_type", "dataType": "STRING", "notNull": false},
    {"name": "os", "dataType": "STRING", "notNull": false},
    {"name": "browser", "dataType": "STRING", "notNull": false},
    {"name": "page_url", "dataType": "STRING", "notNull": false},
    {"name": "referrer", "dataType": "STRING", "notNull": false},
    {"name": "product_id", "dataType": "STRING", "notNull": false},
    {"name": "category", "dataType": "STRING", "notNull": false}
  ],
  "metricFieldSpecs": [
    {"name": "revenue", "dataType": "DOUBLE", "notNull": false, "defaultNullValue": 0.0},
    {"name": "quantity", "dataType": "INT", "notNull": false, "defaultNullValue": 0},
    {"name": "session_duration", "dataType": "LONG", "notNull": false, "defaultNullValue": 0}
  ],
  "dateTimeFieldSpecs": [
    {
      "name": "timestamp",
      "dataType": "LONG",
      "notNull": true,
      "format": "1:MILLISECONDS:EPOCH",
      "granularity": "1:HOURS"
    }
  ]
}
```

### 3.2 Table 配置

```json
{
  "tableName": "user_events",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "timeType": "MILLISECONDS",
    "retentionTimeUnit": "DAYS",
    "retentionTimeValue": "30",
    "replication": "3",
    "minimizeDataMovement": true
  },
  "tenants": {
    "broker": "DefaultTenant",
    "server": "DefaultTenant"
  },
  "tableIndexConfig": {
    "loadMode": "MMAP",
    "invertedIndexColumns": [
      "user_id",
      "event_type",
      "country",
      "device_type",
      "product_id",
      "category"
    ],
    "sortedColumn": ["timestamp"],
    "rangeIndexColumns": ["timestamp", "revenue"],
    "bloomFilterColumns": ["user_id", "session_id"],
    "starTreeIndexConfigs": [
      {
        "dimensionsSplitOrder": ["country", "event_type", "device_type"],
        "functionColumnPairs": [
          "SUM__revenue",
          "COUNT__*",
          "AVG__session_duration"
        ],
        "maxLeafRecords": 10000
      }
    ],
    "enableDefaultStarTree": false,
    "enableDynamicStarTreeCreation": true,
    "nullHandlingEnabled": true
  },
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kafka",
        "stream.kafka.consumer.type": "lowlevel",
        "stream.kafka.topic.name": "user-events",
        "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.stream.kafka.KafkaJSONMessageDecoder",
        "stream.kafka.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kafka20.KafkaConsumerFactory",
        "stream.kafka.broker.list": "kafka:9092",
        "stream.kafka.consumer.prop.auto.offset.reset": "smallest",
        "stream.kafka.consumer.prop.group.id": "pinot-user-events",
        "realtime.segment.flush.threshold.rows": "5000000",
        "realtime.segment.flush.threshold.time": "1h",
        "realtime.segment.flush.threshold.segment.size": "200M"
      }
    ]
  }
}
```

---

## 4. 查询示例

### 4.1 实时监控

```sql
-- 实时 UV/PV
SELECT 
  COUNT(DISTINCT user_id) AS uv,
  COUNT(*) AS pv
FROM user_events
WHERE timestamp > now() - 3600000;

-- 实时转化率
SELECT 
  event_type,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users
FROM user_events
WHERE timestamp > now() - 3600000
GROUP BY event_type;

-- 实时收入
SELECT 
  SUM(revenue) AS total_revenue,
  COUNT(DISTINCT user_id) AS paying_users
FROM user_events
WHERE timestamp > now() - 3600000
  AND event_type = 'purchase';
```

### 4.2 趋势分析

```sql
-- 小时趋势
SELECT 
  ToDateTime(timestamp, 'yyyy-MM-dd HH:mm') AS hour,
  COUNT(DISTINCT user_id) AS uv,
  COUNT(*) AS pv,
  SUM(revenue) AS revenue
FROM user_events
WHERE timestamp > now() - 86400000
GROUP BY hour
ORDER BY hour;

-- 国家分布
SELECT 
  country,
  COUNT(DISTINCT user_id) AS uv,
  SUM(revenue) AS revenue,
  SUM(revenue) / COUNT(DISTINCT user_id) AS arpu
FROM user_events
WHERE timestamp > now() - 86400000
GROUP BY country
ORDER BY revenue DESC;
```

### 4.3 漏斗分析

```sql
-- 购买漏斗
SELECT 
  'view' AS step,
  COUNT(DISTINCT user_id) AS users
FROM user_events
WHERE event_type = 'product_view'
  AND timestamp > now() - 86400000

UNION ALL

SELECT 
  'add_to_cart' AS step,
  COUNT(DISTINCT user_id) AS users
FROM user_events
WHERE event_type = 'add_to_cart'
  AND timestamp > now() - 86400000

UNION ALL

SELECT 
  'purchase' AS step,
  COUNT(DISTINCT user_id) AS users
FROM user_events
WHERE event_type = 'purchase'
  AND timestamp > now() - 86400000;
```

---

## 5. 可视化

### 5.1 Grafana 仪表盘

```json
{
  "dashboard": {
    "title": "实时用户行为分析",
    "panels": [
      {
        "title": "实时 UV/PV",
        "type": "stat",
        "targets": [
          {
            "expr": "SELECT COUNT(DISTINCT user_id) AS uv, COUNT(*) AS pv FROM user_events WHERE timestamp > now() - 3600000",
            "format": "table"
          }
        ]
      },
      {
        "title": "实时收入",
        "type": "stat",
        "targets": [
          {
            "expr": "SELECT SUM(revenue) AS revenue FROM user_events WHERE timestamp > now() - 3600000 AND event_type = 'purchase'",
            "format": "table"
          }
        ]
      },
      {
        "title": "小时趋势",
        "type": "graph",
        "targets": [
          {
            "expr": "SELECT ToDateTime(timestamp, 'yyyy-MM-dd HH:mm') AS hour, COUNT(*) AS pv FROM user_events WHERE timestamp > now() - 86400000 GROUP BY hour ORDER BY hour",
            "format": "time_series"
          }
        ]
      }
    ]
  }
}
```

---

## 6. 性能优化

### 6.1 索引优化

```json
{
  "tableIndexConfig": {
    "invertedIndexColumns": ["user_id", "event_type", "country"],
    "sortedColumn": ["timestamp"],
    "starTreeIndexConfigs": [
      {
        "dimensionsSplitOrder": ["country", "event_type"],
        "functionColumnPairs": ["SUM__revenue", "COUNT__*"]
      }
    ]
  }
}
```

### 6.2 查询优化

```sql
-- 使用索引列过滤
SELECT * FROM user_events 
WHERE user_id = 'user123'  -- 有倒排索引
  AND timestamp > now() - 3600000;  -- 有排序索引

-- 限制返回行数
SELECT * FROM user_events LIMIT 1000;

-- 使用 Star-Tree 索引
SELECT country, SUM(revenue) FROM user_events GROUP BY country;
```

---

## 参考链接

- [Pinot Use Cases](https://docs.pinot.apache.org/users/user-guide-user-case)
- [Pinot Real-time Analytics](https://docs.pinot.apache.org/users/user-guide-user-case/real-time-analytics)
