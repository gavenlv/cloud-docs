# Doris监控告警

## 概述

本文档介绍Doris的监控告警配置，包括集群监控、指标采集、告警规则设置和可视化展示。

## 集群监控

### 查看集群状态

```sql
-- 查看FE状态
SHOW FRONTENDS;

-- 查看BE状态
SHOW BACKENDS;

-- 查看详细集群信息
SHOW PROC '/frontends';
SHOW PROC '/backends';

-- 查看Tablet分布
SHOW TABLETS FROM database_name.table_name;
```

### FE监控指标

```sql
-- 查看FE指标
SHOW FRONTEND METRICS;

-- 常用FE指标
-- qps, query_latency_ms, request_latency_ms
-- frontend_thread_count, current_queries
-- max_scanner_thread_num, scanner_thread_pool_size
```

### BE监控指标

```sql
-- 查看BE指标
SHOW BACKEND METRICS;

-- 常用BE指标
-- be_heap_memory, be_process_cpu_percent
-- be_base_compaction_score, be_cumulative_compaction_score
-- be TabletCount, be_upload_fail_count
```

## Prometheus监控

### 配置Prometheus

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'doris-fe'
    static_configs:
      - targets: ['fe_host:8030']
        labels:
          group: 'frontend'

  - job_name: 'doris-be'
    static_configs:
      - targets: ['be_host:8040']
        labels:
          group: 'backend'
```

### 采集Doris指标

```bash
# FE指标端点
curl http://fe_host:8030/metrics

# BE指标端点
curl http://be_host:8040/metrics
```

### 常用监控指标

| 指标名称 | 说明 | 告警阈值 |
|----------|------|----------|
| doris_fe_qps | 查询QPS | < 100 |
| doris_fe_query_latency_ms | 查询延迟 | > 10000ms |
| doris_fe_session_count | 会话数 | > 5000 |
| doris_be_cpu_used | BE CPU使用率 | > 80% |
| doris_be_mem_used | BE内存使用率 | > 85% |
| doris_be_disk_used | BE磁盘使用率 | > 90% |
| doris_be_tablet_num | Tablet数量 | > 10000 |

## Grafana配置

### 安装Grafana

```bash
# Docker方式安装
docker run -d \
  --name=grafana \
  -p 3000:3000 \
  -v grafana-data:/var/lib/grafana \
  grafana/grafana
```

### 添加数据源

```json
{
  "name": "Doris",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy"
}
```

### 常用Dashboard

```json
{
  "dashboard": {
    "title": "Doris Cluster Overview",
    "panels": [
      {
        "title": "Query QPS",
        "targets": [
          {
            "expr": "sum(rate(doris_fe_qps[5m]))"
          }
        ]
      },
      {
        "title": "Query Latency",
        "targets": [
          {
            "expr": "histogram_quantile(0.99, rate(doris_fe_query_latency_ms_bucket[5m]))"
          }
        ]
      },
      {
        "title": "BE CPU Usage",
        "targets": [
          {
            "expr": "avg(doris_be_cpu_used)"
          }
        ]
      }
    ]
  }
}
```

## 日志监控

### FE日志

```bash
# FE日志位置
$DORIS_HOME/fe/log/

# 日志文件
fe.log          # 主日志
fe.out          # 标准输出
fe.warn.log     # 警告日志

# 查看FE日志
tail -f fe/log/fe.log

# 搜索错误日志
grep -i "error" fe/log/fe.log
grep -i "exception" fe/log/fe.log
```

### BE日志

```bash
# BE日志位置
$DORIS_HOME/be/log/

# 日志文件
be.INFO         # INFO级别日志
be.WARNING      # WARNING级别日志
be.ERROR        # ERROR级别日志

# 查看BE日志
tail -f be/log/be.INFO

# 搜索错误日志
grep -i "error" be/log/be.ERROR
```

### 日志级别配置

```bash
# 修改FE日志级别
# 编辑 fe/conf/logback-fe.xml
<logger name="org.apache.doris" level="INFO"/>

