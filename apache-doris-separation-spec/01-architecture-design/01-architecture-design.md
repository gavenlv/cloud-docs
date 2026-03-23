# Doris存算分离架构设计

## 概述

Apache Doris从2.0版本开始支持存算分离架构，将数据存储与计算节点分离，实现弹性扩展和成本优化。本文档详细介绍存算分离的架构设计、原理和最佳实践。

## 传统架构 vs 存算分离架构

### 传统架构

```
┌─────────────────────────────────────────────────────┐
│                   传统架构                            │
│                                                     │
│  ┌─────────┐     ┌─────────┐                       │
│  │   FE    │────▶│   BE    │                       │
│  │(计算)   │     │(存储+计算)│                      │
│  └─────────┘     └─────────┘                       │
│                         │                           │
│                    ┌────┴────┐                      │
│                    │ 本地磁盘  │                      │
│                    │ (存储)    │                      │
│                    └─────────┘                      │
└─────────────────────────────────────────────────────┘
```

特点：
- 计算和存储紧耦合
- 扩展受限
- 资源利用率低

### 存算分离架构

```
┌─────────────────────────────────────────────────────────┐
│                   存算分离架构                             │
│                                                         │
│  ┌─────────┐     ┌─────────┐                           │
│  │   FE    │────▶│ Compute │                           │
│  │(查询协调) │     │ Nodes  │                           │
│  └─────────┘     └────┬────┘                           │
│                       │                                │
│                 ┌─────┴─────┐                          │
│                 │  S3/GCS   │                          │
│                 │ (对象存储) │                          │
│                 └───────────┘                          │
└─────────────────────────────────────────────────────────┘
```

特点：
- 计算和存储解耦
- 弹性扩展
- 冷热数据分离
- 成本优化

## 核心原理

### 1. 数据持久化

- 数据写入时直接写入对象存储（S3/GCS/HDFS）
- BE节点仅缓存热点数据
- 读取时优先从本地缓存获取，未命中则从对象存储拉取

### 2. 计算节点无状态

- 计算节点不存储数据
- 节点故障时不影响数据安全
- 支持快速扩缩容

### 3. 缓存机制

- 热数据缓存到本地SSD
- 冷数据留在对象存储
- 自动淘汰策略

## 架构设计

### 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                        FE (Query Coordinator)                │
│                  ┌──────────────────────────────────┐        │
│                  │  ┌────────┐  ┌────────┐          │        │
│                  │  │Leader  │  │Follower│          │        │
│                  │  └────────┘  └────────┘          │        │
│                  └──────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Compute Node Pool                       │
│    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│    │ Compute Node │  │ Compute Node │  │ Compute Node │  │
│    │  (计算+缓存)  │  │  (计算+缓存)  │  │  (计算+缓存)  │  │
│    └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Shared Storage                         │
│    ┌─────────────────────────────────────────────────┐     │
│    │  S3 / GCS / HDFS / MinIO (兼容S3协议)           │     │
│    └─────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 存储设计

| 存储类型 | 适用场景 | 优点 | 缺点 |
|----------|----------|------|------|
| S3 | AWS生产环境 | 高可用、低成本 | 延迟较高 |
| GCS | GCP生产环境 | 与GKE集成好 | 厂商锁定 |
| HDFS | 内部部署 | 高性能 | 需要Hadoop集群 |
| MinIO | 本地开发测试 | 兼容S3协议 | 需要自行运维 |

### 计算节点设计

- 节点规格：4核8GB起步
- 本地缓存：建议100GB SSD
- 自动扩缩容

## 配置参数

### BE配置 (be.conf)

```properties
# 存算分离模式
be.conf = be.conf separated
cloud_unique_id = $cloud_unique_id

# 对象存储配置
object_storage_endpoint = s3.amazonaws.com
object_storage_access_key = $access_key
object_storage_secret_key = $secret_key
object_storage_region = us-east-1
# 启用HTTPS
object_storage_endpoint_use_https = true

# 本地缓存配置
short_circuit_data_copy_policy = BE
storage_root_path = /mnt/disk1/doris_cloud_cache
cache_file_size = 20
```

### 计算节点配置

```properties
# 计算节点配置
backend_num = 1
cloud_unique_id = $cloud_unique_id

# 对象存储配置
object_storage_endpoint = minio.local:9000
object_storage_access_key = minioadmin
object_storage_secret_key = minioadmin
object_storage_region = us-east-1
object_storage_bucket = doris-data

# 本地缓存
cache_ttl_seconds = 86400
cache_capacity = 100GB
```

## 数据写入流程

```
1. Client → FE
   │
   ▼
2. FE生成执行计划
   │
   ▼
3. 计算节点接收数据
   │
   ▼
4. 数据直接写入对象存储
   │
   ▼
5. 写入元数据到FE
   │
   ▼
6. 返回成功给Client
```

## 数据读取流程

```
1. Client → FE
   │
   ▼
2. FE查询元数据
   │
   ▼
3. 计算节点检查本地缓存
   │
   ├── 命中 → 直接返回
   │
   └── 未命中 → 从对象存储拉取
                │
                ▼
           存入本地缓存
                │
                ▼
           返回数据给Client
```

## 最佳实践

### 1. 缓存策略

```sql
-- 设置表级别的缓存TTL
CREATE TABLE cache_table (...) PROPERTIES (
    "cachettl" = "86400"  -- 24小时
);

-- 手动预热缓存
INSERT INTO cache_table SELECT * FROM source_table;
```

### 2. 冷热数据分离

```sql
-- 创建冷热分层表
CREATE TABLE tiered_storage_table (
    user_id BIGINT,
    event_time DATETIME,
    data VARIANT
)
PARTITION BY (event_time)
DISTRIBUTED BY HASH(user_id)
PROPERTIES (
    "storage_medium" = "SSD",  -- 热数据
    "cold_border" = "2024-01-01"  -- 冷数据时间边界
);
```

### 3. 计算资源隔离

```sql
-- 创建资源组
CREATE RESOURCE GROUP compute_group
PROPERTIES (
    "cpu_share" = "10",
    "memory_limit" = "20G"
);
```

## 容量规划

### 对象存储容量

| 数据量 | 备份 | 预留 | 建议容量 |
|--------|------|------|----------|
| 1TB | 1x | 20% | 2.4TB |
| 10TB | 1x | 20% | 24TB |
| 100TB | 1x | 20% | 240TB |

### 计算节点规格

| 查询并发 | 节点数 | 单节点规格 | 本地缓存 |
|----------|--------|------------|----------|
| 10 | 2 | 4核8GB | 100GB |
| 50 | 5 | 8核16GB | 200GB |
| 100 | 10 | 16核32GB | 500GB |

## 监控指标

### 关键指标

| 指标 | 说明 | 告警阈值 |
|------|------|----------|
| object_storage_read_latency | 对象存储读取延迟 | > 100ms |
| object_storage_write_latency | 对象存储写入延迟 | > 200ms |
| local_cache_hit_rate | 本地缓存命中率 | < 60% |
| compute_node_cpu_usage | 计算节点CPU | > 80% |
| compute_node_memory_usage | 计算节点内存 | > 85% |

## 相关文档

- [GKE云端部署](../02-cloud-deployment-gke/)
- [本地Docker部署](../03-local-deployment-docker/)
- [Minikube本地集群部署](../04-local-deployment-minikube/)
