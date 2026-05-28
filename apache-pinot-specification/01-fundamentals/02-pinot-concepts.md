# Pinot 核心概念详解

## 概述

本文档深入讲解 Apache Pinot 的核心概念，帮助读者理解 Pinot 的数据模型、配置体系和运行机制。

---

## 1. Schema 设计

### 1.1 Schema 结构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot Schema 结构                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Schema 定义了表的数据结构，包括字段名称、类型和属性：                    │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Schema 组成                                │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │                                                                  │   │
│  │  1. Dimension Fields（维度字段）                                  │   │
│  │     ├── 用于过滤和分组的字段                                      │   │
│  │     ├── 示例：user_id, country, device_type                      │   │
│  │     └── 支持的数据类型：INT, LONG, FLOAT, DOUBLE, STRING, BYTES  │   │
│  │                                                                  │   │
│  │  2. Metric Fields（度量字段）                                     │   │
│  │     ├── 用于聚合计算的字段                                        │   │
│  │     ├── 示例：revenue, page_views, latency                       │   │
│  │     └── 支持的数据类型：INT, LONG, FLOAT, DOUBLE                 │   │
│  │                                                                  │   │
│  │  3. DateTime Fields（时间字段）                                   │   │
│  │     ├── 用于时间过滤和分区的字段                                  │   │
│  │     ├── 示例：timestamp, event_time                              │   │
│  │     └── 支持格式：EPOCH, SIMPLE_DATE_FORMAT                      │   │
│  │                                                                  │   │
│  │  4. Complex Fields（复杂字段）                                    │   │
│  │     ├── JSON 类型字段                                             │   │
│  │     ├── Map 类型字段                                              │   │
│  │     └── 支持嵌套查询                                              │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Schema 配置示例

