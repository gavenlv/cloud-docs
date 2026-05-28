# Apache Pinot 专题

## 概述

Apache Pinot 是一个开源的分布式 OLAP 数据库，专为实时分析而设计。它能够在亚秒级延迟内处理大规模数据，支持低延迟的实时查询和高吞吐量的批量查询。

## 目录结构

```
apache-pinot-specification/
├── README.md                              # 本文件
├── 01-fundamentals/                       # Pinot 基础
│   ├── 01-pinot-intro.md                  # Pinot 原理与架构
│   └── 02-pinot-concepts.md               # 核心概念详解
├── 02-deployment/                         # 部署指南
│   ├── 01-local-setup.md                  # 本地开发环境
│   ├── 02-kubernetes-deployment.md        # Kubernetes 部署
│   └── 03-cloud-deployment.md             # 云平台部署
├── 03-data-ingestion/                     # 数据摄入
│   ├── 01-batch-ingestion.md              # 批量摄入
│   ├── 02-stream-ingestion.md             # 流式摄入
│   └── 03-data-transformations.md         # 数据转换
├── 04-querying/                           # 查询
│   ├── 01-pql-basics.md                   # PQL 基础
│   ├── 02-advanced-queries.md             # 高级查询
│   └── 03-query-optimization.md           # 查询优化
├── 05-table-management/                   # 表管理
│   ├── 01-schema-design.md                # Schema 设计
│   ├── 02-table-config.md                 # 表配置
│   └── 03-segment-management.md           # Segment 管理
├── 06-operations/                         # 运维
│   ├── 01-monitoring.md                   # 监控
│   ├── 02-scaling.md                      # 扩缩容
│   └── 03-troubleshooting.md              # 故障排查
├── 07-integrations/                       # 集成
│   ├── 01-kafka-integration.md            # Kafka 集成
│   ├── 02-presto-trino-integration.md     # Presto/Trino 集成
│   └── 03-superset-integration.md         # Superset 集成
├── 08-performance-tuning/                 # 性能调优
│   ├── 01-indexing-strategies.md          # 索引策略
│   ├── 02-query-performance.md            # 查询性能
│   └── 03-storage-optimization.md         # 存储优化
├── 09-use-cases/                          # 实战案例
│   ├── 01-real-time-analytics.md          # 实时分析
│   ├── 02-use-case-analysis.md            # 适用场景分析
│   ├── 03-user-facing-analytics.md        # 用户分析
│   └── 04-observability.md                # 可观测性
└── 10-best-practices/                     # 最佳实践
    └── 01-production-checklist.md         # 生产检查清单
```

## 快速开始

### 本地启动 Pinot

```bash
# 使用 Docker Compose
docker run -p 9000:9000 apachepinot/pinot:latest QuickStart -type batch

# 访问 Pinot Controller UI
open http://localhost:9000
```

### 创建第一个表

```bash
# 上传 Schema
curl -X POST -H "Content-Type: application/json" \
  -d @schema.json http://localhost:9000/schemas

# 创建 Table
curl -X POST -H "Content-Type: application/json" \
  -d @table-config.json http://localhost:9000/tables
```

## 学习路径

### 初级路径

1. [01-fundamentals](./01-fundamentals/) - 掌握 Pinot 基础
   - [Pinot 原理与架构](./01-fundamentals/01-pinot-intro.md)
   - [核心概念详解](./01-fundamentals/02-pinot-concepts.md)

2. [02-deployment](./02-deployment/) - 掌握部署方法
   - [本地开发环境](./02-deployment/01-local-setup.md)
   - [Kubernetes 部署](./02-deployment/02-kubernetes-deployment.md)

### 中级路径

1. [03-data-ingestion](./03-data-ingestion/) - 掌握数据摄入
2. [04-querying](./04-querying/) - 掌握查询
3. [05-table-management](./05-table-management/) - 掌握表管理

### 高级路径

1. [06-operations](./06-operations/) - 掌握运维
2. [07-integrations](./07-integrations/) - 掌握集成
3. [08-performance-tuning](./08-performance-tuning/) - 掌握性能调优
4. [09-use-cases](./09-use-cases/) - 实战案例
5. [10-best-practices](./10-best-practices/) - 最佳实践

## 前置要求

### 必备工具

- Docker >= 20.0
- Kubernetes >= 1.24 (用于 K8s 部署)
- Java >= 11
- Apache Kafka (用于流式摄入)

### 可选工具

- Apache Superset (可视化)
- Presto/Trino (联邦查询)
- Apache Airflow (调度)

## 常见问题

### Q: Pinot 与 ClickHouse 的区别？

A: Pinot 专为实时分析设计，支持流式和批量摄入；ClickHouse 更侧重于 OLAP 查询性能。

### Q: Pinot 支持哪些数据源？

A: Kafka、Kinesis、Pub/Sub、HDFS、S3、GCS、本地文件等。

### Q: Pinot 的查询延迟如何？

A: 亚秒级延迟，适合用户-facing 的实时分析场景。

## 参考链接

- [Apache Pinot 官网](https://pinot.apache.org/)
- [Pinot 文档](https://docs.pinot.apache.org/)
- [Pinot GitHub](https://github.com/apache/pinot)
- [Pinot Slack](https://apache-pinot.slack.com/)
