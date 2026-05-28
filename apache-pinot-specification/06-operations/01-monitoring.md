# Pinot 监控与告警

## 概述

本文档介绍 Apache Pinot 的监控指标、日志管理和告警配置。

---

## 1. 监控架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 监控架构                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │  Pinot   │────>│ Prometheus│────>│ Grafana  │────>│  告警    │      │
│  │  Metrics │     │          │     │  Dashboard│     │          │      │
│  └──────────┘     └──────────┘     └──────────┘     └──────────┘      │
│                                                                          │
│  指标收集：                                                              │
│  ├── Controller：/metrics                                               │
│  ├── Broker：/metrics                                                   │
│  ├── Server：/metrics                                                   │
│  └── Minion：/metrics                                                   │
│                                                                          │
│  日志收集：                                                              │
│  ├── 应用日志（Log4j2）                                                  │
│  ├── GC 日志                                                             │
│  └── 访问日志                                                            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 关键指标

### 2.1 查询指标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 查询指标                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  指标名称                          │  类型    │  说明                   │
│  ──────────────────────────────────┼──────────┼─────────────────────────│
│  pinot_broker_queries              │  Counter │  查询总数               │
│  pinot_broker_query_latency        │  Timer   │  查询延迟               │
│  pinot_broker_query_latency_p50    │  Gauge   │  P50 延迟               │
│  pinot_broker_query_latency_p95    │  Gauge   │  P95 延迟               │
│  pinot_broker_query_latency_p99    │  Gauge   │  P99 延迟               │
│  pinot_broker_query_error_count    │  Counter │  查询错误数             │
│  pinot_broker_num_docs_scanned     │  Counter │  扫描文档数             │
│  pinot_broker_num_entries_scanned  │  Counter │  扫描条目数             │
│                                                                          │
│  Server 查询指标：                                                       │
│  ─────────────────                                                      │
│  pinot_server_query_execution_time_ms  │  Timer   │  查询执行时间       │
│  pinot_server_num_segments_queried     │  Gauge   │  查询 Segment 数    │
│  pinot_server_num_segments_matched     │  Gauge   │  匹配 Segment 数    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 摄入指标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 摄入指标                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  实时摄入指标：                                                          │
│  ─────────────────                                                      │
│  pinot_server_records_consumed_rate     │  Gauge   │  消费速率（条/秒）  │
│  pinot_server_partition_lag             │  Gauge   │  分区延迟（条数）   │
│  pinot_server_consumer_idle_time_ms     │  Timer   │  消费者空闲时间     │
│  pinot_server_segment_build_time_ms     │  Timer   │  Segment 构建时间   │
│  pinot_server_segment_commit_time_ms    │  Timer   │  Segment 提交时间   │
│  pinot_server_rows_consumed             │  Counter │  已消费行数         │
│                                                                          │
│  批量摄入指标：                                                          │
│  ─────────────────                                                      │
│  pinot_controller_segment_upload_time_ms  │  Timer   │  上传时间         │
│  pinot_controller_segment_download_time_ms│  Timer   │  下载时间         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 系统指标

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 系统指标                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  JVM 指标：                                                              │
│  ─────────────────                                                      │
│  jvm_memory_used_bytes        │  Gauge   │  内存使用（字节）           │
│  jvm_memory_max_bytes         │  Gauge   │  内存上限（字节）           │
│  jvm_gc_collection_seconds    │  Timer   │  GC 时间                    │
│  jvm_threads_live             │  Gauge   │  活跃线程数                 │
│                                                                          │
│  操作系统指标：                                                          │
│  ─────────────────                                                      │
│  process_cpu_usage            │  Gauge   │  CPU 使用率                 │
│  process_open_fds             │  Gauge   │  打开文件描述符数           │
│  disk_free_bytes              │  Gauge   │  磁盘剩余空间               │
│                                                                          │
│  Pinot 特定指标：                                                        │
│  ─────────────────                                                      │
│  pinot_server_segment_count   │  Gauge   │  Segment 数量               │
│  pinot_server_segment_size_bytes  │  Gauge   │  Segment 大小           │
│  pinot_server_num_resizes     │  Counter │  内存调整次数               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Prometheus 配置

### 3.1 抓取配置

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'pinot-controller'
    static_configs:
      - targets: ['pinot-controller-0:9000', 'pinot-controller-1:9000']
    metrics_path: /metrics
    scrape_interval: 15s

  - job_name: 'pinot-broker'
    static_configs:
      - targets: ['pinot-broker-0:8099', 'pinot-broker-1:8099']
    metrics_path: /metrics
    scrape_interval: 15s

  - job_name: 'pinot-server'
    static_configs:
      - targets: ['pinot-server-0:8097', 'pinot-server-1:8097', 'pinot-server-2:8097']
    metrics_path: /metrics
    scrape_interval: 15s

  - job_name: 'pinot-minion'
    static_configs:
      - targets: ['pinot-minion-0:9514']
    metrics_path: /metrics
    scrape_interval: 30s
```

### 3.2 ServiceMonitor（Kubernetes）

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pinot-metrics
  namespace: pinot
  labels:
    release: prometheus
spec:
  namespaceSelector:
    matchNames:
    - pinot
  selector:
    matchLabels:
      app: pinot-controller
  endpoints:
  - port: http
    path: /metrics
    interval: 15s

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pinot-broker-metrics
  namespace: pinot
  labels:
    release: prometheus
spec:
  namespaceSelector:
    matchNames:
    - pinot
  selector:
    matchLabels:
      app: pinot-broker
  endpoints:
  - port: query
    path: /metrics
    interval: 15s
```

---

## 4. Grafana Dashboard

### 4.1 查询性能面板