```json
{
  "schemaName": "user_events",
  "enableColumnBasedNullHandling": true,
  "dimensionFieldSpecs": [
    {
      "name": "user_id",
      "dataType": "STRING",
      "notNull": true
    },
    {
      "name": "country",
      "dataType": "STRING",
      "notNull": true
    },
    {
      "name": "device_type",
      "dataType": "STRING",
      "notNull": false,
      "defaultNullValue": "unknown"
    },
    {
      "name": "event_type",
      "dataType": "STRING",
      "notNull": true
    }
  ],
  "metricFieldSpecs": [
    {
      "name": "revenue",
      "dataType": "DOUBLE",
      "notNull": false,
      "defaultNullValue": 0.0
    },
    {
      "name": "page_views",
      "dataType": "INT",
      "notNull": false,
      "defaultNullValue": 0
    }
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

### 1.3 数据类型详解

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 数据类型                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  基础类型              │  描述              │  范围/说明                  │
│  ──────────────────────┼────────────────────┼─────────────────────────────│
│  INT                   │  32 位有符号整数    │  -2^31 到 2^31-1           │
│  LONG                  │  64 位有符号整数    │  -2^63 到 2^63-1           │
│  FLOAT                 │  32 位浮点数        │  IEEE 754 单精度           │
│  DOUBLE                │  64 位浮点数        │  IEEE 754 双精度           │
│  STRING                │  变长字符串         │  UTF-8 编码                │
│  BYTES                 │  字节数组           │  原始二进制数据            │
│                                                                          │
│  复杂类型              │  描述              │  使用场景                   │
│  ──────────────────────┼────────────────────┼─────────────────────────────│
│  JSON                  │  JSON 对象          │  嵌套结构数据              │
│  MAP                   │  键值对映射         │  动态属性                  │
│  LIST                  │  列表               │  多值维度                  │
│                                                                          │
│  类型选择建议：                                                          │
│  ─────────────────                                                      │
│  ├── ID 字段：STRING（UUID、哈希值）                                     │
│  ├── 计数：INT（小范围）或 LONG（大范围）                                │
│  ├── 金额：DOUBLE（精度要求）或 LONG（分单位存储）                       │
│  ├── 时间戳：LONG（毫秒级 EPOCH）                                        │
│  └── 枚举值：STRING（低基数）                                            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Table 配置

### 2.1 Table 配置结构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot Table 配置结构                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Table 配置定义了表的摄入、存储和查询行为：                              │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Table 配置组成                             │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │                                                                  │   │
│  │  1. 基本信息                                                        │   │
│  │     ├── tableName：表名称                                         │   │
│  │     ├── tableType：表类型（OFFLINE/REALTIME）                     │   │
│  │     └── tenantConfig：租户配置                                    │   │
│  │                                                                  │   │
│  │  2. 摄入配置 (ingestionConfig)                                    │   │
│  │     ├── batchConfigMaps：批量摄入配置                             │   │
│  │     ├── streamConfigMaps：流式摄入配置                            │   │
│  │     └── transformConfigs：数据转换配置                            │   │
│  │                                                                  │   │
│  │  3. 索引配置 (tableIndexConfig)                                   │   │
│  │     ├── invertedIndexColumns：倒排索引列                          │   │
│  │     ├── sortedColumn：排序列                                      │   │
│  │     ├── rangeIndexColumns：范围索引列                             │   │
│  │     ├── bloomFilterColumns：布隆过滤器列                          │   │
│  │     └── starTreeIndexConfigs：星型树索引配置                      │   │
│  │                                                                  │   │
│  │  4. 存储配置                                                        │   │
│  │     ├── replication：副本数                                       │   │
│  │     ├── retentionTimeUnit：保留时间单位                           │   │
│  │     └── retentionTimeValue：保留时间值                            │   │
│  │                                                                  │   │
│  │  5. 查询配置                                                        │   │
│  │     ├── queryQuota：查询配额                                      │   │
│  │     └── routingConfig：路由配置                                   │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Real-time Table 配置示例

```json
{
  "tableName": "user_events",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "timeType": "MILLISECONDS",
    "retentionTimeUnit": "DAYS",
    "retentionTimeValue": "30",
    "segmentPushType": "APPEND",
    "segmentAssignmentStrategy": "BalanceNumSegmentAssignmentStrategy",
    "replication": "3",
    "minimizeDataMovement": true
  },
  "tenants": {
    "broker": "DefaultTenant",
    "server": "DefaultTenant"
  },
  "tableIndexConfig": {
    "loadMode": "MMAP",
    "invertedIndexColumns": ["user_id", "country", "event_type"],
    "sortedColumn": ["timestamp"],
    "rangeIndexColumns": ["timestamp"],
    "bloomFilterColumns": ["user_id"],
    "starTreeIndexConfigs": [
      {
        "dimensionsSplitOrder": ["country", "event_type"],
        "functionColumnPairs": ["SUM__revenue", "COUNT__*"],
        "maxLeafRecords": 10000
      }
    ],
    "enableDefaultStarTree": false,
    "enableDynamicStarTreeCreation": true,
    "aggregateMetrics": false,
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
        "realtime.segment.flush.threshold.rows": "5000000",
        "realtime.segment.flush.threshold.time": "1h",
        "realtime.segment.flush.threshold.segment.size": "200M"
      }
    ],
    "transformConfigs": [
      {
        "columnName": "timestamp",
        "transformFunction": "toEpochSeconds(event_time) * 1000"
      }
    ]
  },
  "metadata": {
    "customConfigs": {}
  }
}
```

### 2.3 Offline Table 配置示例

```json
{
  "tableName": "user_events",
  "tableType": "OFFLINE",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "timeType": "MILLISECONDS",
    "retentionTimeUnit": "DAYS",
    "retentionTimeValue": "365",
    "segmentPushType": "APPEND",
    "segmentAssignmentStrategy": "BalanceNumSegmentAssignmentStrategy",
    "replication": "2"
  },
  "tenants": {
    "broker": "DefaultTenant",
    "server": "DefaultTenant"
  },
  "tableIndexConfig": {
    "loadMode": "MMAP",
    "invertedIndexColumns": ["user_id", "country", "event_type"],
    "sortedColumn": ["timestamp"],
    "bloomFilterColumns": ["user_id"],
    "starTreeIndexConfigs": [
      {
        "dimensionsSplitOrder": ["country", "event_type", "device_type"],
        "functionColumnPairs": ["SUM__revenue", "AVG__page_views", "COUNT__*"]
      }
    ]
  },
  "ingestionConfig": {
    "batchConfigMaps": [
      {
        "inputDirURI": "s3://my-bucket/pinot-data/",
        "inputFormat": "parquet",
        "outputDirURI": "s3://my-bucket/pinot-output/",
        "overwriteOutput": "true",
        "pinotFSSpecs": [
          {
            "scheme": "s3",
            "className": "org.apache.pinot.plugin.filesystem.S3PinotFS",
            "configs": {
              "region": "us-east-1"
            }
          }
        ]
      }
    ]
  },
  "task": {
    "taskTypeConfigsMap": {
      "SegmentGenerationAndPushTask": {
        "schedule": "0 0 * * * ?",
        "tableMaxNumTasks": "10"
      }
    }
  }
}
```

---

## 3. 索引详解

### 3.1 索引类型对比

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 索引类型详解                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. Forward Index（前向索引）                                            │
│  ─────────────────────────────                                          │
│  ├── 默认索引，所有列都有                                                 │
│  ├── 存储列的原始值                                                       │
│  ├── 支持快速顺序扫描                                                     │
│  └── 存储格式：字典编码 + 文档 ID 列表                                    │
│                                                                          │
│  2. Inverted Index（倒排索引）                                           │
│  ─────────────────────────────                                          │
│  ├── 适用：等值过滤、IN 查询                                              │
│  ├── 结构：值 -> 文档 ID 列表                                             │
│  ├── 查询：WHERE country = 'US'                                          │
│  └── 开销：中等（额外存储映射关系）                                       │
│                                                                          │
│  3. Sorted Index（排序索引）                                             │
│  ─────────────────────────────                                          │
│  ├── 适用：范围查询、排序                                                 │
│  ├── 要求：数据按该列排序                                                 │
│  ├── 优势：范围查询只需扫描部分数据                                       │
│  └── 开销：低（利用数据有序性）                                           │
│                                                                          │
│  4. Range Index（范围索引）                                              │
│  ─────────────────────────────                                          │
│  ├── 适用：数值范围查询                                                   │
│  ├── 结构：B+ 树索引                                                      │
│  ├── 查询：WHERE age BETWEEN 18 AND 25                                   │
│  └── 开销：中等                                                           │
│                                                                          │
│  5. Bloom Filter（布隆过滤器）                                           │
│  ─────────────────────────────                                          │
│  ├── 适用：存在性检查、高基数列                                           │
│  ├── 特点：可能误报，不会漏报                                             │
│  ├── 优势：空间效率高                                                     │
│  └── 开销：低                                                             │
│                                                                          │
│  6. Star-Tree Index（星型树索引）                                        │
│  ─────────────────────────────                                          │
│  ├── 适用：聚合查询加速                                                   │
│  ├── 原理：预计算多维聚合                                                 │
│  ├── 优势：聚合查询性能提升 10-100 倍                                     │
│  └── 开销：高（预计算存储）                                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 索引选择决策树

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        索引选择决策树                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  开始                                                                     │
│   │                                                                      │
│   ▼                                                                      │
│  列是否用于过滤？                                                         │
│   │                                                                      │
│   ├── 是 ──> 过滤类型？                                                  │
│   │           │                                                          │
│   │           ├── 等值/IN ──> 基数？                                     │
│   │           │               │                                          │
│   │           │               ├── 低基数（<10K）──> Inverted Index       │
│   │           │               └── 高基数 ──> Bloom Filter                │
│   │           │                                                          │
│   │           └── 范围 ──> 数据是否有序？                                │
│   │                       │                                              │
│   │                       ├── 是 ──> Sorted Index                        │
│   │                       └── 否 ──> Range Index                         │
│   │                                                                      │
│   └── 否 ──> 列是否用于聚合？                                            │
│               │                                                          │
│               ├── 是 ──> 聚合频率？                                      │
│               │           │                                              │
│               │           ├── 高频 ──> Star-Tree Index                   │
│               │           └── 低频 ──> Forward Index                     │
│               │                                                          │
│               └── 否 ──> Forward Index（默认）                           │
│                                                                          │
│  时间戳列特殊处理：                                                        │
│  ─────────────────                                                      │
│  ├── 总是设置为 sortedColumn                                             │
│  ├── 添加 Range Index                                                    │
│  └── 考虑时间分区策略                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. 数据摄入

### 4.1 摄入模式对比

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 数据摄入模式                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. 实时摄入（Real-time Ingestion）                                      │
│  ─────────────────────────────                                          │
│  ├── 数据源：Kafka、Kinesis、Pub/Sub                                     │
│  ├── 延迟：亚秒级                                                         │
│  ├── 使用场景：实时监控、用户行为分析                                     │
│  └── 特点：                                                              │
│      ├── Server 直接消费流数据                                            │
│      ├── 内存中构建 Segment                                               │
│      ├── 定期提交到 Deep Storage                                          │
│      └── 支持 Upsert（去重）                                              │
│                                                                          │
│  2. 批量摄入（Batch Ingestion）                                          │
│  ─────────────────────────────                                          │
│  ├── 数据源：HDFS、S3、GCS、本地文件                                     │
│  ├── 延迟：分钟级到小时级                                                 │
│  ├── 使用场景：历史数据加载、数据仓库同步                                 │
│  └── 特点：                                                              │
│      ├── 使用 Hadoop/Spark 处理                                           │
│      ├── 生成优化的 Segment                                               │
│      ├── 推送到 Deep Storage                                              │
│      └── Controller 通知 Server 加载                                      │
│                                                                          │
│  3. 混合摄入（Hybrid Ingestion）                                         │
│  ─────────────────────────────                                          │
│  ├── 组合：实时表 + 离线表                                                │
│  ├── 使用场景：Lambda 架构                                                │
│  └── 特点：                                                              │
│      ├── 实时表处理最近数据                                               │
│      ├── 离线表处理历史数据                                               │
│      └── 统一查询接口                                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 实时摄入流程

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        实时摄入流程                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │  Kafka   │────>│  Server  │────>│  Segment │────>│  Deep    │      │
│  │  Topic   │     │  Consumer│     │  Builder │     │  Storage │      │
│  └──────────┘     └──────────┘     └──────────┘     └──────────┘      │
│                                                                          │
│  详细流程：                                                              │
│  ─────────────────                                                      │
│                                                                          │
│  1. 消费数据                                                             │
│     ├── Server 启动 Kafka Consumer                                       │
│     ├── 从 ZooKeeper 获取消费偏移量                                      │
│     └── 开始消费消息                                                     │
│                                                                          │
│  2. 构建 Segment                                                         │
│     ├── 在内存中累积数据                                                 │
│     ├── 应用转换函数                                                     │
│     ├── 构建索引（倒排、排序等）                                         │
│     └── 监控触发条件                                                     │
│                                                                          │
│  3. 触发提交                                                             │
│     ├── 达到时间阈值（如 1 小时）                                        │
│     ├── 达到行数阈值（如 500 万行）                                      │
│     ├── 达到大小阈值（如 200MB）                                         │
│     └── 手动触发                                                         │
│                                                                          │
│  4. 提交 Segment                                                         │
│     ├── 将 Segment 上传到 Deep Storage                                   │
│     ├── 通知 Controller                                                  │
│     ├── Controller 更新元数据                                            │
│     └── 其他 Server 可下载副本                                           │
│                                                                          │
│  5. 继续消费                                                             │
│     ├── 创建新 Segment                                                   │
│     ├── 更新消费偏移量                                                   │
│     └── 循环继续                                                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.3 数据转换

```json
{
  "transformConfigs": [
    {
      "columnName": "timestamp",
      "transformFunction": "toEpochSeconds(event_time) * 1000"
    },
    {
      "columnName": "year",
      "transformFunction": "year(timestamp)"
    },
    {
      "columnName": "month",
      "transformFunction": "month(timestamp)"
    },
    {
      "columnName": "day",
      "transformFunction": "day(timestamp)"
    },
    {
      "columnName": "full_name",
      "transformFunction": "concat(first_name, ' ', last_name)"
    },
    {
      "columnName": "is_mobile",
      "transformFunction": "case when device_type = 'mobile' then 1 else 0 end"
    },
    {
      "columnName": "json_data",
      "transformFunction": "jsonFormat(properties)"
    }
  ]
}
```

---

## 5. 查询语言

### 5.1 PQL vs SQL

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 查询语言对比                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  PQL (Pinot Query Language)                                              │
│  ─────────────────────────────                                          │
│  ├── Pinot 原生查询语言                                                   │
│  ├── 语法类似 SQL                                                         │
│  ├── 支持基本聚合和过滤                                                   │
│  └── 示例：                                                              │
│      SELECT SUM(revenue) FROM orders                                     │
│      WHERE country = 'US'                                                │
│      GROUP BY device_type                                                │
│      TOP 10                                                              │
│                                                                          │
│  ANSI SQL                                                                │
│  ─────────────────                                                      │
│  ├── 标准 SQL 语法                                                        │
│  ├── 更丰富的功能支持                                                     │
│  ├── 支持 JOIN、子查询等                                                  │
│  └── 示例：                                                              │
│      SELECT                                                              │
│        device_type,                                                       │
│        SUM(revenue) as total_revenue,                                    │
│        COUNT(*) as order_count                                           │
│      FROM orders                                                         │
│      WHERE country = 'US' AND timestamp > now() - 86400000               │
│      GROUP BY device_type                                                │
│      ORDER BY total_revenue DESC                                         │
│      LIMIT 10                                                            │
│                                                                          │
│  推荐使用 ANSI SQL                                                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 常用查询模式

```sql
-- 1. 基础聚合查询
SELECT
  country,
  COUNT(*) as total_orders,
  SUM(revenue) as total_revenue,
  AVG(revenue) as avg_revenue,
  MAX(revenue) as max_revenue,
  MIN(revenue) as min_revenue
