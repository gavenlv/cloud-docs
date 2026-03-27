# GCP Memorystore 深入解析

## 本章概述

Memorystore是GCP提供的完全托管式内存数据库服务，支持Redis和Memcached。本章深入讲解Memorystore for Redis的核心特性、架构原理、GKE集成、在Cloud Run等服务中的使用方式以及最佳安全实践。

## 学习目标

- 深入理解Memorystore for Redis架构和核心概念
- 掌握Memorystore for Redis的基本操作命令
- 掌握Memorystore与GKE的集成方式
- 掌握在Cloud Run、Cloud Functions等服务中使用Memorystore
- 理解Memorystore高可用配置和灾难恢复
- 掌握Memorystore安全最佳实践

---

## 1. Memorystore核心概念

### 1.1 什么是Memorystore？

Memorystore是Google Cloud提供的完全托管式内存数据库服务，目前支持Redis和Memcached两种引擎。它为应用程序提供毫秒级延迟的高性能缓存层，是构建高吞吐量应用的关键组件。

```
Memorystore定位

┌─────────────────────────────────────────────────────────────────────────┐
│                        GCP缓存服务层级                                   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                   完全托管 - Memorystore                         │   │
│  │  ├── 原生Redis/Memcached兼容                                    │   │
│  │  ├── 自动故障转移                                                │   │
│  │  ├── 自动备份和恢复                                              │   │
│  │  └── VPC原生集成                                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    自托管 - Compute Engine                       │   │
│  │  ├── 完全控制                                                    │   │
│  │  ├── 需手动配置高可用                                            │   │
│  │  └── 需自行维护和升级                                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Memorystore for Redis vs Memcached

```
核心对比

┌─────────────────────────────────────────────────────────────────────────┐
│                    Memorystore Redis vs Memcached                        │
│                                                                         │
│  特性                Redis                  Memcached                  │
│  ────────────────────────────────────────────────────────────────────   │
│                                                                         │
│  数据结构            多种类型                仅字符串                    │
│                      String/Hash/List        单值                       │
│                      Set/SortedSet                                       │
│                      HyperLogLog                                         │
│                                                                         │
│  持久化              支持RDB/AOF            不支持                     │
│                      磁盘备份                纯内存                     │
│                                                                         │
│  复制                主从复制               多节点分片                  │
│                      自动故障转移            无复制                     │
│                                                                         │
│  高可用              支持(Standard层)       不支持                     │
│                      自动故障转移                                         │
│                      区域冗余                                              │
│                                                                         │
│  内存效率            较高                   最高                       │
│                      压缩字典               简单kv                     │
│                                                                         │
│  适用场景            缓存/会话/             简单缓存                     │
│                      排行榜/消息队列        HTML片段缓存               │
│                                                                         │
│  最大容量            300GB                 256GB(分片)                 │
│                                                                         │
│  最小延迟            ~1ms                  ~0.5ms                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.3 Redis Tier对比

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Memorystore Redis服务层级                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  BASIC TIER (基础层)                                                     │
│  ├── 单节点Redis实例                                                    │
│  ├── 无自动故障转移                                                     │
│  ├── 无自动备份                                                         │
│  ├── 适合开发/测试                                                      │
│  └── 99.9%可用性                                                        │
│                                                                         │
│  STANDARD TIER (标准层)                                                 │
│  ├── 主从复制                                                           │
│  ├── 自动故障转移                                                       │
│  ├── 自动每日备份                                                       │
│  ├── 适合生产环境                                                       │
│  └── 99.99%可用性                                                       │
│                                                                         │
│  ENTERPRISE TIER (企业层)                                               │
│  ├── Standard Tier全部特性                                              │
│  ├── Active-Active地理冗余                                              │
│  ├── Redis JSON支持                                                     │
│  ├── Bloom过滤器                                                        │
│  ├── RedisGears                                                        │
│  └── 99.999%可用性                                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Memorystore命令行操作

### 2.1 实例基本操作

```bash
# ============================================================
# 创建Redis实例
# ============================================================

# 创建基础层Redis实例
gcloud redis instances create my-redis `
    --size=1 `
    --region=us-central1 `
    --redis-version=redis_7_0

