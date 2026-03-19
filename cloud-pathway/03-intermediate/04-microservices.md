# 微服务架构

## 本章概述

微服务架构是现代云原生应用的核心架构模式。本章将学习微服务的设计原则、实现模式和最佳实践。

## 学习目标

- 理解微服务设计原则
- 掌握API网关模式
- 学会服务发现机制
- 理解配置中心设计
- 掌握熔断器模式
- 学会分布式链路追踪

---

## 1. 微服务设计原则

### 1.1 单体 vs 微服务

```
单体架构                              微服务架构

┌─────────────────────────────┐     ┌─────────────────────────────────────┐
│         单体应用             │     │              微服务                  │
│  ┌───────────────────────┐  │     │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│  │        用户模块        │  │     │  │用户 │ │订单 │ │商品 │ │支付 │  │
│  ├───────────────────────┤  │     │  │服务 │ │服务 │ │服务 │ │服务 │  │
│  │        订单模块        │  │     │  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘  │
│  ├───────────────────────┤  │     │     │       │       │       │     │
│  │        商品模块        │  │     │     ▼       ▼       ▼       ▼     │
│  ├───────────────────────┤  │     │  ┌─────────────────────────────┐  │
│  │        支付模块        │  │     │  │         API 网关             │  │
│  └───────────────────────┘  │     │  └─────────────────────────────┘  │
│  ┌───────────────────────┐  │     │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│  │       共享数据库        │  │     │  │ DB1 │ │ DB2 │ │ DB3 │ │ DB4 │  │
│  └───────────────────────┘  │     │  └─────┘ └─────┘ └─────┘ └─────┘  │
└─────────────────────────────┘     └─────────────────────────────────────┘
```

### 1.2 服务拆分原则

| 原则 | 说明 |
|-----|------|
| 单一职责 | 每个服务只做一件事 |
| 高内聚低耦合 | 相关功能放在一起，服务间依赖最小化 |
| 业务边界 | 按业务领域划分，领域驱动设计(DDD) |
| 数据独立 | 每个服务独立数据库，通过API共享数据 |
| 团队自治 | 服务与团队对应，独立开发部署 |

---

## 2. API网关

### 2.1 网关职责

```
API网关职责

请求路由 ────► 将请求路由到对应服务
负载均衡 ────► 分发请求到多个实例
认证授权 ────► 统一身份验证
限流熔断 ────► 保护后端服务
协议转换 ────► HTTP/gRPC/GraphQL转换
日志监控 ────► 统一日志收集
```

### 2.2 Kong网关配置

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: my-service-config
proxy:
  path: /api/v1
route:
  methods:
  - GET
  - POST
  strip_path: true
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-api
  annotations:
    kubernetes.io/ingress.class: kong
    konghq.com/override: my-service-config
    konghq.com/plugins: rate-limiting,jwt-auth
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
```

---

## 3. 服务发现

### 3.1 服务发现模式

```
服务发现模式

客户端发现
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Client  │────►│ Service │────►│ Service │
│         │     │Registry │     │Instance │
└─────────┘     └─────────┘     └─────────┘
     │
     └────────────────────────────────────►

服务端发现
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Client  │────►│  Load   │────►│ Service │
│         │     │Balancer │     │Instance │
└─────────┘     └─────────┘     └─────────┘
```

### 3.2 Kubernetes服务发现

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: user-service-headless
spec:
  clusterIP: None
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 8080
```

---

## 4. 配置中心

### 4.1 配置中心架构

```
配置中心架构

┌─────────────────────────────────────────────────────────────┐
│                     Config Server                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Git Repository                     │   │
│  │  ├── application.yml                                 │   │
│  │  ├── application-dev.yml                             │   │
│  │  ├── application-prod.yml                            │   │
│  │  └── user-service.yml                                │   │
│  └─────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  User Service │   │ Order Service │   │ Product Svc   │
└───────────────┘   └───────────────┘   └───────────────┘
```

### 4.2 Consul配置

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: consul-config
data:
  user-service.json: |
    {
      "service": {
        "name": "user-service",
        "tags": ["api", "v1"],
        "port": 8080,
        "check": {
          "http": "http://localhost:8080/health",
          "interval": "10s"
        }
      }
    }
```

---

## 5. 熔断器模式

### 5.1 熔断器状态

```
熔断器状态机

          失败率超过阈值
    ┌─────────────────────────┐
    │                         │
    ▼                         │
