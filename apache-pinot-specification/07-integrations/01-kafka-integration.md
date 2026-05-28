# Pinot 与 Kafka 集成

## 概述

本文档详细介绍 Apache Pinot 与 Apache Kafka 的集成，包括配置、监控和最佳实践。

---

## 1. 集成架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot + Kafka 集成架构                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │  生产者  │────>│  Kafka   │────>│  Pinot   │────>│  查询    │      │
│  │          │     │  Topic   │     │  Server  │     │          │      │
│  └──────────┘     └──────────┘     └──────────┘     └──────────┘      │
│                                                                          │
│  关键概念：                                                              │
│  ─────────────────                                                      │
│  ├── Topic：数据主题                                                     │
│  ├── Partition：数据分区                                                 │
│  ├── Consumer Group：消费者组                                            │
│  ├── Offset：消费偏移量                                                  │
│  └── Segment：Pinot 存储单元                                             │
│                                                                          │
│  消费模式：                                                              │
│  ─────────────────                                                      │
│  ├── Low-level Consumer：每个分区一个消费者                              │
│  └── High-level Consumer：自动分区分配                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 基础配置

### 2.1 表配置

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

### 2.2 Schema 配置

```json
{
  "schemaName": "user_events",
  "enableColumnBasedNullHandling": true,
  "dimensionFieldSpecs": [
    {"name": "user_id", "dataType": "STRING", "notNull": true},
    {"name": "event_type", "dataType": "STRING", "notNull": true},
    {"name": "country", "dataType": "STRING", "notNull": false}
  ],
  "metricFieldSpecs": [
    {"name": "revenue", "dataType": "DOUBLE", "notNull": false, "defaultNullValue": 0.0}
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

---

## 3. 高级配置

### 3.1 SASL/SSL 认证

```json
{
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kafka",
        "stream.kafka.topic.name": "user-events",
        "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.stream.kafka.KafkaJSONMessageDecoder",
        "stream.kafka.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kafka20.KafkaConsumerFactory",
        "stream.kafka.broker.list": "kafka:9093",
        "stream.kafka.consumer.prop.security.protocol": "SASL_SSL",
        "stream.kafka.consumer.prop.sasl.mechanism": "PLAIN",
        "stream.kafka.consumer.prop.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='pinot' password='secret';",
        "stream.kafka.consumer.prop.ssl.truststore.location": "/etc/pinot/kafka.truststore.jks",
        "stream.kafka.consumer.prop.ssl.truststore.password": "truststore-pass",
        "stream.kafka.consumer.prop.auto.offset.reset": "smallest"
      }
    ]
  }
}
```

### 3.2 消费者调优

```json
{
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kafka",
        "stream.kafka.topic.name": "user-events",
        "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.stream.kafka.KafkaJSONMessageDecoder",
        "stream.kafka.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kafka20.KafkaConsumerFactory",
        "stream.kafka.broker.list": "kafka:9092",
        "stream.kafka.fetcher.minBytes": "100000",
        "stream.kafka.fetcher.maxWaitMs": "1000",
        "stream.kafka.consumer.prop.auto.offset.reset": "smallest",
        "stream.kafka.consumer.prop.max.poll.records": "500",
        "stream.kafka.consumer.prop.max.poll.interval.ms": "300000",
        "stream.kafka.consumer.prop.session.timeout.ms": "30000",
        "stream.kafka.consumer.prop.heartbeat.interval.ms": "10000"
      }
    ]
  }
}
```

---

## 4. 消息格式

### 4.1 JSON 格式

```json
{
  "user_id": "user123",
  "event_type": "purchase",
  "country": "US",
  "revenue": 100.50,
  "timestamp": 1704067200000
}
```

### 4.2 Avro 格式

```json
{
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kafka",
        "stream.kafka.topic.name": "user-events",
        "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.inputformat.avro.KafkaAvroMessageDecoder",
        "stream.kafka.decoder.prop.schema.registry.rest.url": "http://schema-registry:8081",
        "stream.kafka.decoder.prop.schema.registry.schema.name": "user-events-value"
      }
    ]
  }
}
```

### 4.3 Protobuf 格式

```json
{
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kafka",
        "stream.kafka.topic.name": "user-events",
        "stream.kafka.decoder.class.name": "org.apache.pinot.plugin.inputformat.protobuf.KafkaProtobufMessageDecoder",
        "stream.kafka.decoder.prop.proto.class.name": "com.example.UserEvent"
      }
    ]
  }
}
```

---

## 5. 监控和告警

### 5.1 关键指标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Kafka 消费指标                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  指标名称                          │  说明                              │
│  ──────────────────────────────────┼────────────────────────────────────│
│  pinot_server_records_consumed_rate│  消费速率（条/秒）                 │
│  pinot_server_partition_lag        │  分区延迟（条数）                  │
│  pinot_server_consumer_idle_time_ms│  消费者空闲时间                    │
│  pinot_server_segment_build_time_ms│  Segment 构建时间                  │
│  pinot_server_segment_commit_time_ms│ Segment 提交时间                  │
│  pinot_server_rows_consumed        │  已消费行数                        │
│  pinot_server_consumer_error_count │  消费者错误数                      │
│  pinot_server_decode_error_count   │  解码错误数                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 告警规则

```yaml
groups:
- name: pinot-kafka
  rules:
  - alert: PinotHighConsumerLag
    expr: pinot_server_partition_lag > 100000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pinot Kafka 消费延迟过高"
      description: "Table {{ $labels.table }} 分区 {{ $labels.partition }} 延迟 {{ $value }} 条"

  - alert: PinotConsumerStopped
    expr: rate(pinot_server_records_consumed_rate[5m]) == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pinot Kafka 消费者停止"
      description: "Server {{ $labels.instance }} Table {{ $labels.table }} 消费停止"

  - alert: PinotKafkaDecodeError
    expr: rate(pinot_server_decode_error_count[5m]) > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pinot Kafka 解码错误"
      description: "Server {{ $labels.instance }} 解码错误率 {{ $value }}/s"