# 创建标准层Redis实例(带高可用)
gcloud redis instances create my-redis-standard `
    --size=2 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --network=projects/PROJECT_ID/global/networks/my-vpc

# 创建带指定子网的Redis实例
gcloud redis instances create my-redis-subnet `
    --size=1 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --region=us-central1 `
    --zone=us-central1-a `
    --redis-config=maxmemory-policy=allkeys-lru

# 创建带auth的Redis实例
gcloud redis instances create my-redis-auth `
    --size=1 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --enable-auth

# ============================================================
# 查询实例
# ============================================================

# 列出所有Redis实例
gcloud redis instances list

# 按项目筛选
gcloud redis instances list --project=PROJECT_ID

# 查看实例详情
gcloud redis instances describe my-redis --region=us-central1

# 获取实例IP和端口
gcloud redis instances describe my-redis --region=us-central1 `
    --format="value(host,port)"

# 获取实例连接信息
gcloud redis instances describe my-redis --region=us-central1

# ============================================================
# 更新实例
# ============================================================

# 修改实例大小
gcloud redis instances update my-redis `
    --region=us-central1 `
    --size=3

# 修改实例类型
gcloud redis instances update my-redis `
    --region=us-central1 `
    --tier=STANDARD_HA

# 更新Redis配置
gcloud redis instances update my-redis `
    --region=us-central1 `
    --redis-config=maxmemory-policy=allkeys-lru,timeout=300

# 启用传输加密
gcloud redis instances update my-redis `
    --region=us-central1 `
    --transit-encryption-mode=SERVER_AUTHENTICATION

# ============================================================
# 删除实例
# ============================================================

# 删除实例
gcloud redis instances delete my-redis --region=us-central1

# 强制删除
gcloud redis instances delete my-redis --region=us-central1 --quiet
```

### 2.2 高可用操作

```bash
# ============================================================
# 故障转移操作
# ============================================================

# 触发手动故障转移(标准层)
gcloud redis instances failover my-redis `
    --region=us-central1

# 获取副本实例信息
gcloud redis instances describe my-redis `
    --region=us-central1 `
    --format="value(read-replicas-ip)"

# ============================================================
# 备份和恢复
# ============================================================

# 创建手动备份
gcloud redis instances export my-redis `
    --region=us-central1 `
    --output-directory=gs://my-bucket/backups/

# 从备份恢复(创建新实例)
gcloud redis instances import my-restored-redis `
    --region=us-central1 `
    --source=gs://my-bucket/backups/my-redis.rdb `
    --size=2

# 查看备份列表
gcloud redis instances backups list my-redis --region=us-central1

# 查看备份详情
gcloud redis instances backups describe BACKUP_ID `
    --instance=my-redis `
    --region=us-central1
```

### 2.3 连接和诊断

```bash
# ============================================================
# 连接诊断
# ============================================================

# 测试连接
gcloud redis instances test-connection my-redis --region=us-central1

# 获取实例IP
HOST=$(gcloud redis instances describe my-redis --region=us-central1 `
    --format="value(host)")

# 使用redis-cli连接
redis-cli -h $HOST -p 6379

# 使用认证连接
AUTH=$(gcloud redis instances describe my-redis --region=us-central1 `
    --format="value(serverCaCerts[0].cert)")
redis-cli -h $HOST -p 6379 --tls --cert /tmp/server.crt --key /tmp/server.key

# ============================================================
# 监控
# ============================================================

# 查看实例指标(通过Cloud Monitoring)
gcloud monitoring metrics list --filter="metric.type:redis"

