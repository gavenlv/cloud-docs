# GCP架构设计最佳实践

## 本章概述

云架构设计是将业务需求转化为可落地技术方案的过程。一个好的架构需要平衡可用性、可扩展性、可维护性、安全性和成本等多个方面。本章深入讲解GCP架构设计最佳实践，包括高可用架构、微服务架构、事件驱动架构和安全架构的设计原则与实战操作，帮助你理解为什么需要这些架构模式，以及如何在Windows环境下完成配置和部署。

## 学习目标

- 理解云架构设计核心原则
- 掌握高可用架构设计方法
- 学会微服务架构设计模式
- 理解事件驱动架构
- 掌握安全架构设计
- 理解成本优化策略

---

## 1. 云架构设计核心原则

### 1.1 为什么架构设计如此重要？

```
架构设计的重要性

┌─────────────────────────────────────────────────────────────────────────┐
│                    架构设计决定系统命运                                   │
│                                                                         │
│  好的架构：                                                            │
│  ├── 可扩展 ─── 业务增长时轻松扩展                                     │
│  ├── 高可用 ─── 故障时自动恢复                                        │
│  ├── 易维护 ─── 修改成本低                                            │
│  ├── 安全可靠 ─── 保护数据和业务                                       │
│  └── 成本优化 ─── 只为需要的资源付费                                   │
│                                                                         │
│  不好的架构：                                                          │
│  ├── 难以扩展 ─── 每次增长都是灾难                                     │
│  ├── 频繁故障 ─── 故障恢复困难                                         │
│  ├── 修改困难 ─── 改一处动全身                                         │
│  ├── 安全风险 ─── 容易被攻击                                          │
│  └── 成本失控 ─── 资源浪费严重                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 架构设计核心原则

```
云架构设计七大原则

┌─────────────────────────────────────────────────────────────────────────┐
│                    云架构设计核心原则                                     │
│                                                                         │
│  1. 弹性 (Elasticity)                                                  │
│     └── 根据负载自动扩缩容                                              │
│                                                                         │
│  2. 冗余 (Redundancy)                                                  │
│     └── 消除单点故障                                                    │
│                                                                         │
│  3. 可观测性 (Observability)                                           │
│     └── 监控、日志、追踪                                                │
│                                                                         │
│  4. 自动化 (Automation)                                                │
│     └── 自动恢复、自动扩展                                             │
│                                                                         │
│  5. 安全性 (Security)                                                  │
│     └── 纵深防御、最小权限                                             │
│                                                                         │
│  6. 可维护性 (Maintainability)                                         │
│     └── 模块化、解耦                                                    │
│                                                                         │
│  7. 成本优化 (Cost Optimization)                                       │
│     └── 按需付费、预留实例                                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 高可用架构

### 2.1 理解高可用架构

**为什么需要高可用？**

```
系统故障的代价

┌─────────────────────────────────────────────────────────────────────────┐
│                    停机时间成本分析                                       │
│                                                                         │
│  例子：电商网站每秒收入 $1000                                           │
│                                                                         │
│  停机1分钟 = $60,000 损失                                              │
│  停机1小时 = $3,600,000 损失                                           │
│  停机1天 = $86,400,000 损失                                            │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    可用性等级                                   │   │
│  │                                                                  │   │
│  │  99% (2个9)   ─── 每年停机 87.6小时   ─── 电商不可接受        │   │
│  │  99.9% (3个9) ─── 每年停机 8.76小时    ─── 多数应用目标        │   │
│  │  99.99% (4个9)─── 每年停机 52分钟      ─── 关键业务目标        │   │
│  │  99.999% (5个9)─── 每年停机 5.26分钟   ─── 电信/金融级        │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 高可用架构模式

```
多层高可用架构

┌─────────────────────────────────────────────────────────────────────────┐
│                    GCP高可用架构分层                                      │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    第1层：DNS和全局负载均衡                        │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Cloud DNS + Global External HTTP(S) Load Balancer     │    │   │
│  │  │  - 全球 Anycast IP                                         │    │   │
│  │  │  - 自动健康检查                                             │    │   │
│  │  │  - DDoS保护                                                │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    第2层：计算服务高可用                          │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Cloud Run / GKE (多区域副本)                            │    │   │
│  │  │  - 多可用区部署                                            │    │   │
│  │  │  - 自动扩缩容                                               │    │   │
│  │  │  - 健康检查和自动恢复                                      │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    第3层：数据层高可用                            │   │
│  │                                                                  │   │
│  │  ┌───────────────────┐  ┌───────────────────┐                  │   │
│  │  │    Cloud SQL     │  │  Cloud Memorystore│                  │   │
│  │  │  高可用配置      │  │     Redis 集群    │                  │   │
│  │  │  - 主从复制      │  │  - 主从复制       │                  │   │
│  │  │  - 自动故障转移  │  │  - 自动故障转移  │                  │   │
│  │  └───────────────────┘  └───────────────────┘                  │   │
│  │                                                                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │                   Cloud Storage                           │  │   │
│  │  │         多区域存储 + 版本控制 + 生命周期策略               │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    第4层：网络和安全                              │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Cloud Armor (WAF/DDoS防护)                              │    │   │
│  │  │  VPC Flow Logs (网络流量监控)                           │    │   │
│  │  │  Cloud NAT (出站流量管理)                               │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 高可用架构操作 - Windows PowerShell