┌─────────┐    成功      ┌─────────┐
│  CLOSED │◄────────────│   OPEN  │
└─────────┘              └────┬────┘
    │                         │
    │                    超时后
    │                         │
    │                         ▼
    │                   ┌─────────┐
    └──────────────────►│HALF-OPEN│
                        └─────────┘

CLOSED: 正常状态，请求正常通过
OPEN: 熔断状态，请求直接失败
HALF-OPEN: 半开状态，允许部分请求测试
```

### 5.2 Resilience4j配置

```yaml
resilience4j:
  circuitbreaker:
    instances:
      userService:
        slidingWindowSize: 10
        failureRateThreshold: 50
        waitDurationInOpenState: 10s
        permittedNumberOfCallsInHalfOpenState: 3
        slidingWindowType: COUNT_BASED
        
  retry:
    instances:
      userService:
        maxAttempts: 3
        waitDuration: 1s
        
  ratelimiter:
    instances:
      userService:
        limitForPeriod: 10
        limitRefreshPeriod: 1s
```

---

## 6. 链路追踪

### 6.1 分布式追踪原理

```
分布式追踪流程

请求流程：
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  API    │────►│  User   │────►│  Order  │────►│ Payment │
│ Gateway │     │ Service │     │ Service │     │ Service │
└─────────┘     └─────────┘     └─────────┘     └─────────┘

Trace: 全局唯一ID，贯穿整个请求链路
Span: 每个服务的操作单元

Trace ID: abc123
├── Span 1: API Gateway (parent: null)
│   ├── Span 2: User Service (parent: Span 1)
│   └── Span 3: Order Service (parent: Span 1)
│       └── Span 4: Payment Service (parent: Span 3)
```

### 6.2 Jaeger配置

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
spec:
  template:
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:latest
        ports:
        - containerPort: 16686
        - containerPort: 14268
        env:
        - name: COLLECTOR_ZIPKIN_HTTP_PORT
          value: "9411"
```

### 6.3 分布式追踪深度原理

**分布式追踪是怎么工作的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              分布式追踪核心机制解析                                 │
└─────────────────────────────────────────────────────────────────┘

Span与Trace概念：

┌─────────────────────────────────────────────────────────────────┐
│  Trace（追踪）：                                                │
│  ├── 一个完整的请求链路                                     │
│  ├── 从入口到出口的完整路径                                 │
│  ├── 由多个Span组成                                        │
│  └── 唯一标识：Trace ID                                     │
│                                                                  │
│  Span（跨度）：                                                  │
│  ├── 单个服务或操作的执行时间                                │
│  ├── 包含开始时间、结束时间、元数据                          │
│  ├── 通过Parent ID关联父子关系                              │
│  └── 唯一标识：Span ID                                      │
│                                                                  │
│  示例：                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Trace ID: abc123                                    │   │
│  │                                                          │   │
│  │  ┌─────────────────────────────────────────────┐       │   │
│  │  │ Span 1: API Gateway                 │       │   │
│  │  │ Parent: null                            │       │   │
│  │  │ Duration: 50ms                         │       │   │
│  │  └─────────────────────────────────────────────┘       │   │
│  │              │                                             │   │
│  │  ┌─────────────────────────────────────────────┐       │   │
│  │  │ Span 2: User Service                │       │   │
│  │  │ Parent: Span 1                        │       │   │
│  │  │ Duration: 30ms                         │       │   │
│  │  └─────────────────────────────────────────────┘       │   │
│  │              │                                             │   │
│  │  ┌─────────────────────────────────────────────┐       │   │
│  │  │ Span 3: Order Service               │       │   │
│  │  │ Parent: Span 1                        │       │   │
│  │  │ Duration: 40ms                         │       │   │
│  │  └─────────────────────────────────────────────┘       │   │
│  │              │                                             │   │
│  │  ┌─────────────────────────────────────────────┐       │   │
│  │  │ Span 4: Payment Service             │       │   │
│  │  │ Parent: Span 3                        │       │   │
│  │  │ Duration: 35ms                         │       │   │
│  │  └─────────────────────────────────────────────┘       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

追踪数据采集流程：