```

---

## 6. 最佳实践

### 6.1 Topic 设计

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Kafka Topic 设计建议                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  分区数：                                                                │
│  ─────────────────                                                      │
│  ├── 至少等于 Pinot Server 数                                            │
│  ├── 建议为 Server 数的 2-4 倍                                           │
│  └── 考虑未来扩容需求                                                    │
│                                                                          │
│  副本数：                                                                │
│  ─────────────────                                                      │
│  ├── 生产环境至少 3 个副本                                               │
│  └── 考虑可用区分布                                                      │
│                                                                          │
│  数据保留：                                                              │
│  ─────────────────                                                      │
│  ├── 至少保留 7 天                                                       │
│  ├── 考虑数据重放需求                                                    │
│  └── 监控磁盘使用                                                        │
│                                                                          │
│  示例：                                                                  │
│  ─────────────────                                                      │
│  kafka-topics.sh --create \
│    --topic user-events \
│    --bootstrap-server kafka:9092 \
│    --partitions 12 \
│    --replication-factor 3 \
│    --config retention.ms=604800000 \
│    --config min.insync.replicas=2                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 消费者组管理

```bash
# 查看消费者组
kafka-consumer-groups.sh \
  --bootstrap-server kafka:9092 \
  --describe \
  --group pinot-user-events

# 重置偏移量（谨慎操作）
kafka-consumer-groups.sh \
  --bootstrap-server kafka:9092 \
  --group pinot-user-events \
  --topic user-events \
  --reset-offsets \
  --to-latest \
  --execute
```

---

## 参考链接

- [Pinot Kafka Integration](https://docs.pinot.apache.org/basics/data-import/pinot-stream-ingestion/import-from-apache-kafka)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Pinot Stream Ingestion](https://docs.pinot.apache.org/basics/data-import/pinot-stream-ingestion)