```powershell
# ============================================================
# 高可用架构配置 - Windows PowerShell
# ============================================================

# ========== 1. 创建高可用Cloud Run服务 ==========

# 创建Cloud Run服务（高可用配置）
gcloud run deploy my-ha-service `
    --image gcr.io/PROJECT_ID/my-app `
    --region us-central1 `
    --platform managed `
    --cpu 2 `
    --memory 1Gi `
    --min-instances 2 `
    --max-instances 100 `
    --concurrency 80 `
    --port 8080 `
    --allow-unauthenticated

# 更新服务为高可用配置
gcloud run services update my-ha-service `
    --region us-central1 `
    --min-instances 2 `
    --max-instances 100 `
    --cpu 2 `
    --memory 1Gi

# ========== 2. 配置健康检查 ==========

# Cloud Run 健康检查（通过服务配置）
# 在服务配置中设置：
# readinessProbe:
#   httpGet:
#     path: /health
#     port: 8080
#   initialDelaySeconds: 5
#   periodSeconds: 5
# livenessProbe:
#   httpGet:
#     path: /health
#     port: 8080
#   initialDelaySeconds: 30
#   periodSeconds: 10

# ========== 3. 创建全局负载均衡 ==========

# 创建健康检查
gcloud compute health-checks create http my-health-check `
    --description="Health check for HA service" `
    --port 80 `
    --request-path=/health `
    --check-interval 10s `
    --timeout 5s `
    --healthy-threshold 2 `
    --unhealthy-threshold 3

# 创建后端服务
gcloud compute backend-services create my-backend-service `
    --protocol HTTPS `
    --health-checks my-health-check `
    --enable-logging `
    --logging-flow-sampling 0.5

# 添加后端（Cloud Run）
gcloud compute backend-services add-backend my-backend-service `
    --global `
    --backend-service-group=gcloud-neg `
    --gcb-neg="network_endpoint_groups/lb-default-my-ha-service-8080"

# 创建URL映射
gcloud compute url-maps create my-url-map `
    --default-service my-backend-service

# 创建目标HTTPS代理
gcloud compute target-https-proxies create my-https-proxy `
    --url-map my-url-map `
    --ssl-certificates my-ssl-cert

# 创建全球转发规则
gcloud compute forwarding-rules create my-global-forwarding-rule `
    --global `
    --target-https-proxy my-https-proxy `
    --ports 443

# ========== 4. 配置GKE高可用 ==========

# 创建GKE集群（高可用配置）
gcloud container clusters create my-ha-cluster `
    --zone us-central1-a `
    --node-locations us-central1-a,us-central1-b,us-central1-c `
    --num-nodes=3 `
    --machine-type n2-standard-4 `
    --enable-autoscaling `
    --min-nodes 3 `
    --max-nodes 20 `
    --enable-autorepair `
    --enable-autoupgrade `
    --enable-vertical-pod-autoscaling `
    --enable-shielded-nodes

# 创建高可用Deployment
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ha-app
  labels:
    app: ha-app
spec:
  replicas: 6
  selector:
    matchLabels:
      app: ha-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: ha-app
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: ha-app
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: ha-app
      containers:
      - name: app
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
"@ | Out-File -FilePath ha-deployment.yaml -Encoding UTF8

# 应用部署
kubectl apply -f ha-deployment.yaml

# ========== 5. 配置高可用数据库 ==========

# 创建Cloud SQL高可用实例
gcloud sql instances create my-ha-sql `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-4 `
    --region=us-central1 `
    --availability-type=regional `
    --storage-size=100GB `
    --storage-type=pd-ssd `
    --backup-start-time=03:00 `
    --enable-bin-log `
    --maintenance-window-day=SUN `
    --maintenance-window-hour=04:00
```

---

## 3. 微服务架构

### 3.1 理解微服务架构

**为什么需要微服务？**

```
单体架构 vs 微服务架构

┌─────────────────────────────────────────────────────────────────────────┐
│                       单体架构问题                                        │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    巨大的单体应用                                  │   │
│  │  ┌─────────┬─────────┬─────────┬─────────┐                     │   │
│  │  │ 用户    │ 订单    │ 支付    │ 库存    │                     │   │
│  │  │ 模块    │ 模块    │ 模块    │ 模块    │                     │   │
│  │  └─────────┴─────────┴─────────┴─────────┘                     │   │
│  │                    │                                             │   │
│  │                    ▼                                             │   │
│  │              紧耦合 ─── 修改一处，影响全局                        │   │
│  │              部署困难 ─── 每次发布需要重建整个应用                │   │
│  │              技术栈限制 ─── 只能用一种技术                        │   │
│  │              扩展困难 ─── 需要扩展整个应用                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                       微服务架构优势                                      │
│                                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐                 │
│  │ 用户    │  │ 订单    │  │ 支付    │  │ 库存    │                 │
│  │ 服务    │  │ 服务    │  │ 服务    │  │ 服务    │                 │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘                 │
│       │            │            │            │                        │
│       └────────────┼────────────┼────────────┘                        │
│                    ▼                                                 │
│            ┌─────────────┐                                           │
│            │  服务网格   │                                           │
│            │ (Service   │                                           │
│            │  Mesh)    │                                           │
│            └─────────────┘                                           │
│                                                                         │
│  优势：                                                               │
│  - 独立部署 ─── 每个服务可以单独部署                                  │
│  - 独立扩展 ─── 按需扩展每个服务                                     │
│  - 技术多样 ─── 每个服务可以用不同技术                                │
│  - 故障隔离 ─── 一个服务故障不影响其他                               │
│  - 团队独立 ─── 团队可以独立开发和维护                               │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 微服务设计模式