┌─────────────────────────────────────────────────────────────────┐
│  OpenTelemetry追踪流程：                                      │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 应用埋点                                           │   │
│  │  ├── 集成OpenTelemetry SDK                            │   │
│  │  ├── 配置Tracer                                         │   │
│  │  ├── 创建Span                                           │   │
│  │  └── 添加上下文信息                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  2. 数据导出                                           │   │
│  │  ├── OTLP协议 (OpenTelemetry Protocol)              │   │
│  │  ├── gRPC或HTTP传输                                    │   │
│  │  ├── 批量发送Span                                     │   │
│  │  └── 异步非阻塞                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  3. 收集器处理                                         │   │
│  │  ├── OpenTelemetry Collector                             │   │
│  │  ├── 接收Span数据                                      │   │
│  │  ├── 处理和转换                                        │   │
│  │  └── 批量导出到后端                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  4. 后端存储                                           │   │
│  │  ├── Jaeger/Zipkin                                     │   │
│  │  ├── Elasticsearch/Cassandra                            │   │
│  │  ├── 存储Span数据                                      │   │
│  │  └── 提供查询接口                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  5. 可视化展示                                         │   │
│  │  ├── Jaeger UI                                          │   │
│  │  ├── 查询Trace                                         │   │
│  │  ├── 显示调用链                                         │   │
│  │  └── 分析性能瓶颈                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

采样策略：

┌─────────────────────────────────────────────────────────────────┐
│  为什么需要采样？                                               │
│                                                                  │
│  问题：                                                          │
│  - 高流量下，追踪数据量巨大                                   │
│  - 存储成本高                                                 │
│  - 查询性能下降                                               │
│                                                                  │
│  解决方案：采样策略                                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 固定采样率                                         │   │
│  │  ├── 采样率：1% (每100个请求采样1个)                 │   │
│  │  ├── 优点：简单可控                                       │   │
│  │  └── 缺点：可能遗漏重要错误                              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  2. 动态采样率                                         │   │
│  │  ├── 根据流量自动调整                                   │   │
│  │  ├── 低流量：高采样率                                    │   │
│  │  ├── 高流量：低采样率                                    │   │
│  │  └── 平衡成本和覆盖率                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  3. 智能采样                                           │   │
│  │  ├── 错误请求：100%采样                                │   │
│  │  ├── 慢请求：100%采样                                   │   │
│  │  ├── 正常请求：低采样率                                  │   │
│  │  └── 聚焦问题场景                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 实操项目

### 项目：微服务电商系统

```yaml
docker-compose.yml

version: '3.8'

services:
  api-gateway:
    image: kong:latest
    ports:
    - "8000:8000"
    - "8443:8443"
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /etc/kong/kong.yml

  user-service:
    build: ./user-service
    ports:
    - "8081:8080"
    environment:
      - DATABASE_URL=postgresql://user:pass@user-db:5432/users
      - REDIS_URL=redis://redis:6379

  order-service:
    build: ./order-service
    ports:
    - "8082:8080"
    environment:
      - DATABASE_URL=postgresql://user:pass@order-db:5432/orders
      - USER_SERVICE_URL=http://user-service:8080

  product-service:
    build: ./product-service
    ports:
    - "8083:8080"
    environment:
      - DATABASE_URL=postgresql://user:pass@product-db:5432/products
      - ELASTICSEARCH_URL=http://elasticsearch:9200

  user-db:
    image: postgres:15
    environment:
      POSTGRES_DB: users
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass

  order-db:
    image: postgres:15
    environment:
      POSTGRES_DB: orders
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass

  product-db:
    image: postgres:15
    environment:
      POSTGRES_DB: products
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass

  redis:
    image: redis:7-alpine

  elasticsearch:
    image: elasticsearch:8.9.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
```

---

## 8. 知识检测

### 选择题

1. 微服务架构的核心原则是什么？
   - A. 共享数据库
   - B. 服务独立部署
   - C. 单一代码库
   - D. 统一技术栈

2. API网关的主要职责不包括？
   - A. 请求路由
   - B. 认证授权
   - C. 数据存储
   - D. 负载均衡

3. 熔断器的OPEN状态表示什么？
   - A. 正常状态
   - B. 熔断状态
   - C. 半开状态
   - D. 关闭状态

---

## 9. 扩展阅读

- [微服务设计](https://book.douban.com/subject/25866950/)
- [构建微服务](https://book.douban.com/subject/26855423/)
- [Istio官方文档](https://istio.io/latest/docs/)

---

## 学习进度

- [ ] 理解微服务设计原则
- [ ] 掌握API网关模式
- [ ] 学会服务发现机制
- [ ] 理解配置中心设计
- [ ] 掌握熔断器模式
- [ ] 学会链路追踪
- [ ] 完成实操项目