```json
{
  "dashboard": {
    "title": "Pinot Query Performance",
    "panels": [
      {
        "title": "Query Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(pinot_broker_queries[1m])",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Query Latency (P99)",
        "type": "graph",
        "targets": [
          {
            "expr": "pinot_broker_query_latency_p99",
            "legendFormat": "{{instance}}"
          }
        ],
        "yAxes": [
          {
            "format": "ms"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(pinot_broker_query_error_count[1m])",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Documents Scanned",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(pinot_broker_num_docs_scanned[1m])",
            "legendFormat": "{{instance}}"
          }
        ]
      }
    ]
  }
}
```

### 4.2 摄入性能面板

```json
{
  "dashboard": {
    "title": "Pinot Ingestion Performance",
    "panels": [
      {
        "title": "Consumption Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "pinot_server_records_consumed_rate",
            "legendFormat": "{{table}}-{{partition}}"
          }
        ]
      },
      {
        "title": "Partition Lag",
        "type": "graph",
        "targets": [
          {
            "expr": "pinot_server_partition_lag",
            "legendFormat": "{{table}}-{{partition}}"
          }
        ]
      },
      {
        "title": "Segment Build Time",
        "type": "graph",
        "targets": [
          {
            "expr": "pinot_server_segment_build_time_ms",
            "legendFormat": "{{table}}"
          }
        ]
      }
    ]
  }
}
```

---

## 5. 告警规则

### 5.1 查询告警

```yaml
groups:
- name: pinot-query
  rules:
  - alert: PinotHighQueryLatency
    expr: pinot_broker_query_latency_p99 > 5000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pinot 查询延迟过高"
      description: "Broker {{ $labels.instance }} P99 延迟 {{ $value }}ms"

  - alert: PinotQueryErrorRate
    expr: rate(pinot_broker_query_error_count[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pinot 查询错误率高"
      description: "Broker {{ $labels.instance }} 错误率 {{ $value }}/s"

  - alert: PinotHighScanRate
    expr: rate(pinot_broker_num_docs_scanned[5m]) > 1000000
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Pinot 扫描率过高"
      description: "Broker {{ $labels.instance }} 扫描率 {{ $value }}/s"
```

### 5.2 摄入告警

```yaml
groups:
- name: pinot-ingestion
  rules:
  - alert: PinotHighConsumerLag
    expr: pinot_server_partition_lag > 100000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pinot 消费延迟过高"
      description: "Table {{ $labels.table }} 分区 {{ $labels.partition }} 延迟 {{ $value }} 条"

  - alert: PinotConsumerStopped
    expr: rate(pinot_server_records_consumed_rate[5m]) == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pinot 消费者停止"
      description: "Server {{ $labels.instance }} Table {{ $labels.table }} 消费停止"

  - alert: PinotSlowSegmentBuild
    expr: pinot_server_segment_build_time_ms > 300000
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Pinot Segment 构建缓慢"
      description: "Table {{ $labels.table }} 构建时间 {{ $value }}ms"
```

### 5.3 系统告警

```yaml
groups:
- name: pinot-system
  rules:
  - alert: PinotHighMemoryUsage
    expr: (jvm_memory_used_bytes / jvm_memory_max_bytes) > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pinot 内存使用率高"
      description: "Instance {{ $labels.instance }} 内存使用率 {{ $value | humanizePercentage }}"

  - alert: PinotHighCPUUsage
    expr: process_cpu_usage > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pinot CPU 使用率高"
      description: "Instance {{ $labels.instance }} CPU 使用率 {{ $value | humanizePercentage }}"

  - alert: PinotLowDiskSpace
    expr: disk_free_bytes / disk_total_bytes < 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pinot 磁盘空间不足"
      description: "Instance {{ $labels.instance }} 磁盘剩余 {{ $value | humanizePercentage }}"

  - alert: PinotServerDown
    expr: up{job=~"pinot-.*"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Pinot 服务宕机"
      description: "Instance {{ $labels.instance }} 已宕机"
```

---

## 6. 日志管理

### 6.1 Log4j2 配置

```xml
<!-- log4j2.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
  <Appenders>
    <Console name="console" target="SYSTEM_OUT">
      <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n"/>
    </Console>
    
    <RollingFile name="file" fileName="/var/log/pinot/pinot.log"
                 filePattern="/var/log/pinot/pinot-%d{yyyy-MM-dd}-%i.log.gz">
      <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n"/>
      <Policies>
        <TimeBasedTriggeringPolicy interval="1"/>
        <SizeBasedTriggeringPolicy size="100MB"/>
      </Policies>
      <DefaultRolloverStrategy max="30"/>
    </RollingFile>
  </Appenders>
  
  <Loggers>
    <Root level="info">
      <AppenderRef ref="console"/>
      <AppenderRef ref="file"/>
    </Root>
    
    <Logger name="org.apache.pinot" level="info"/>
    <Logger name="org.apache.kafka" level="warn"/>
  </Loggers>
</Configuration>
```

### 6.2 日志收集（Fluentd）

```yaml
# fluentd-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: pinot
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/pinot/*.log
      pos_file /var/log/pinot/fluentd.pos
      tag pinot.*
      <parse>
        @type regexp
        expression /^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?<level>\w+) (?<class>[^:]+):(?<line>\d+) - (?<message>.*)$/
      </parse>
    </source>
    
    <match pinot.**>
      @type elasticsearch
      host elasticsearch
      port 9200
      index_name pinot-logs
      type_name _doc
    </match>
```

---

## 参考链接

- [Pinot Monitoring](https://docs.pinot.apache.org/operators/operating-pinot/monitoring)
- [Pinot Metrics](https://docs.pinot.apache.org/operators/operating-pinot/metrics)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