```
微服务设计模式

┌─────────────────────────────────────────────────────────────────────────┐
│                    微服务核心设计模式                                    │
│                                                                         │
│  1. API网关模式                                                        │
│     └── 统一入口、认证、限流、路由                                      │
│                                                                         │
│  2. 服务发现                                                           │
│     └── 自动发现服务地址                                               │
│                                                                         │
│  3. 熔断器模式                                                         │
│     └── 防止故障级联传播                                               │
│                                                                         │
│  4.  Circuit Breaker                                                  │
│     └── 快速失败，保护系统                                             │
│                                                                         │
│  5. 事件驱动                                                           │
│     └── 服务间异步通信                                                │
│                                                                         │
│  6. CQRS                                                              │
│     └── 命令查询职责分离                                               │
│                                                                         │
│  7. Saga模式                                                           │
│     └── 分布式事务管理                                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 微服务架构实现

```powershell
# ============================================================
# 微服务架构配置 - Windows PowerShell
# ============================================================

# ========== 1. 创建微服务（多个Cloud Run服务）==========

# 创建用户服务
gcloud run deploy user-service `
    --image gcr.io/PROJECT_ID/user-service `
    --region us-central1 `
    --platform managed `
    --allow-unauthenticated

# 创建订单服务
gcloud run deploy order-service `
    --image gcr.io/PROJECT_ID/order-service `
    --region us-central1 `
    --platform managed `
    --allow-unauthenticated

# 创建支付服务
gcloud run deploy payment-service `
    --image gcr.io/PROJECT_ID/payment-service `
    --region us-central1 `
    --platform managed `
    --allow-unauthenticated

# ========== 2. 配置服务间通信 ==========

# 获取服务URL
gcloud run services describe user-service --region us-central1 --format="value(status.url)"
gcloud run services describe order-service --region us-central1 --format="value(status.url)"

# 配置VPC连接（私有服务访问）
gcloud compute networks vpc-access connectors create service-connector `
    --region us-central1 `
    --subnet-name=proxy-subnet `
    --subnet-secondary-range=proxy-range=10.10.0.0/28

# 配置服务使用VPC连接
gcloud run services update user-service `
    --region us-central1 `
    --vpc-connector=projects/PROJECT_ID/locations/us-central1/connectors/service-connector `
    --egress=all

# ========== 3. 配置服务网格 (Anthos Service Mesh) ==========

# 启用服务网格
gcloud container clusters update my-cluster `
    --enable-mesh-certificates `
    --region us-central1

# 安装Anthos Service Mesh
kubectl apply -f asm/istio-configuration-package.yaml

# 创建DestinationRule（熔断配置）
@"
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: order-service
spec:
  host: order-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        h2UpgradePolicy: UPGRADE
        http2MaxRequests: 1000
        maxRequestsPerConnection: 10
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
"@ | Out-File -FilePath destination-rule.yaml -Encoding UTF8

kubectl apply -f destination-rule.yaml

# ========== 4. 配置API网关 (Cloud Endpoints) ==========

# 创建OpenAPI规范
@"
openapi: 3.0.0
info:
  title: Microservices API
  version: 1.0.0
servers:
  - url: https://my-api.endpoints.PROJECT_ID.cloud.goog
paths:
  /users/{id}:
    get:
      operationId: getUser
      summary: Get user by ID
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: User response
      x-google-backend:
        address: https://user-service-xxx.us-central1.run.app
  /orders:
    get:
      operationId: listOrders
      summary: List orders
      responses:
        '200':
          description: Orders response
      x-google-backend:
        address: https://order-service-xxx.us-central1.run.app
"@ | Out-File -FilePath openapi.yaml -Encoding UTF8

# 部署API
gcloud endpoints services deploy openapi.yaml
```

---

## 4. 事件驱动架构

### 4.1 理解事件驱动架构

**为什么需要事件驱动？**

```
同步调用 vs 事件驱动

┌─────────────────────────────────────────────────────────────────────────┐
│                       同步调用问题                                        │
│                                                                         │
│  服务A ──────> 服务B ──────> 服务C ──────> 服务D                       │
│       │              │              │              │                    │
│       │              │              │              │                    │
│       ▼              ▼              ▼              ▼                    │
│    等待完成       等待完成       等待完成       等待完成                │
│                                                                         │
│  问题：                                                               │
│  - 强耦合 ─── A需要知道B的存在                                         │
│  - 等待时间长 ─── 所有服务串行执行                                     │
│  - 故障传播 ─── 任何一个服务故障都会导致失败                            │
│  - 扩展困难 ─── 需要同时扩展所有服务                                   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                       事件驱动优势                                       │
│                                                                         │
│  ┌─────────┐                                                         │
│  │ 事件总线 │  (Pub/Sub)                                             │
│  └────┬────┘                                                         │
│       │发布事件                                                       │
│       ▼                                                               │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                              │
│  │ 服务A   │  │ 服务B   │  │ 服务C   │                              │
│  │ (处理)  │  │ (处理)  │  │ (处理)  │                              │
│  └─────────┘  └─────────┘  └─────────┘                              │
│                                                                         │
│  优势：                                                               │
│  - 松耦合 ─── 发布者不需要知道订阅者                                    │
│  - 异步处理 ─── 不需要等待                                            │
│  - 容错性强 ─── 事件可以重放                                           │
│  - 独立扩展 ─── 每个消费者独立扩展                                     │
│  - 可追溯 ─── 事件日志完整记录                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 事件驱动实现 - Windows PowerShell