# 查看CPU使用率
gcloud monitoring metrics describe redis.googleapis.com.instance/cpu/utilization
```

---

## 3. Memorystore与GKE集成

### 3.1 GKE连接Memorystore架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│            GKE + Memorystore Redis集成架构                               │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      GKE Cluster                                 │   │
│   │                                                                 │   │
│   │   ┌───────────────┐    ┌───────────────┐    ┌───────────────┐   │   │
│   │   │    Pod        │    │    Pod        │    │    Pod        │   │   │
│   │   │  (App)        │    │  (App)        │    │  (App)        │   │   │
│   │   │    :8080      │    │    :8080      │    │    :8080      │   │   │
│   │   └───────┬───────┘    └───────┬───────┘    └───────┬───────┘   │   │
│   │           │                   │                   │           │   │
│   │           └───────────────────┼───────────────────┘           │   │
│   │                               │                               │   │
│   └───────────────────────────────┼───────────────────────────────┘   │
│                                   │ VPC Native Network               │
│   ┌───────────────────────────────┼───────────────────────────────┐   │
│   │                     Memorystore Redis                          │   │
│   │                                                                 │   │
│   │   my-redis: 10.0.0.5:6379                                     │   │
│   │   ├── Primary Node (write)                                    │   │
│   │   └── Replica Node (read)                                     │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 配置GKE访问Memorystore

```bash
# ============================================================
# 前提条件: VPC原生集群
# ============================================================

# 创建VPC原生集群(如果还没有)
gcloud container clusters create my-cluster `
    --region=us-central1 `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --subnetwork=projects/PROJECT_ID/regions/us-central1/subnetworks/my-subnet `
    --enable-ip-alias

# Memorystore需要专用子网(Psfc网络)
# 在创建Redis时指定:
gcloud redis instances create my-redis `
    --region=us-central1 `
    --size=1 `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --tier=STANDARD `
    --redis-version=redis_7_0

# ============================================================
# 获取Redis连接信息
# ============================================================

# 获取Redis主机IP
REDIS_HOST=$(gcloud redis instances describe my-redis `
    --region=us-central1 `
    --format="value(host)")

# 获取Redis端口
REDIS_PORT=$(gcloud redis instances describe my-redis `
    --region=us-central1 `
    --format="value(port)")

echo "Redis Host: $REDIS_HOST"
echo "Redis Port: $REDIS_PORT"
```

### 3.3 应用中使用Redis客户端

```python
# requirements.txt
# redis>=4.5.0

import redis
import os

class RedisClient:
    def __init__(self):
        self.host = os.environ.get('REDIS_HOST', 'localhost')
        self.port = int(os.environ.get('REDIS_PORT', 6379))
        self.password = os.environ.get('REDIS_PASSWORD')

        self.client = redis.Redis(
            host=self.host,
            port=self.port,
            password=self.password,
            decode_responses=True,
            ssl=True if os.environ.get('REDIS_USE_SSL') else False
        )

    def set(self, key, value, expire=None):
        if expire:
            return self.client.setex(key, expire, value)
        return self.client.set(key, value)

    def get(self, key):
        return self.client.get(key)

    def delete(self, key):
        return self.client.delete(key)

    def exists(self, key):
        return self.client.exists(key)

redis_client = RedisClient()
```

### 3.4 GKE Deployment配置

```yaml
# deployment-with-redis.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          ports:
            - containerPort: 8080
          env:
            - name: REDIS_HOST
              value: "10.0.0.5"
            - name: REDIS_PORT
              value: "6379"
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: redis-auth-secret
                  key: password
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

### 3.5 使用Sidecar模式

```yaml
# deployment-with-redis-sidecar.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-with-redis-cache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          ports:
            - containerPort: 8080
          env:
            - name: REDIS_HOST
              value: "localhost"
            - name: REDIS_PORT
              value: "6379"
          volumeMounts:
            - name: shared-cache
              mountPath: /var/cache
        - name: redis-sidecar
          image: redis:7-alpine
          ports:
            - containerPort: 6379
          command:
            - redis-server
            - --maxmemory 100mb
            - --maxmemory-policy allkeys-lru
          volumeMounts:
            - name: shared-cache
              mountPath: /data
      volumes:
        - name: shared-cache
          emptyDir: {}
