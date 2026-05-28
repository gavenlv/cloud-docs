# Pinot 流式数据摄入

## 概述

本文档介绍 Apache Pinot 的流式数据摄入方式，包括 Kafka、Kinesis、Pub/Sub 等消息队列的集成。

---

## 1. 流式摄入架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 流式摄入架构                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │  生产者  │────>│  消息队列 │────>│  Pinot   │────>│  查询    │      │
│  │          │     │          │     │  Server  │     │          │      │
│  └──────────┘     └──────────┘     └──────────┘     └──────────┘      │
│                                                                          │
│  消息队列：                                                              │
│  ├── Apache Kafka（最常用）                                              │
│  ├── Amazon Kinesis                                                      │
│  ├── Google Pub/Sub                                                      │
│  ├── Apache Pulsar                                                       │
│  └── Event Hubs                                                          │
│                                                                          │
│  消费模式：                                                              │
│  ├── Low-level Consumer（低级消费者）                                    │
│  └── High-level Consumer（高级消费者）                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Kafka 集成

### 2.1 基础配置

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
    "invertedIndexColumns": ["user_id", "event_type"],
    "sortedColumn": ["timestamp"],
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

### 2.2 高级配置

```json
{
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kafka",
        "stream.kafka.consumer.type": "lowlevel",
        "stream.kafka.topic.name": "user-events",
        "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.stream.kafka.KafkaJSONMessageDecoder",
        "stream.kafka.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kafka20.KafkaConsumerFactory",
        "stream.kafka.broker.list": "kafka-0:9092,kafka-1:9092,kafka-2:9092",
        "stream.kafka.consumer.prop.auto.offset.reset": "smallest",
        "stream.kafka.consumer.prop.group.id": "pinot-user-events",
        "stream.kafka.consumer.prop.security.protocol": "SASL_SSL",
        "stream.kafka.consumer.prop.sasl.mechanism": "PLAIN",
        "stream.kafka.consumer.prop.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='user' password='pass';",
        "stream.kafka.fetcher.minBytes": "100000",
        "stream.kafka.fetcher.maxWaitMs": "1000",
        "realtime.segment.flush.threshold.rows": "5000000",
        "realtime.segment.flush.threshold.time": "1h",
        "realtime.segment.flush.threshold.segment.size": "200M",
        "realtime.segment.flush.desired.num.rows": "4000000"
      }
    ],
    "transformConfigs": [
      {
        "columnName": "timestamp",
        "transformFunction": "toEpochSeconds(event_time) * 1000"
      }
    ]
  }
}
```

### 2.3 创建 Kafka Topic

```bash
# 创建 Topic
kafka-topics.sh --create \
  --topic user-events \
  --bootstrap-server kafka:9092 \
  --partitions 12 \
  --replication-factor 3

# 查看 Topic 信息
kafka-topics.sh --describe \
  --topic user-events \
  --bootstrap-server kafka:9092

# 发送测试数据
kafka-console-producer.sh \
  --topic user-events \
  --bootstrap-server kafka:9092 <<EOF
{"user_id": "user1", "event_type": "click", "timestamp": 1704067200000, "revenue": 0}
{"user_id": "user2", "event_type": "purchase", "timestamp": 1704067260000, "revenue": 100.50}
EOF
```

---

## 3. Kinesis 集成

### 3.1 配置示例

```json
{
  "tableName": "user_events",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "replication": "3"
  },
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kinesis",
        "stream.kinesis.topic.name": "user-events-stream",
        "stream.kinesis.decoder.class.name": "org.apache.pinot.plugin.inputformat.json.JSONMessageDecoder",
        "stream.kinesis.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kinesis.KinesisConsumerFactory",
        "stream.kinesis.aws.region": "us-west-2",
        "stream.kinesis.aws.accessKey": "${AWS_ACCESS_KEY_ID}",
        "stream.kinesis.aws.secretKey": "${AWS_SECRET_ACCESS_KEY}",
        "stream.kinesis.reader.timeout.millis": "1000",
        "realtime.segment.flush.threshold.rows": "5000000",
        "realtime.segment.flush.threshold.time": "1h"
      }
    ]
  }
}
```

---

## 4. Pub/Sub 集成

### 4.1 配置示例

```json
{
  "tableName": "user_events",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "replication": "3"
  },
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "pubsub",
        "stream.pubsub.project.id": "my-gcp-project",
        "stream.pubsub.topic.name": "user-events-topic",
        "stream.pubsub.sub.name": "user-events-subscription",
        "stream.pubsub.creds.file": "/etc/gcp/service-account.json",
        "stream.pubsub.decoder.class.name": "org.apache.pinot.plugin.inputformat.json.JSONMessageDecoder",
        "realtime.segment.flush.threshold.rows": "5000000",
        "realtime.segment.flush.threshold.time": "1h"
      }
    ]
  }
}
```

---

## 5. Upsert（数据更新）

### 5.1 Upsert 配置

```json
{
  "tableName": "user_events",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "replication": "3"
  },
  "tableIndexConfig": {
    "loadMode": "MMAP"
  },
  "upsertConfig": {
    "mode": "FULL",
    "hashFunction": "NONE",
    "enableSnapshot": true,
    "enablePreload": false
  },
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kafka",
        "stream.kafka.topic.name": "user-events",
        "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.stream.kafka.KafkaJSONMessageDecoder",
        "stream.kafka.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kafka20.KafkaConsumerFactory",
        "stream.kafka.broker.list": "kafka:9092"
      }
    ]
  }
}
```