```powershell
# ============================================================
# 事件驱动架构配置 - Windows PowerShell
# ============================================================

# ========== 1. 创建Pub/Sub主题 ==========

# 创建订单事件主题
gcloud pubsub topics create order-created
gcloud pubsub topics create order-updated
gcloud pubsub topics create order-cancelled

# 创建支付事件主题
gcloud pubsub topics create payment-processed
gcloud pubsub topics create payment-failed

# 创建库存事件主题
gcloud pubsub topics create inventory-reserved
gcloud pubsub topics create inventory-released

# 列出主题
gcloud pubsub topics list

# ========== 2. 创建订阅 ==========

# 创建订单服务订阅
gcloud pubsub subscriptions create order-service-sub `
    --topic=order-created `
    --ack-deadline=60 `
    --message-retention-duration=604800s `
    --retain-acked-messages=false

# 创建通知服务订阅
gcloud pubsub subscriptions create notification-sub `
    --topic=order-created `
    --push-endpoint=https://notification-service.endpoints.PROJECT_ID.cloud.goog/push

# 创建死信队列
gcloud pubsub subscriptions create order-dlq `
    --topic=order-created `
    --dead-letter-topic=order-dead-letter

# ========== 3. 配置发布 ==========

# 发布消息
gcloud pubsub topics publish order-created `
    --message='{"orderId":"ORD-123","customerId":"CUST-456","total":99.99,"items":[{"productId":"PROD-1","quantity":2}]}'

# 发布带属性消息
gcloud pubsub topics publish order-created `
    --message='{"orderId":"ORD-124"}' `
    --attribute=eventType=order.created,source=order-service

# ========== 4. 创建Cloud Scheduler定时任务 ==========

# 创建每日报告生成任务
gcloud scheduler jobs create http daily-report `
    --schedule="0 1 * * *" `
    --uri="https://report-service.endpoints.PROJECT_ID.cloud.goog/generate" `
    --http-method=POST `
    --time-zone=Asia/Shanghai

# 创建订单超时检查任务（每5分钟）
gcloud scheduler jobs create http order-timeout `
    --schedule="*/5 * * * *" `
    --uri="https://order-service.endpoints.PROJECT_ID.cloud.goog/check-timeouts" `
    --http-method=POST

# ========== 5. 配置Cloud Functions事件触发 ==========

# 创建处理订单创建的函数
gcloud functions deploy processOrder `
    --runtime python311 `
    --trigger-topic order-created `
    --entry-point process_order `
    --region us-central1 `
    --memory 256MB `
    --timeout 60s

# 创建处理支付的函数
gcloud functions deploy processPayment `
    --runtime python311 `
    --trigger-topic payment-processed `
    --entry-point process_payment `
    --region us-central1 `
    --memory 512MB `
    --timeout 120s

# ========== 6. 配置事件驱动工作流 (Cloud Workflows) ==========

# 创建工作流
gcloud workflows deploy order-processing-workflow `
    --source-yaml=order-workflow.yaml

# order-workflow.yaml 示例
@"
- steps:
  - createOrder:
      assign:
        - orderId: ${"ORD-" + string(int(current_time.timestamp()) % 100000)}
  - reserveInventory:
      call: http POST
      args:
        url: https://inventory-service.endpoints.PROJECT_ID.cloud.goog/reserve
        body:
          orderId: ${orderId}
  - processPayment:
      call: http POST
      args:
        url: https://payment-service.endpoints.PROJECT_ID.cloud.goog/process
        body:
          orderId: ${orderId}
  - sendNotification:
      call: http POST
      args:
        url: https://notification-service.endpoints.PROJECT_ID.cloud.goog/send
        body:
          orderId: ${orderId}
"@ | Out-File -FilePath order-workflow.yaml -Encoding UTF8

gcloud workflows deploy order-workflow --source-yaml=order-workflow.yaml --location=us-central1
```

---

## 5. 安全架构

### 5.1 纵深防御架构

```
纵深防御架构

┌─────────────────────────────────────────────────────────────────────────┐
│                    纵深防御安全层次                                       │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  第1层：边界安全                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Cloud Armor (WAF/DDoS防护)                             │    │   │
│  │  │  - WAF规则                                                │    │   │
│  │  │  - DDoS防护                                               │    │   │
│  │  │  - IP信誉                                                 │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  第2层：网络安全                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  VPC Firewall Rules                                     │    │   │
│  │  │  - 最小权限出口/入口                                    │    │   │
│  │  │  Cloud NAT - 统一出口IP                                 │    │   │
│  │  │  Private Google Access - 私有访问Google服务            │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  第3层：身份安全                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  IAM - 最小权限原则                                      │    │   │
│  │  │  Service Account - 程序身份                             │    │   │
│  │  │  Identity Aware Proxy - 零信任访问                      │    │   │
│  │  │  BeyondCorp Enterprise                                  │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  第4层：数据安全                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  静态加密 - KMS, Cloud HSM                              │    │   │
│  │  │  传输加密 - TLS 1.3                                     │    │   │
│  │  │  密钥管理 - Secret Manager                             │    │   │
│  │  │  数据分类 - Data Loss Prevention                        │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  第5层：应用安全                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Binary Authorization - 只运行受信任镜像              │    │   │
│  │  │  Container Analysis - 漏洞扫描                        │    │   │
│  │  │  Security Command Center - 威胁检测                   │    │   │
│  │  │  Web Risk API - 恶意URL检测                            │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 安全架构操作

```powershell
# ============================================================
# 安全架构配置 - Windows PowerShell
# ============================================================

# ========== 1. 配置VPC安全 ==========

# 创建自定义VPC
gcloud compute networks create secure-vpc `
    --subnet-mode=custom `
    --bgp-routing-mode=regional

# 创建子网（带Private Google Access）
gcloud compute networks subnets create secure-subnet `
    --network=secure-vpc `
    --region=us-central1 `
    --range=10.0.1.0/24 `
    --enable-private-ip-google-access

# 创建防火墙规则（最小权限）
gcloud compute firewall-rules create deny-all-inbound `
    --network=secure-vpc `
    --action=deny `
    --direction=ingress `
    --rules=all `
    --source-ranges=0.0.0.0/0 `
    --description="Deny all inbound traffic"

gcloud compute firewall-rules create allow-ssh-from-bastion `
    --network=secure-vpc `
    --allow=tcp:22 `
    --source-ranges=10.0.0.0/24 `
    --target-tags=bastion-host

# ========== 2. 配置IAM安全 ==========

# 创建服务账号（最小权限）
gcloud iam service-accounts create app-service-sa `
    --display-name="Application Service Account"