```

---

## 4. Cloud Run中使用Memorystore

### 4.1 Cloud Run连接Memorystore架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│            Cloud Run + Memorystore Redis集成架构                         │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      Cloud Run Service                            │   │
│   │                                                                 │   │
│   │   my-cloudrun-service                                           │   │
│   │   └── env:                                                     │   │
│   │       REDIS_HOST=10.0.0.5                                      │   │
│   │       REDIS_PORT=6379                                          │   │
│   │       REDIS_PASSWORD=xxx                                       │   │
│   │                                                                 │   │
│   └────────────────────────────┬────────────────────────────────────┘   │
│                                │ VPC Connector                          │
│   ┌────────────────────────────┼────────────────────────────────────┐   │
│   │                     Memorystore Redis                            │   │
│   │                                                                 │   │
│   │   my-redis: 10.0.0.5:6379 (Private IP)                          │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   IAM: Cloud Run Service SA 需要VpcAccessUser角色                      │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Cloud Run服务配置

```bash
# ============================================================
# 创建VPC Connector(如果还没有)
# ============================================================

gcloud compute networks vpc-access connectors create my-connector `
    --region=us-central1 `
    --network=my-vpc `
    --range=10.8.0.0/28

# ============================================================
# 部署Cloud Run服务连接Memorystore
# ============================================================

# 获取Redis连接信息
REDIS_HOST=$(gcloud redis instances describe my-redis `
    --region=us-central1 --format="value(host)")

# 部署Cloud Run服务
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --vpc-connector=my-connector `
    --no-allow-unauthenticated `
    --service-account=my-service-sa@PROJECT_ID.iam.gserviceaccount.com `
    --set-env-vars `
        REDIS_HOST=${REDIS_HOST},`
        REDIS_PORT=6379

# ============================================================
# 使用Serverless VPC Access集成
# ============================================================

# 创建Serverless VPC Access
gcloud compute networks vpc-access connectors create my-connector `
    --region=us-central1 `
    --subnet=my-subnet `
    --subnet-project=PROJECT_ID `
    --min-instances=2 `
    --max-instances=10

# 更新Cloud Run服务
gcloud run services update my-service `
    --region=us-central1 `
    --vpc-connector=my-connector `
    --vpc-egress=all-traffic
```

### 4.3 Cloud Run IAM权限配置

```bash
# ============================================================
# 服务账号权限配置
# ============================================================

# 创建服务账号
gcloud iam service-accounts create my-service-sa `
    --display-name="My Cloud Run Service Account"

# Cloud Run服务账号需要VPC访问权限
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member=serviceAccount:my-service-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/vpcaccess.user

# 如果Redis启用了AUTH,需要Secret Manager权限(可选)
gcloud secrets add-iam-policy-binding redis-auth `
    --member=serviceAccount:my-service-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor
```

---

## 5. Memorystore高可用配置

### 5.1 Standard Tier高可用架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│            Standard Tier高可用架构                                       │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      us-central1区域                            │   │
│   │                                                                 │   │
│   │   ┌─────────────────────────────────────────────────────────┐   │   │
│   │   │                    Primary Node                         │   │   │
│   │   │              10.0.0.5:6379 (写入)                        │   │   │
│   │   │                                                         │   │   │
│   │   │   ┌─────────┐    ┌─────────┐    ┌─────────┐          │   │   │
│   │   │   │  CPU    │    │  Memory │    │  Disk   │          │   │   │
│   │   │   │  100%   │    │  80%    │    │  RDB    │          │   │   │
│   │   │   └─────────┘    └─────────┘    └─────────┘          │   │   │
│   │   └─────────────────────────────────────────────────────────┘   │   │
│   │                              │                                  │   │
│   │                         同步复制                                 │   │
│   │                              │                                  │   │
│   │   ┌─────────────────────────────────────────────────────────┐   │   │
│   │   │                   Replica Node                          │   │   │
│   │   │              10.0.0.6:6379 (读取)                       │   │   │
│   │   │                                                         │   │   │
│   │   │   ┌─────────┐    ┌─────────┐    ┌─────────┐          │   │   │
│   │   │   │  CPU    │    │  Memory │    │  Disk   │          │   │   │
│   │   │   │  50%    │    │  80%    │    │  RDB    │          │   │   │
│   │   │   └─────────┘    └─────────┘    └─────────┘          │   │   │
│   │   └─────────────────────────────────────────────────────────┘   │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   自动故障转移: Primary节点故障时,Replica自动提升为Primary              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 创建高可用实例