### 5.2 Upsert 原理

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot Upsert 原理                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  问题：同一主键的多条消息，需要保留最新版本                              │
│                                                                          │
│  解决方案：                                                              │
│  ─────────────────                                                      │
│                                                                          │
│  1. 主键定义                                                             │
│     ├── 在 Schema 中定义 primaryKeyColumns                              │
│     ├── 示例：["user_id", "event_id"]                                   │
│     └── 复合主键支持                                                     │
│                                                                          │
│  2. 版本控制                                                             │
│     ├── 使用时间戳作为版本                                               │
│     ├── 新消息覆盖旧消息                                                 │
│     └── 无效化旧 Segment 中的记录                                        │
│                                                                          │
│  3. 查询处理                                                             │
│     ├── 查询时过滤无效记录                                               │
│     ├── 使用 ValidDocIndex 加速                                          │
│     └── 对查询性能影响最小                                               │
│                                                                          │
│  4. 快照机制                                                             │
│     ├── 定期保存主键到快照                                               │
│     ├── 加速 Server 重启恢复                                             │
│     └── 减少内存占用                                                     │
│                                                                          │
│  配置示例：                                                              │
│  ─────────────────                                                      │
│  {                                                                      │
│    "schemaName": "user_events",                                         │
│    "primaryKeyColumns": ["user_id"],                                    │
│    "dimensionFieldSpecs": [...],                                        │
│    "metricFieldSpecs": [...]                                            │
│  }                                                                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 6. 消费组管理

### 6.1 分区分配

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 分区分配策略                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Kafka Topic：12 个分区                                                  │
│  Pinot Server：3 个节点                                                  │
│                                                                          │
│  分配结果：                                                              │
│  ─────────────────                                                      │
│                                                                          │
│  Server 1：分区 0, 1, 2, 3                                              │
│  Server 2：分区 4, 5, 6, 7                                              │
│  Server 3：分区 8, 9, 10, 11                                            │
│                                                                          │
│  扩容到 4 个 Server：                                                    │
│  Server 1：分区 0, 1, 2                                                 │
│  Server 2：分区 3, 4, 5                                                 │
│  Server 3：分区 6, 7, 8                                                 │
│  Server 4：分区 9, 10, 11                                               │
│                                                                          │
│  注意：                                                                  │
│  ─────────────────                                                      │
│  ├── 分区数应大于 Server 数                                              │
│  ├── 分区数建议为 Server 数的整数倍                                      │
│  └── 扩容时会重新分配分区                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 消费偏移管理

```bash
# 查看消费偏移
kubectl exec -it pinot-server-0 -n pinot -- \
  curl http://localhost:8097/debug/consumers

# 重置消费偏移（谨慎操作）
curl -X POST http://pinot-controller:9000/tables/user_events/segments \
  -H "Content-Type: application/json" \
  -d '{
    "type": "REALTIME",
    "offset": "smallest"
  }'
```

---

## 7. 监控和告警

### 7.1 关键指标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        流式摄入关键指标                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  消费延迟                                                                │
│  ─────────────────                                                      │
│  ├── recordsConsumedRate：消费速率（条/秒）                              │
│  ├── partitionLag：分区延迟（条数）                                      │
│  └── consumerIdleTimeMs：消费者空闲时间                                  │
│                                                                          │
│  Segment 生成                                                            │
│  ─────────────────                                                      │
│  ├── segmentBuildTimeMs：Segment 构建时间                                │
│  ├── segmentCommitTimeMs：Segment 提交时间                               │
│  └── numRowsConsumed：已消费行数                                         │
│                                                                          │
│  错误指标                                                                │
│  ─────────────────                                                      │
│  ├── consumerErrorCount：消费者错误数                                    │
│  ├── decodeErrorCount：解码错误数                                        │
│  └── segmentBuildErrorCount：构建错误数                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Prometheus 告警规则

```yaml
groups:
- name: pinot-streaming
  rules:
  - alert: PinotHighConsumerLag
    expr: pinot_server_partitionLag > 100000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pinot 消费延迟过高"
      description: "分区 {{ $labels.partition }} 延迟超过 10 万条"

  - alert: PinotConsumerStopped
    expr: rate(pinot_server_recordsConsumedRate[5m]) == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pinot 消费者停止"
      description: "Server {{ $labels.instance }} 消费速率为 0"

  - alert: PinotSegmentBuildSlow
    expr: pinot_server_segmentBuildTimeMs > 300000
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Pinot Segment 构建缓慢"
      description: "Segment 构建时间超过 5 分钟"
```

---

## 参考链接

- [Pinot Stream Ingestion](https://docs.pinot.apache.org/basics/data-import/pinot-stream-ingestion)
- [Pinot Kafka Integration](https://docs.pinot.apache.org/basics/data-import/pinot-stream-ingestion/import-from-apache-kafka)
- [Pinot Upsert](https://docs.pinot.apache.org/basics/data-import/upsert)