# 授予最小权限
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="serviceAccount:app-service-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/run.invoker"

gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="serviceAccount:app-service-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/storage.objectViewer"

# 条件角色绑定（基于资源）
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="serviceAccount:app-service-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/compute.instanceAdmin" `
    --condition="resource.name.startsWith('projects/PROJECT_ID/zones/us-central1-a/instances/prod-')"

# ========== 3. 配置数据加密 ==========

# 创建KMS密钥环
gcloud kms keyrings create secure-keyring `
    --location=global

# 创建加密密钥
gcloud kms keys create data-encryption-key `
    --keyring=secure-keyring `
    --location=global `
    --purpose=encryption `
    --rotation-period=90d `
    --next-rotation-time=2024-04-01T00:00:00Z

# 授予密钥使用权限
gcloud kms keys add-iam-policy-binding data-encryption-key `
    --keyring=secure-keyring `
    --location=global `
    --member="serviceAccount:app-service-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

# ========== 4. 配置Binary Authorization ==========

# 启用Binary Authorization
gcloud services enable binaryauthorization.googleapis.com

# 创建证明者
gcloud container binauthz attestors create my-attestor `
    --attestation-authority-note=my-attestation-authority

# 创建评价策略
@"
evaluationMode: REQUIRE_ATTESTATION
attestors:
- name: projects/PROJECT_ID/attestors/my-attestor
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: REQUIRE_ATTESTATION
"@ | Out-File -FilePath binauthz-policy.yaml -Encoding UTF8

gcloud container binauthz policy import binauthz-policy.yaml
```

---

## 6. 成本优化

### 6.1 成本优化策略

```
成本优化策略

┌─────────────────────────────────────────────────────────────────────────┐
│                    GCP成本优化四大支柱                                   │
│                                                                         │
│  1. 正确选择资源                                                        │
│     ├── 按需 vs 预留 vs 承诺使用                                       │
│     ├── 合适的大小                                                     │
│     └── 正确的工作负载类型                                             │
│                                                                         │
│  2. 自动扩缩容                                                         │
│     ├── 根据负载自动调整                                               │
│     ├── 最小实例数配置                                                 │
│     └── 避免资源闲置                                                   │
│                                                                         │
│  3. 善用免费套餐                                                       │
│     ├── 始终免费层                                                     │
│     ├── 免费试用                                                       │
│     └── credits使用                                                    │
│                                                                         │
│  4. 监控和优化                                                         │
│     ├── 成本分析                                                       │
│     ├── 异常告警                                                       │
│     └── 定期review                                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 成本优化操作

```powershell
# ============================================================
# 成本优化配置 - Windows PowerShell
# ============================================================

# ========== 1. 启用承诺使用折扣 ==========

# 查看可用的承诺使用折扣
gcloud compute regions describe us-central1 --format="get(commitmentPlans)"

# 创建承诺使用（1年期，vCPU）
gcloud compute commitments create my-commitment `
    --region=us-central1 `
    --plan=12-month `
    --resources=vcpu=4,memory=15GB

# ========== 2. 配置Cloud Run自动扩缩 ==========

# 最小实例数设为0（节省非工作时间成本）
gcloud run services update my-service `
    --region us-central1 `
    --min-instances=0 `
    --max-instances=10

# 配置并发数优化（提高资源利用率）
gcloud run services update my-service `
    --region us-central1 `
    --concurrency=100

# ========== 3. 配置GKE成本优化 ==========

# 启用节点自动池
gcloud container pools create nodepool-spot `
    --cluster=my-cluster `
    --zone=us-central1-a `
    --node-locations=us-central1-a,us-central1-b `
    --num-nodes=3 `
    --machine-type=n2-standard-4 `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=10 `
    --spot=true

# 配置Pod资源请求（确保合理分配）
@"
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
"@ | Out-File -FilePath resource-quota.yaml -Encoding UTF8

kubectl apply -f resource-quota.yaml

# ========== 4. 配置预算和告警 ==========

# 创建预算
gcloud billing budgets create `
    --billing-account=BILLING_ACCOUNT_ID `
    --display-name="Monthly Budget" `
    --threshold-rule=threshold=0.8, spend-basis=current_spend `
    --threshold-rule=threshold=1.0,spend-basis=forecasted_spend `
    --filter-prop=resources="services/4F2B8F76-9C0E-4E5B-8A2C-1B5C3D7E9F0A"

# ========== 5. 查看成本分析 ==========

# 列出当月成本
gcloud beta billing budgets list --billing-account=BILLING_ACCOUNT_ID

# 使用Billing Catalog API查看服务价格
gcloud beta services pricing list --service=compute.googleapis.com