```bash
# 创建Standard层Redis实例
gcloud redis instances create my-redis-ha `
    --size=2 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --redis-config=`
        maxmemory-policy=allkeys-lru,`
        timeout=300,`
        lazyfree-lazy-eviction=yes

# 启用TLS
gcloud redis instances create my-redis-tls `
    --size=1 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --transit-encryption-mode=SERVER_AUTHENTICATION

# 获取HA实例信息
gcloud redis instances describe my-redis-ha --region=us-central1

# 查看副本信息
gcloud redis instances describe my-redis-ha --region=us-central1 `
    --format="value(read-replicas)"
```

### 5.3 故障转移测试

```bash
# 触发手动故障转移
gcloud redis instances failover my-redis-ha --region=us-central1

# 监控故障转移状态
gcloud redis instances describe my-redis-ha --region=us-central1 `
    --format="value(status)"

# 查看实例事件
gcloud redis instances operations list --region=us-central1
```

---

## 6. Memorystore安全最佳实践

### 6.1 网络安全

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Memorystore安全最佳实践                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   1. 网络隔离                                                            │
│   ├── 使用VPC原生网络                                                   │
│   ├── 禁止公开访问Redis                                                 │
│   ├── 使用Private Service Connect(PSC)                                 │
│   └── 配置防火墙规则限制访问                                            │
│                                                                         │
│   2. 传输加密                                                            │
│   ├── 启用TLS传输加密                                                   │
│   ├── 使用AUTH功能                                                      │
│   └── 定期轮换证书                                                       │
│                                                                         │
│   3. 访问控制                                                            │
│   ├── 使用服务账号认证                                                   │
│   ├── 避免使用默认服务账号                                               │
│   └── 实施最小权限原则                                                   │
│                                                                         │
│   4. 监控审计                                                            │
│   ├── 启用Cloud Audit Logs                                              │
│   ├── 设置异常访问告警                                                   │
│   └── 定期审查访问日志                                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 VPC配置

```bash
# ============================================================
# 创建专用VPC for Memorystore
# ============================================================

# 创建自定义VPC
gcloud compute networks create redis-vpc `
    --subnet-mode=custom

# 创建子网(需要留出足够IP空间供Redis使用)
gcloud compute networks subnets create redis-subnet `
    --network=redis-vpc `
    --region=us-central1 `
    --range=10.0.0.0/24

# 创建Redis实例(使用专用VPC)
gcloud redis instances create my-redis `
    --region=us-central1 `
    --size=1 `
    --tier=STANDARD `
    --network=projects/PROJECT_ID/global/networks/redis-vpc

# ============================================================
# 配置防火墙规则
# ============================================================

# 允许GKE节点访问Redis
gcloud compute firewall-rules create allow-redis-from-gke `
    --network=redis-vpc `
    --allow=tcp:6379 `
    --source-tags=gke-nodes `
    --target-tags=redis-instance

# 允许Cloud Run访问Redis
gcloud compute firewall-rules create allow-redis-from-run `
    --network=redis-vpc `
    --allow=tcp:6379 `
    --source-ranges=10.8.0.0/28 `
    --target-tags=redis-instance
```

### 6.3 AUTH和TLS配置

```bash
# ============================================================
# 启用AUTH
# ============================================================

# 创建带AUTH的Redis实例
gcloud redis instances create my-redis-auth `
    --region=us-central1 `
    --size=1 `
    --tier=STANDARD `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --enable-auth