# 修改BE日志级别
# 编辑 be/conf/be.conf
sys_log_level = INFO
```

## 告警配置

### AlertManager配置

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alert@example.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email'

receivers:
- name: 'email'
  email_configs:
  - to: 'admin@example.com'
```

### 告警规则

```yaml
# prometheus rules
groups:
- name: doris_alerts
  rules:
  # FE告警
  - alert: DorisFEUnavailable
    expr: up{job="doris-fe"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Doris FE is down"
      description: "Doris Frontend {{ $labels.instance }} is down"

  - alert: DorisFEHighLatency
    expr: doris_fe_query_latency_ms > 10000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Doris FE query latency is high"
      description: "Query latency is above 10s"

  # BE告警
  - alert: DorisBEHighCPU
    expr: doris_be_cpu_used > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Doris BE CPU usage is high"
      description: "BE {{ $labels.instance }} CPU usage is above 80%"

  - alert: DorisBEHighMemory
    expr: doris_be_mem_used > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Doris BE memory usage is high"
      description: "BE {{ $labels.instance }} memory usage is above 85%"

  - alert: DorisBEHighDisk
    expr: doris_be_disk_used > 90
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Doris BE disk is almost full"
      description: "BE {{ $labels.instance }} disk usage is above 90%"
```

## 常用监控SQL

### 监控查询

```sql
-- 查看当前运行的查询
SHOW PROCESSLIST;

-- 查看最近错误查询
SHOW TABLETS;

-- 查看慢查询
SHOW FRONTEND CONFIG ("query_log_size");
SHOW VARIABLES LIKE '%slow_query%';
```

### 监控资源使用

```sql
-- 查看BE资源使用
SHOW PROC '/backends';

-- 查看Tablet分布
SHOW TABLETS FROM database_name.table_name;

-- 查看数据量
SHOW DATA;
```

### 监控性能

```sql
-- 查看FE性能
SHOW PROC '/frontends';

-- 查看查询统计
SHOW VARIABLES;

-- 查看连接数
SHOW VARIABLES LIKE '%max_connections%';
```

## 监控最佳实践

### 1. 核心监控指标

```sql
-- 定期执行监控SQL
SELECT
    'FE' as component,
    FrontendHost as host,
    HeartbeatPort as port,
    SystemInfo.'LastHeartbeat' as last_heartbeat,
    BackendInfo.'CpuFunc' as cpu,
    BackendInfo.'MemFunc' as memory
FROM show_proc '/frontends';

SELECT
    'BE' as component,
    BackendHost as host,
    HeartbeatPort as port,
    LastHeartbeat as last_heartbeat,
    CpuUsed as cpu,
    MemUsed as memory,
    DiskUsed as disk
FROM show_proc '/backends';
```

### 2. 告警阈值建议

| 指标 | 警告 | 严重 |
|------|------|------|
| FE可用性 | 1个不可用 | 2个不可用 |
| BE可用性 | < 3个可用 | < 2个可用 |
| CPU使用率 | > 70% | > 90% |
| 内存使用率 | > 80% | > 95% |
| 磁盘使用率 | > 85% | > 95% |
| 查询延迟 | > 5s | > 30s |

### 3. 监控报告

```bash
#!/bin/bash
# daily_monitor_report.sh

echo "=== Doris Daily Monitor Report ==="
echo "Date: $(date)"
echo ""

echo "=== FE Status ==="
mysql -h fe_host -P 9030 -uroot -p'' -e "SHOW FRONTENDS;"

echo ""
echo "=== BE Status ==="
mysql -h fe_host -P 9030 -uroot -p'' -e "SHOW BACKENDS;"

echo ""
echo "=== Query Statistics ==="
mysql -h fe_host -P 9030 -uroot -p'' -e "SHOW VARIABLES LIKE '%query%';"

echo ""
echo "Report Generated Successfully"
```

## 常见问题

### Q: 监控数据不准确？

A: 检查Prometheus抓取间隔和采集延迟

### Q: 告警频繁？

A: 调整告警阈值和持续时间（for参数）

### Q: Grafana图表不显示？

A: 检查Prometheus数据源配置和网络连通性