# 导出成本数据到BigQuery
gcloud billing accounts get-iam-policy BILLING_ACCOUNT_ID
```

### 6.3 限流与熔断深度原理

**限流和熔断是怎么保护系统的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              限流算法深度解析                                     │
└─────────────────────────────────────────────────────────────────┘

限流的目的是防止系统被突发流量冲垮

┌─────────────────────────────────────────────────────────────────┐
│  1. 令牌桶算法（Token Bucket）                                   │
│                                                                  │
│  原理：                                                          │
│  - 桶以固定速率发放令牌                                          │
│  - 请求需要获取令牌才能处理                                       │
│  - 桶满时令牌溢出（不积累）                                       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    令牌桶                                │   │
│  │                                                          │   │
│  │      ┌───────────────────────┐                         │   │
│  │      │   桶容量 = 100       │  ← 突发容量              │   │
│  │      │   ○○○○○○○○○○        │                         │   │
│  │      │   ○○○○○○○○○○○○○○○○   │                         │   │
│  │      │   ...                │                         │   │
│  │      └───────────────────────┘                         │   │
│  │              │                                          │   │
│  │              ▼                                          │   │
│  │      rate = 10 req/s (固定速率补充令牌)                  │   │
│  │              │                                          │   │
│  │              ▼                                          │   │
│  │      请求到来 → 取令牌 → 有令牌 → 处理                    │   │
│  │                      → 无令牌 → 拒绝/排队                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  优势：允许一定程度的突发流量                                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  2. 漏桶算法（Leaky Bucket）                                     │
│                                                                  │
│  原理：                                                          │
│  - 请求进入桶中                                                  │
│  - 桶以固定速率漏出（处理）                                      │
│  - 桶满时拒绝请求                                                │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    漏桶                                  │   │
│  │                                                          │   │
│  │         ┌───────────────┐                              │   │
│  │         │ 请求→ → → →  │ ← 输入（可变速率）            │   │
│  │         │ ▼▼▼▼▼▼▼▼▼   │                              │   │
│  │         │ (请求队列)    │                              │   │
│  │         │ ▼▼▼▼▼▼▼▼▼   │                              │   │
│  │         └───────┬───────┘                              │   │
│  │                 │                                      │   │
│  │                 ▼ 漏出（固定速率）                       │   │
│  │            处理请求                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  优势：输出速率恒定，平滑流量                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  3. 滑动窗口计数器（Sliding Window Counter）                    │
│                                                                  │
│  原理：                                                          │
│  - 将时间划分为小窗口                                            │
│  - 统计当前窗口内的请求数                                        │
│  - 超过阈值则限流                                                │
│                                                                  │
│  例：10秒窗口，限流100次                                        │
│                                                                  │
│  时间轴：[---5s---][---5s---][---5s---]                        │
│          [  60次  ][  70次  ][  30次  ] ← 当前窗口            │
│          当前窗口 = 70次 < 100次 → 通过                        │
│                                                                  │
│  优势：比固定窗口更精确                                          │
└─────────────────────────────────────────────────────────────────┘

GCP限流实现（API Gateway + Cloud Armor）：

┌─────────────────────────────────────────────────────────────────┐
│  Cloud Armor速率限制配置：                                       │
│                                                                  │
│  gcloud compute security-policies rules create 1000 \          │
│      --security-policy=my-policy \                             │
│      --src-ip-ranges="*" \                                     │
│      --action=rate-based-ban \                                  │
│      --rate-limit-threshold-count=100 \                        │
│      --rate-limit-threshold-interval-sec=60 \                  │
│      --ban-duration-sec=300                                     │
│                                                                  │
│  解释：                                                          │
│  - 每分钟最多100个请求                                           │
│  - 超过后封禁IP 5分钟                                           │
└─────────────────────────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────────────┐
│              熔断器模式深度解析                                   │
└─────────────────────────────────────────────────────────────────┘

熔断器的目的是防止故障级联传播

┌─────────────────────────────────────────────────────────────────┐
│  熔断器三种状态：                                                │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │     CLOSED（闭合）      OPEN（断开）     HALF-OPEN    │   │
│  │         │                  │                │           │   │
│  │         ▼                  ▼                ▼           │   │
│  │    ┌─────────┐        ┌─────────┐       ┌─────────┐    │   │
│  │    │ 正常    │ 失败   │ 熔断    │ 超时   │ 测试    │    │   │
│  │    │ 请求    │ 阈值   │ 拒绝    │ 结束   │ 请求    │    │   │
│  │    │ 通过    │ 触发   │ 直接    │        │ 通过    │    │   │
│  │    └─────────┘        │ 返回    │        └─────────┘    │   │
│  │                       │ 503    │           │             │   │
│  │                       └─────────┘           ▼             │   │
│  │                                                  成功？     │   │
│  │                                                 ┌───┴───┐  │   │
│  │                                                Yes       No │   │
│  │                                                ▼           ▼  │   │
│  │                                          CLOSED        OPEN   │   │
│  │                                                          │     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

熔断器实现（Envoy Proxy）：

┌─────────────────────────────────────────────────────────────────┐
│  Envoy熔断配置：                                                 │
│                                                                  │
│  cluster:                                                       │
│    name: order_service                                         │
│    type: STRICT_DNS                                            │
│    connect_timeout: 5s                                         │
│    lb_policy: ROUND_ROBIN                                      │
│    circuit_breakers:                                           │
│      thresholds:                                               │
│      - max_connections: 100           ← 最大连接数              │
│        max_pending_requests: 100       ← 最大等待请求数          │
│        max_requests: 50               ← 最大请求数               │
│        max_retries: 3                ← 最大重试次数             │
│        track_remaining: true                                    │
│                                                                  │
│  熔断触发条件：                                                  │
│  - 连接数达到max_connections → 拒绝新连接                       │
│  - 等待请求达到max_pending_requests → 拒绝新请求                │
│  - 请求数达到max_requests → 触发熔断                            │
│  - 重试次数达到max_retries → 停止重试                          │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 服务网格Envoy Sidecar代理原理

**Sidecar代理是怎么拦截和处理请求的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              Envoy Sidecar代理工作原理                             │
└─────────────────────────────────────────────────────────────────┘

服务网格中，每个Pod都有一个Sidecar代理（Envoy）

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Pod内部结构：                                                   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │     ┌─────────────┐         ┌─────────────┐          │   │
│  │     │   App       │         │   Envoy     │          │   │
│  │     │   Container │◄───────►│   Sidecar   │          │   │
│  │     │   :8080     │         │   :15001    │          │   │
│  │     └─────────────┘         └──────┬──────┘          │   │
│  │                                      │                   │   │
│  │                                      │                                           │
│  └──────────────────────────────────────┼───────────────────┘   │
│                                          │                       │
│                              ┌───────────┘                       │
│                              ▼                                   │
│                      ┌───────────────┐                          │
│                      │    lo        │ ← localhost               │
│                      │  (虚拟网卡)  │                          │
│                      └───────────────┘                          │
│                                                                  │
│  请求流程：                                                     │
│  1. App发送请求到localhost:15001                               │
│  2. Envoy Sidecar拦截请求                                      │
│  3. Envoy应用路由/限流/熔断规则                                │
│  4. Envoy转发请求到目标服务                                    │
│  5. 响应同样经过Envoy                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Envoy监听端口：

┌─────────────────────────────────────────────────────────────────┐
│  Envoy端口映射：                                                │
│                                                                  │
│  :15001 - Envoy ingress（接收App出站请求）                      │
│  :15006 - Envoy egress（转发到其他服务）                        │
│  :15000 - Admin接口（监控和配置）                               │
│  :15020 - Health Check接口                                      │
│                                                                  │
│  iptables规则（透明拦截）：                                     │
│                                                                  │
│  # 重定向出站流量到Envoy                                        │
│  iptables -t nat -A OUTPUT -p tcp \                           │
│      --dport 8080 -j REDIRECT --to-port 15001                 │
│                                                                  │
│  # 重定向入站流量到Envoy                                        │
│  iptables -t nat -A PREROUTING -p tcp \                       │
│      --dport 8080 -j REDIRECT --to-port 15001                 │
└─────────────────────────────────────────────────────────────────┘

Envoy配置结构：

┌─────────────────────────────────────────────────────────────────┐
│  Envoy配置四大元素：                                            │
│                                                                  │
│  1. Listener（监听器）- 接收请求的入口                          │
│                                                                  │
│     listeners:                                                  │
│     - name: inbound_8080                                       │
│       address:                                                  │
│         socket_address:                                        │
│           address: 0.0.0.0                                     │
│           port_value: 15001                                    │
│       filter_chains:                                           │
│       - filters:                                               │
│         - name: envoy.filters.network.http_connection_manager  │
│           config:                                               │
│             stat_prefix: inbound                               │
│             route_config:                                      │
│               name: local_route                                │
│               virtual_hosts:                                   │
│               - name: service                                 │
│                 domains: ["*"]                                 │
│                 routes:                                        │
│                 - match: { prefix: "/" }                      │
│                   route: { cluster: backend }                  │
│                                                                  │
│  2. Cluster（集群）- 后端服务定义                               │
│                                                                  │
│     clusters:                                                   │
│     - name: backend                                           │
│       type: STRICT_DNS                                        │
│       connect_timeout: 5s                                      │
│       lb_policy: ROUND_ROBIN                                  │
│       hosts:                                                   │
│       - socket_address:                                        │
│           address: 127.0.0.1                                   │
│           port_value: 8080                                     │
│                                                                  │
│  3. Route（路由）- 请求转发规则                                 │
│                                                                  │
│     路由决定请求发送到哪个Cluster                               │
│     支持：路径匹配、权重分配、熔断等                           │
│                                                                  │
│  4. Filter（过滤器）- 请求处理链                                │
│                                                                  │
│     过滤器链：                                                  │
│     listener →限流filter →鉴权filter →路由filter →目标服务    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 架构设计底层原理深度解析

### 7.1 分布式系统一致性协议深度原理

**分布式系统是怎么保证数据一致性的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              分布式一致性模型                                       │
└─────────────────────────────────────────────────────────────────┘

分布式系统面临的核心问题：

┌─────────────────────────────────────────────────────────────────┐
│  CAP定理：                                                      │
│                                                                  │
│  一个分布式系统最多只能同时满足以下两个特性：                      │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  C (Consistency) - 一致性                                │   │
│  │  所有节点在同一时刻看到相同的数据                         │   │
│  │                                                          │   │
│  │  A (Availability) - 可用性                               │   │
│  │  每个请求都能在有限时间内得到响应                       │   │
│  │                                                          │   │
│  │  P (Partition Tolerance) - 分区容错                    │   │
│  │  系统在网络分区时仍能继续运行                           │   │
│  │                                                          │   │
│  │  现实：网络分区不可避免                                 │   │
│  │  所以实际是CA或CP的选择                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

一致性级别：

┌─────────────────────────────────────────────────────────────────┐
│  一致性级别（从强到弱）：                                        │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 强一致性 (Strong Consistency)                       │   │
│  │  ├── 写入后立即可读                                     │   │
│  │  ├── 典型：传统RDBMS                                    │   │
│  │  └── 代价：延迟高                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  2. 顺序一致性 (Sequential Consistency)                 │   │
│  │  ├── 所有进程以相同顺序看到操作                         │   │
│  │  ├── 典型：Zookeeper                                     │   │
│  │  └── 代价：中等                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  3. 最终一致性 (Eventual Consistency)                   │   │
│  │  ├── 写入后最终会传播到所有节点                        │   │
│  │  ├── 典型：DynamoDB、Cassandra                         │   │
│  │  └── 代价：延迟低                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  4. 因果一致性 (Causal Consistency)                    │   │
│  │  ├── 只保证有因果关系的操作顺序                          │   │
│  │  ├── 典型：Cassandra                                   │   │
│  │  └── 代价：较低                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

共识算法：Raft vs Paxos

┌─────────────────────────────────────────────────────────────────┐
│  Raft算法核心概念：                                             │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  节点角色：                                            │   │
│  │  ├── Leader: 处理所有写请求                             │   │
│  │  ├── Follower: 响应Leader和候选人                      │   │
│  │  └── Candidate: 参与选举                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  日志复制流程：                                        │   │
│  │  1. Client发送写请求到Leader                           │   │
│  │  2. Leader将操作追加到本地日志                         │   │
│  │  3. Leader并行发送日志到所有Follower                   │   │
│  │  4. Follower收到日志后追加到本地日志                   │   │
│  │  5. Leader收到多数派确认后提交日志                     │   │
│  │  6. Leader通知Client请求成功                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  选举流程：                                                     │
│  1. Follower超时未收到Leader心跳 → 转为Candidate             │
│  2. Candidate发起选举投票                                     │
│  3. 获得多数派票数 → 成为Leader                               │
│  4. 其他Candidate转为Follower                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 SLO/SLI/错误预算深度原理

**SRE是怎么量化系统可靠性的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              可靠性指标体系                                         │
└─────────────────────────────────────────────────────────────────┘

SLO (Service Level Objective) - 服务级别目标：

┌─────────────────────────────────────────────────────────────────┐
│  SLO定义示例：                                                   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "API服务的月度可用性达到99.9%"                         │   │
│  │                                                          │   │
│  │  分解：                                                  │   │
│  │  ├── 可用性目标: 99.9%                                 │   │
│  │  ├── 时间窗口: 30天                                     │   │
│  │  ├── 测量方法: 成功响应码/总请求数                     │   │
│  │  └── 排除项: 计划内维护                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

SLI (Service Level Indicator) - 服务级别指标：

┌─────────────────────────────────────────────────────────────────┐
│  常见SLI指标：                                                  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  可用性 = 成功请求数 / 总请求数                        │   │
│  │                                                          │   │
│  │  延迟 = P50/P95/P99响应时间                           │   │
│  │                                                          │   │
│  │  错误率 = 错误请求数 / 总请求数                        │   │
│  │                                                          │   │
│  │  吞吐量 = RPS (每秒请求数)                              │   │
│  │                                                          │   │
│  │  饱和度 = CPU/内存/磁盘使用率                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  建议使用P99而不是平均值：                                       │
│  - 平均值容易被异常值拉偏                                       │
│  - P99更能反映用户体验                                          │
│  - "我的请求99%在1秒内完成"比"平均1秒"更有意义                 │
└─────────────────────────────────────────────────────────────────┘

错误预算 (Error Budget)：

┌─────────────────────────────────────────────────────────────────┐
│  错误预算计算：                                                  │
│                                                                  │
│  月度99.9%可用性的错误预算：                                     │
│                                                                  │
│  月度总分钟数 = 30天 × 24小时 × 60分钟 = 43,200分钟           │
│                                                                  │
│  允许的不可用分钟数 = 43,200 × (1 - 0.999) = 43.2分钟         │
│                                                                  │
│  即：每月允许约43分钟不可用                                      │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  可用性目标与错误预算：                                 │   │
│  │                                                          │   │
│  │  99%    → 每月7.3小时不可用                            │   │
│  │  99.9%  → 每月43分钟不可用                             │   │
│  │  99.99% → 每月4.3分钟不可用                            │   │
│  │  99.999%→ 每月26秒不可用                               │   │
│  │                                                          │   │
│  │  每提高一个9，成本指数级增长                            │   │
│  │  建议：选择合适的SLO，不要过度追求高可用性              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

错误预算消耗策略：

┌─────────────────────────────────────────────────────────────────┐
│  消耗错误预算时的行动：                                          │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  阶段1: 错误预算充足 (80-100%)                        │   │
│  │  ├── 正常开发新功能                                   │   │
│  │  └── 可以进行风险变更                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  阶段2: 错误预算警告 (20-80%)                         │   │
│  │  ├── 减少非关键变更                                   │   │
│  │  ├── 增加监控告警                                     │   │
│  │  └── 开始准备应急响应                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  阶段3: 错误预算耗尽 (<20%)                            │   │
│  │  ├── 停止所有非必要变更                               │   │
│  │  ├── 启动应急响应流程                                 │   │
│  │  └── 专注稳定性修复                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 知识检测

### 选择题

1. 三个9（99.9%）的可用性，每年允许停机多长时间？
   - A. 8.76小时 ✓
   - B. 87.6小时
   - C. 52分钟
   - D. 5分钟

2. 微服务架构的核心优势是什么？
   - A. 单一技术栈
   - B. 独立部署和扩展 ✓
   - C. 简单易管理
   - D. 不需要测试

3. 事件驱动架构的主要特点是什么？
   - A. 同步调用
   - B. 异步处理，松耦合 ✓
   - C. 强一致性
   - D. 紧耦合

4. 纵深防御的核心原则是什么？
   - A. 只在边界防御
   - B. 多层安全防护 ✓
   - C. 只依赖防火墙
   - D. 忽视内部威胁

---

## 学习进度

- [ ] 理解云架构设计核心原则
- [ ] 掌握高可用架构设计
- [ ] 学会微服务架构设计
- [ ] 理解事件驱动架构
- [ ] 掌握安全架构设计
- [ ] 理解成本优化策略
- [ ] 完成实战项目