FROM orders
WHERE timestamp > now() - 86400000
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 10;

-- 2. 时间序列查询
SELECT
  ToDateTime(timestamp, 'yyyy-MM-dd HH:mm') as time_bucket,
  COUNT(*) as event_count,
  SUM(revenue) as revenue
FROM user_events
WHERE timestamp > now() - 3600000
GROUP BY time_bucket
ORDER BY time_bucket;

-- 3. 去重计数（近似）
SELECT
  country,
  DISTINCTCOUNT(user_id) as unique_users,
  DISTINCTCOUNTRAWHLL(user_id) as unique_users_hll
FROM user_events
WHERE timestamp > now() - 86400000
GROUP BY country;

-- 4. 百分位统计
SELECT
  country,
  PERCENTILE(latency, 50) as p50_latency,
  PERCENTILE(latency, 95) as p95_latency,
  PERCENTILE(latency, 99) as p99_latency
FROM api_logs
WHERE timestamp > now() - 3600000
GROUP BY country;

-- 5. JSON 数据查询
SELECT
  user_id,
  JSONEXTRACTSCALAR(properties, '$.device.os', 'STRING') as os,
  JSONEXTRACTSCALAR(properties, '$.device.browser', 'STRING') as browser
FROM user_events
WHERE JSONEXTRACTSCALAR(properties, '$.device.os', 'STRING') = 'iOS';
```

---

## 6. 多租户架构

### 6.1 租户概念

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 多租户架构                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  租户（Tenant）是 Pinot 的资源隔离单位：                                 │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        租户类型                                   │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │                                                                  │   │
│  │  1. Server Tenant                                                 │   │
│  │     ├── 存储实际数据                                              │   │
│  │     ├── 执行查询                                                  │   │
│  │     └── 资源隔离：CPU、内存、磁盘                                 │   │
│  │                                                                  │   │
│  │  2. Broker Tenant                                                 │   │
│  │     ├── 接收查询请求                                              │   │
│  │     ├── 路由查询                                                  │   │
│  │     └── 资源隔离：查询并发、配额                                  │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  多租户部署示例：                                                        │
│  ─────────────────                                                      │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                                                                  │   │
│  │  租户 A（业务团队 1）                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │   │
│  │  │   Broker    │    │   Server    │    │   Server    │        │   │
│  │  │  (team1)    │    │  (team1)    │    │  (team1)    │        │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘        │   │
│  │         │                  │                  │                │   │
│  │         └──────────────────┼──────────────────┘                │   │
│  │                            │                                   │   │
│  │                            ▼                                   │   │
│  │                    Table: orders_team1                         │   │
│  │                    Table: users_team1                          │   │
│  │                                                                  │   │
│  │  租户 B（业务团队 2）                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │   │
│  │  │   Broker    │    │   Server    │    │   Server    │        │   │
│  │  │  (team2)    │    │  (team2)    │    │  (team2)    │        │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘        │   │
│  │         │                  │                  │                │   │
│  │         └──────────────────┼──────────────────┘                │   │
│  │                            │                                   │   │
│  │                            ▼                                   │   │
│  │                    Table: orders_team2                         │   │
│  │                    Table: users_team2                          │   │
│  │                                                                  │   │
│  │  共享 Controller 和 ZooKeeper                                   │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Controller    Controller    ZooKeeper  ZooKeeper       │    │   │
│  │  │  (shared)      (shared)      (shared)   (shared)        │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 租户配置

```json
{
  "tableName": "orders",
  "tableType": "REALTIME",
  "tenants": {
    "broker": "team1",
    "server": "team1"
  },
  "quota": {
    "storage": "100G",
    "maxQueriesPerSecond": 1000
  }
}
```

---

## 7. 关键配置参数

### 7.1 性能相关参数

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 性能配置参数                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  查询性能                                                                │
│  ─────────────────                                                      │
│  ├── timeoutMs：查询超时时间（默认 10s）                                 │
│  ├── maxQueryResponseSizeBytes：最大响应大小                             │
│  ├── groupByTrimThreshold：GROUP BY 剪枝阈值                             │
│  └── minSegmentGroupTrimSize：Segment 级别剪枝大小                       │
│                                                                          │
│  摄入性能                                                                │
│  ─────────────────                                                      │
│  ├── realtime.segment.flush.threshold.rows：Segment 行数阈值             │
│  ├── realtime.segment.flush.threshold.time：Segment 时间阈值             │
│  ├── realtime.segment.flush.threshold.segment.size：Segment 大小阈值     │
│  └── stream.kafka.fetcher.minBytes：Kafka 最小获取字节数                 │
│                                                                          │
│  存储性能                                                                │
│  ─────────────────                                                      │
│  ├── loadMode：加载模式（MMAP/HEAP）                                     │
│  ├── segment.map.flush.threshold：MMAP 刷新阈值                          │
│  └── pinot.server.instance.max.threads：Server 最大线程数                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.2 可靠性参数

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 可靠性配置参数                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  副本与容错                                                              │
│  ─────────────────                                                      │
│  ├── replication：副本数（推荐 3）                                       │
│  ├── minimizeDataMovement：最小化数据移动                                │
│  ├── peerDownloadScheme：副本下载方案                                    │
│  └── segmentAssignmentStrategy：Segment 分配策略                         │
│                                                                          │
│  数据保留                                                                │
│  ─────────────────                                                      │
│  ├── retentionTimeUnit：保留时间单位（DAYS/HOURS）                       │
│  ├── retentionTimeValue：保留时间值                                      │
│  ├── deletedSegmentsRetentionInDays：删除 Segment 保留天数               │
│  └── segmentDeletionEnabled：是否启用 Segment 删除                       │
│                                                                          │
│  消费容错                                                                │
│  ─────────────────                                                      │
│  ├── stream.kafka.consumer.prop.enable.auto.commit：自动提交偏移量       │
│  ├── realtime.segment.commit.timeoutSeconds：Segment 提交超时            │
│  └── pinot.server.instance.realtime.max.wait.for.segment.build：构建等待 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 8. 监控指标

### 8.1 关键指标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 关键监控指标                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  查询指标                                                                │
│  ─────────────────                                                      │
│  ├── queries：查询总数                                                   │
│  ├── queryLatency：查询延迟（P50/P95/P99）                               │
│  ├── queryErrorRate：查询错误率                                          │
│  ├── numDocsScanned：扫描文档数                                          │
│  └── numEntriesScannedInFilter：过滤扫描条目数                           │
│                                                                          │
│  摄入指标                                                                │
│  ─────────────────                                                      │
│  ├── consumingPartitions：消费分区数                                     │
│  ├── segmentBuildTimeMs：Segment 构建时间                                │
│  ├── segmentCommitTimeMs：Segment 提交时间                               │
│  ├── recordsConsumedRate：消费速率                                       │
│  └── partitionLag：分区延迟                                              │
│                                                                          │
│  存储指标                                                                │
│  ─────────────────                                                      │
│  ├── segmentCount：Segment 数量                                          │
│  ├── segmentSizeBytes：Segment 大小                                      │
│  ├── diskSizeBytes：磁盘使用大小                                         │
│  ├── numSegmentsToDownload：待下载 Segment 数                            │
│  └── numSegmentsToUpload：待上传 Segment 数                              │
│                                                                          │
│  系统指标                                                                │
│  ─────────────────                                                      │
│  ├── cpuUsage：CPU 使用率                                                │
│  ├── memoryUsage：内存使用率                                             │
│  ├── heapUsage：堆内存使用                                               │
│  └── gcTimeMs：GC 时间                                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 参考链接

- [Pinot Schema 配置](https://docs.pinot.apache.org/configuration-reference/schema)
- [Pinot Table 配置](https://docs.pinot.apache.org/configuration-reference/table)
- [Pinot 索引配置](https://docs.pinot.apache.org/basics/indexing)
- [Pinot 查询语言](https://docs.pinot.apache.org/users/user-guide-query/pinot-query-language)
