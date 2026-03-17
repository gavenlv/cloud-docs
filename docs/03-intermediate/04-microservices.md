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