# 获取AUTH密码
gcloud redis instances describe my-redis-auth --region=us-central1 `
    --format="value(serverCaCerts[0].sha256Fingerprint)"

# 更新实例启用AUTH
gcloud redis instances update my-redis `
    --region=us-central1 `
    --enable-auth

# ============================================================
# 启用TLS
# ============================================================

# 创建带TLS的Redis实例
gcloud redis instances create my-redis-tls `
    --region=us-central1 `
    --size=1 `
    --tier=STANDARD `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --transit-encryption-mode=SERVER_AUTHENTICATION

# 更新实例启用TLS
gcloud redis instances update my-redis `
    --region=us-central1 `
    --transit-encryption-mode=SERVER_AUTHENTICATION

# 下载证书
gcloud redis instances describe my-redis-tls --region=us-central1 `
    --format="value(serverCaCerts[0].cert)" > /tmp/redis.crt
```

---

## 7. 监控和维护

### 7.1 Cloud Monitoring集成

```bash
# ============================================================
# 查看Redis指标
# ============================================================

# 列出Redis可用指标
gcloud monitoring metrics list --filter="metric.type:starts_with('redis')"

# 主要指标:
# - redis.googleapis.com/instance/cpu/utilization
# - redis.googleapis.com/instance/memory/usage
# - redis.googleapis.com/instance/memory/usage/peak
# - redis.googleapis.com/instance/stats/connected_clients
# - redis.googleapis.com/instance/stats/keyspace
# - redis.googleapis.com/instance/stats/evicted_keys
# - redis.googleapis.com/instance/stats/rejected_connections

# ============================================================
# 创建告警策略
# ============================================================

# CPU使用率告警
gcloud monitoring policies create `
    --notification-channels=CHANNEL_ID `
    --display-name="Redis High CPU" `
    --condition-display-name="CPU > 80%" `
    --condition-filter='metric.type="redis.googleapis.com/instance/cpu/utilization" resource.type="redis_instance"' `
    --condition-threshold-value=0.8 `
    --condition-threshold-comparison=COMPARISON_GT `
    --condition-threshold-duration=300s
```

### 7.2 维护窗口

```bash
# ============================================================
# 维护窗口配置
# ============================================================

# 设置维护窗口(周日凌晨)
gcloud redis instances update my-redis `
    --region=us-central1 `
    --maintenance-window-day=sunday `
    --maintenance-window-start-time=03:00

# 查看维护排程
gcloud redis instances describe my-redis --region=us-central1 `
    --format="value(maintenanceWindow)"

# 查看实例版本和升级信息
gcloud redis instances list --region=us-central1 `
    --format="table(name,redisVersion,tier)"
```

---

## 8. 知识检测

### 选择题

1. Memorystore for Redis Standard Tier提供多少可用性SLA?
   - A. 99.5%
   - B. 99.9%
   - C. 99.99% ✓
   - D. 99.999%

2. 下列哪种数据结构是Memcached支持的?
   - A. Hash
   - B. List
   - C. Set
   - D. 仅字符串 ✓

3. 在GKE中连接Memorystore需要什么前提条件?
   - A. 使用公共网络
   - B. VPC原生集群 ✓
   - C. 使用Istio
   - D. 启用Anthos

4. Cloud Run服务连接Memorystore需要配置什么?
   - A. Cloud CDN
   - B. VPC Connector ✓
   - C. Cloud Load Balancing
   - D. Cloud Armor

5. Memorystore Standard Tier的故障转移是?
   - A. 手动触发
   - B. 自动 ✓
   - C. 不支持故障转移
   - D. 需要重启实例

---

## 扩展阅读

- [Memorystore for Redis文档](https://cloud.google.com/memorystore/docs/redis)
- [Memorystore连接指南](https://cloud.google.com/memorystore/docs/redis/connect-redis-instance)
- [GKE网络指南](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [Cloud Run VPC集成](https://cloud.google.com/run/docs/configuring/vpc)
- [Memorystore监控](https://cloud.google.com/memorystore/docs/redis/monitoring)

---

## 学习进度

- [ ] 深入理解Memorystore for Redis架构和核心概念
- [ ] 掌握Memorystore for Redis的基本操作命令
- [ ] 掌握Memorystore与GKE的集成方式
- [ ] 掌握在Cloud Run、Cloud Functions等服务中使用Memorystore
- [ ] 理解Memorystore高可用配置和灾难恢复
- [ ] 掌握Memorystore安全最佳实践
