# GKE Cloud Service Mesh 多集群服务管理

## 概述

Cloud Service Mesh 基于开源 Istio 技术构建。分布式服务是一个 Kubernetes Service，作为单一逻辑服务运行。这些服务比普通 Kubernetes 服务更具弹性，因为它们在相同命名空间的多个 Kubernetes 集群上运行。即使一个或多个 GKE 集群宕机，只要健康的集群能够处理预期负载，分布式服务仍可继续运行。

GKE 私有集群允许将节点和 API Server 配置为仅在 VPC 网络内可用的私有资源。在 GKE 私有集群中运行分布式服务为企业提供安全可靠的服务。

---

## 学习目标

- 创建三个 GKE 集群
- 配置两个 GKE 集群为私有集群
- 配置一个 GKE 集群（gke-ingress）作为中央配置集群
- 配置网络（NAT Gateway、Cloud Router、防火墙规则）以允许两个私有 GKE 集群之间的集群间流量和出口流量
- 配置授权网络以允许从 Cloud Shell 访问两个私有 GKE 集群的 API 服务
- 在多主模式（Multi-Primary Mode）下部署和配置多集群 Cloud Service Mesh 到两个私有集群
- 在两个私有集群上部署 Cymbal Bank 应用程序

---

## 场景说明

本实验探索如何在两个 GKE 私有集群上部署 Cymbal Bank 示例应用程序。

### Cymbal Bank 应用架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Cymbal Bank 应用架构                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        前端层                                    │   │
│  │  ┌─────────────────┐                                            │   │
│  │  │   Web Frontend  │  ◄── 客户端访问入口                        │   │
│  │  └────────┬────────┘                                            │   │
│  └───────────┼─────────────────────────────────────────────────────┘   │
│              │                                                           │
│  ┌───────────┼─────────────────────────────────────────────────────┐   │
│  │           ▼           后端服务层                                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │   Balance   │  │   Ledger    │  │   Account   │             │   │
│  │  │   Service   │  │   Service   │  │   Service   │             │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │   │
│  └─────────┼────────────────┼────────────────┼────────────────────┘   │
│            │                │                │                         │
│  ┌─────────┼────────────────┼────────────────┼────────────────────┐   │
│  │         ▼                ▼                ▼        数据层       │   │
│  │  ┌─────────────────┐  ┌─────────────────┐                      │   │
│  │  │   PostgreSQL    │  │   PostgreSQL    │                      │   │
│  │  │  (Transactions) │  │   (Accounts)    │                      │   │
│  │  │   StatefulSet   │  │   StatefulSet   │                      │   │
│  │  └─────────────────┘  └─────────────────┘                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  特点：                                                                  │
│  ├── 所有服务（除数据库外）作为分布式服务运行                           │
│  ├── Pod 在两个应用集群的相同命名空间中运行                             │
│  └── Cloud Service Mesh 使每个服务表现为单一逻辑服务                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 应用组件

| 组件 | 类型 | 说明 |
|------|------|------|
| Web Frontend | 前端服务 | 客户端访问入口 |
| Balance Service | 后端服务 | 余额查询服务 |
| Ledger Service | 后端服务 | 账本/交易记录服务 |
| Account Service | 后端服务 | 账户管理服务 |
| PostgreSQL (Transactions) | 数据库 | 交易数据存储 |
| PostgreSQL (Accounts) | 数据库 | 用户账户数据存储 |

---

## 架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        多集群 GKE 架构                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│                          ┌─────────────────┐                            │
│                          │   Cloud Shell   │                            │
│                          │   (管理节点)     │                            │
│                          └────────┬────────┘                            │
│                                   │                                      │
│                                   │ 授权网络访问                         │
│                                   ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                         VPC Network                               │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐ │  │
│  │  │                    gke-ingress 集群                          │ │  │
│  │  │                    (中央配置集群)                             │ │  │
│  │  │                                                              │ │  │
│  │  │  ├── Multi Cluster Ingress Controller                       │ │  │
│  │  │  └── Cloud Service Mesh 控制平面                             │ │  │
│  │  └─────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────┐    ┌─────────────────────────┐     │  │
│  │  │   gke-app-cluster-1     │    │   gke-app-cluster-2     │     │  │
│  │  │   (私有集群)             │    │   (私有集群)             │     │  │
│  │  │                         │    │                         │     │  │
│  │  │  ├── Cymbal Bank App    │    │  ├── Cymbal Bank App    │     │  │
│  │  │  ├── Cloud Service Mesh │    │  ├── Cloud Service Mesh │     │  │
│  │  │  └── PostgreSQL DBs     │    │  └── PostgreSQL DBs     │     │  │
│  │  │                         │    │                         │     │  │
│  │  │  ┌─────────────────┐   │    │  ┌─────────────────┐   │     │  │
│  │  │  │  NAT Gateway    │   │    │  │  NAT Gateway    │   │     │  │
│  │  │  │  Cloud Router   │   │    │  │  Cloud Router   │   │     │  │
│  │  │  └─────────────────┘   │    │  └─────────────────┘   │     │  │
│  │  └─────────────────────────┘    └─────────────────────────┘     │  │
│  │                                                                   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 集群角色

| 集群名称 | 类型 | 角色 | 说明 |
|----------|------|------|------|
| gke-ingress | 公有集群 | 中央配置集群 | Multi Cluster Ingress、Mesh 控制平面 |
| gke-app-cluster-1 | 私有集群 | 应用集群 | 运行 Cymbal Bank 应用 |
| gke-app-cluster-2 | 私有集群 | 应用集群 | 运行 Cymbal Bank 应用 |

---

## 实施步骤

### 步骤 1：环境准备

```bash
# 设置项目 ID
export PROJECT_ID=$(gcloud config get-value project)

# 设置区域
export REGION=us-central1

# 获取 Cloud Shell IP（用于授权网络）
export CLOUDSHELL_IP=$(curl -s ifconfig.me)

# 启用必要的 API
gcloud services enable \
    container.googleapis.com \
    mesh.googleapis.com \
    cloudresourcemanager.googleapis.com \
    gkehub.googleapis.com \
    trafficdirector.googleapis.com
```

### 步骤 2：创建 GKE 集群

#### 2.1 创建中央配置集群（gke-ingress）

```bash
gcloud container clusters create gke-ingress \
    --region=${REGION} \
    --num-nodes=1 \
    --machine-type=e2-standard-4 \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-ip-alias \
    --enable-master-authorized-networks \
    --master-authorized-networks=${CLOUDSHELL_IP}/32
```

#### 2.2 创建私有应用集群

```bash
# 创建第一个私有集群
gcloud container clusters create gke-app-cluster-1 \
    --region=${REGION} \
    --num-nodes=2 \
    --machine-type=e2-standard-4 \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-ip-alias \
    --enable-private-nodes \
    --enable-private-endpoint \
    --master-ipv4-cidr=172.16.0.0/28 \
    --enable-master-authorized-networks \
    --master-authorized-networks=${CLOUDSHELL_IP}/32 \
    --no-enable-basic-auth \
    --no-issue-client-certificate

# 创建第二个私有集群
gcloud container clusters create gke-app-cluster-2 \
    --region=${REGION} \
    --num-nodes=2 \
    --machine-type=e2-standard-4 \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --enable-ip-alias \
    --enable-private-nodes \
    --enable-private-endpoint \
    --master-ipv4-cidr=172.16.1.0/28 \
    --enable-master-authorized-networks \
    --master-authorized-networks=${CLOUDSHELL_IP}/32 \
    --no-enable-basic-auth \
    --no-issue-client-certificate
```

### 步骤 3：配置网络

#### 3.1 创建 Cloud Router 和 NAT Gateway

```bash
# 获取 VPC 网络名称
export VPC_NETWORK=default

# 为集群 1 创建 Cloud Router
gcloud compute routers create router-cluster-1 \
    --region=${REGION} \
    --network=${VPC_NETWORK}

# 为集群 1 创建 NAT Gateway
gcloud compute routers nats create nat-cluster-1 \
    --router=router-cluster-1 \
    --region=${REGION} \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips

# 为集群 2 创建 Cloud Router
gcloud compute routers create router-cluster-2 \
    --region=${REGION} \
    --network=${VPC_NETWORK}

# 为集群 2 创建 NAT Gateway
gcloud compute routers nats create nat-cluster-2 \
    --router=router-cluster-2 \
    --region=${REGION} \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

#### 3.2 配置防火墙规则

```bash
# 允许集群间通信
gcloud compute firewall-rules create allow-inter-cluster \
    --network=${VPC_NETWORK} \
    --allow=tcp,udp,icmp \
    --source-ranges=10.0.0.0/8 \
    --target-tags=gke

# 允许健康检查
gcloud compute firewall-rules create allow-health-checks \
    --network=${VPC_NETWORK} \
    --allow=tcp:80,tcp:443,tcp:15021,tcp:15017 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=gke
```

### 步骤 4：注册集群到 Fleet

```bash
# 注册 gke-ingress 集群
gcloud container fleet memberships register gke-ingress \
    --gke-cluster=${REGION}/gke-ingress \
    --enable-workload-identity

# 注册 gke-app-cluster-1
gcloud container fleet memberships register gke-app-cluster-1 \
    --gke-cluster=${REGION}/gke-app-cluster-1 \
    --enable-workload-identity

# 注册 gke-app-cluster-2
gcloud container fleet memberships register gke-app-cluster-2 \
    --gke-cluster=${REGION}/gke-app-cluster-2 \
    --enable-workload-identity
```

### 步骤 5：启用 Cloud Service Mesh

```bash
# 启用 Mesh 功能
gcloud container fleet mesh enable

# 为集群启用自动 Mesh 管理
gcloud container fleet mesh update \
    --management automatic \
    --memberships gke-app-cluster-1,gke-app-cluster-2

# 验证 Mesh 状态
gcloud container fleet mesh describe
```

### 步骤 6：配置多集群服务

#### 6.1 获取集群凭据

```bash
# 获取 gke-ingress 凭据
gcloud container clusters get-credentials gke-ingress --region=${REGION}

# 获取 gke-app-cluster-1 凭据
gcloud container clusters get-credentials gke-app-cluster-1 --region=${REGION}

# 获取 gke-app-cluster-2 凭据
gcloud container clusters get-credentials gke-app-cluster-2 --region=${REGION}
```

#### 6.2 安装 Multi Cluster Ingress

```bash
# 启用 Multi Cluster Ingress
gcloud container fleet ingress enable \
    --config-membership=gke-ingress \
    --memberships=gke-app-cluster-1,gke-app-cluster-2
```

### 步骤 7：部署 Cymbal Bank 应用

#### 7.1 创建命名空间

```bash
# 在两个应用集群上创建命名空间
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-1 \
    create namespace cymbal-bank

kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-2 \
    create namespace cymbal-bank
```

#### 7.2 启用 Sidecar 注入

```bash
# 为命名空间添加标签以启用自动注入
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-1 \
    label namespace cymbal-bank istio-injection=enabled

kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-2 \
    label namespace cymbal-bank istio-injection=enabled
```

#### 7.3 部署应用组件

```yaml
# cymbal-bank-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: cymbal-bank
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        version: v1
    spec:
      containers:
      - name: frontend
        image: gcr.io/google-samples/cymbal-bank/frontend:v1
        ports:
        - containerPort: 8080
        env:
        - name: BALANCE_SERVICE
          value: "balance:8080"
        - name: LEDGER_SERVICE
          value: "ledger:8080"
        - name: ACCOUNT_SERVICE
          value: "account:8080"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: cymbal-bank
spec:
  selector:
    app: frontend
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: balance
  namespace: cymbal-bank
spec:
  replicas: 2
  selector:
    matchLabels:
      app: balance
  template:
    metadata:
      labels:
        app: balance
        version: v1
    spec:
      containers:
      - name: balance
        image: gcr.io/google-samples/cymbal-bank/balance:v1
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: balance
  namespace: cymbal-bank
spec:
  selector:
    app: balance
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
  namespace: cymbal-bank
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ledger
  template:
    metadata:
      labels:
        app: ledger
        version: v1
    spec:
      containers:
      - name: ledger
        image: gcr.io/google-samples/cymbal-bank/ledger:v1
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: ledger
  namespace: cymbal-bank
spec:
  selector:
    app: ledger
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: account
  namespace: cymbal-bank
spec:
  replicas: 2
  selector:
    matchLabels:
      app: account
  template:
    metadata:
      labels:
        app: account
        version: v1
    spec:
      containers:
      - name: account
        image: gcr.io/google-samples/cymbal-bank/account:v1
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: account
  namespace: cymbal-bank
spec:
  selector:
    app: account
  ports:
  - port: 8080
    targetPort: 8080
```

```bash
# 在两个集群上部署应用
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-1 \
    apply -f cymbal-bank-deployment.yaml

kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-2 \
    apply -f cymbal-bank-deployment.yaml
```

### 步骤 8：配置 Multi Cluster Ingress

```yaml
# multi-cluster-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cymbal-bank-ingress
  namespace: cymbal-bank
  annotations:
    kubernetes.io/ingress.class: gce-multi-cluster
spec:
  rules:
  - http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: frontend
            port:
              number: 8080
```

```bash
# 在 gke-ingress 集群上创建 Ingress
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-ingress \
    apply -f multi-cluster-ingress.yaml
```

---

## Cloud Service Mesh 核心概念

### 多主模式（Multi-Primary Mode）

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Cloud Service Mesh 多主模式                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  传统单主模式：                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                                                                  │   │
│  │    ┌─────────────┐                                              │   │
│  │    │   Primary   │  ◄── 单点故障                                │   │
│  │    │  Control    │                                              │   │
│  │    │   Plane     │                                              │   │
│  │    └──────┬──────┘                                              │   │
│  │           │                                                      │   │
│  │     ┌─────┴─────┐                                               │   │
│  │     ▼           ▼                                               │   │
│  │  ┌─────┐    ┌─────┐                                            │   │
│  │  │Pod  │    │Pod  │                                            │   │
│  │  └─────┘    └─────┘                                            │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  多主模式：                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                                                                  │   │
│  │  ┌─────────────┐         ┌─────────────┐                        │   │
│  │  │   Primary   │ ◄─────► │   Primary   │                        │   │
│  │  │  Control    │  同步   │  Control    │                        │   │
│  │  │   Plane     │         │   Plane     │                        │   │
│  │  └──────┬──────┘         └──────┬──────┘                        │   │
│  │         │                       │                                │   │
│  │    ┌────┴────┐             ┌────┴────┐                         │   │
│  │    ▼         ▼             ▼         ▼                         │   │
│  │  ┌────┐   ┌────┐        ┌────┐   ┌────┐                       │   │
│  │  │Pod │   │Pod │        │Pod │   │Pod │                       │   │
│  │  └────┘   └────┘        └────┘   └────┘                       │   │
│  │                                                                  │   │
│  │  Cluster 1                    Cluster 2                         │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  优势：                                                                  │
│  ├── 无单点故障                                                        │
│  ├── 跨集群负载均衡                                                    │
│  ├── 故障自动转移                                                      │
│  └── 本地服务发现优先                                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 分布式服务特性

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        分布式服务特性                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. 服务发现                                                            │
│     ├── 跨集群服务自动发现                                              │
│     ├── 统一服务注册表                                                  │
│     └── DNS 解析跨集群                                                  │
│                                                                          │
│  2. 负载均衡                                                            │
│     ├── 跨集群请求分发                                                  │
│     ├── 本地优先路由                                                    │
│     └── 健康检查驱动的负载均衡                                          │
│                                                                          │
│  3. 故障恢复                                                            │
│     ├── 自动故障检测                                                    │
│     ├── 流量重路由                                                      │
│     └── 熔断和重试                                                      │
│                                                                          │
│  4. 安全性                                                              │
│     ├── mTLS 自动加密                                                   │
│     ├── 服务间身份验证                                                  │
│     └── 细粒度访问控制                                                  │
│                                                                          │
│  5. 可观测性                                                            │
│     ├── 分布式追踪                                                      │
│     ├── 统一监控指标                                                    │
│     └── 集中式日志                                                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 私有集群网络配置

### 网络架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        私有集群网络架构                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│                         互联网                                           │
│                            │                                             │
│                            ▼                                             │
│                    ┌───────────────┐                                    │
│                    │  Cloud NAT    │                                    │
│                    │  Gateway      │                                    │
│                    └───────┬───────┘                                    │
│                            │                                             │
│                    ┌───────┴───────┐                                    │
│                    │ Cloud Router  │                                    │
│                    └───────┬───────┘                                    │
│                            │                                             │
│  ┌─────────────────────────┼─────────────────────────────────────────┐ │
│  │                    VPC Network                                     │ │
│  │                         │                                          │ │
│  │         ┌───────────────┼───────────────┐                         │ │
│  │         │               │               │                         │ │
│  │         ▼               ▼               ▼                         │ │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐                  │ │
│  │  │  Subnet 1  │  │  Subnet 2  │  │  Subnet 3  │                  │ │
│  │  │ (Pod CIDR) │  │ (Pod CIDR) │  │ (Pod CIDR) │                  │ │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘                  │ │
│  │        │               │               │                          │ │
│  │        ▼               ▼               ▼                          │ │
│  │  ┌──────────┐   ┌──────────┐   ┌──────────┐                      │ │
│  │  │ Private  │   │ Private  │   │  Public  │                      │ │
│  │  │ Cluster  │   │ Cluster  │   │ Cluster  │                      │ │
│  │  │    1     │   │    2     │   │ (Ingress)│                      │ │
│  │  └──────────┘   └──────────┘   └──────────┘                      │ │
│  │                                                                   │ │
│  │  私有集群特点：                                                   │ │
│  │  ├── 节点无公网 IP                                               │ │
│  │  ├── API Server 仅可通过私有端点访问                             │ │
│  │  ├── 通过 NAT Gateway 访问外部服务                               │ │
│  │  └── 授权网络控制访问来源                                        │ │
│  │                                                                   │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 授权网络配置

```bash
# 添加 Cloud Shell IP 到授权网络
gcloud container clusters update gke-app-cluster-1 \
    --region=${REGION} \
    --enable-master-authorized-networks \
    --master-authorized-networks=${CLOUDSHELL_IP}/32

# 添加其他网络（如企业网络）
gcloud container clusters update gke-app-cluster-1 \
    --region=${REGION} \
    --enable-master-authorized-networks \
    --master-authorized-networks=${CLOUDSHELL_IP}/32,10.0.0.0/8
```

---

## 验证和测试

### 验证集群状态

```bash
# 查看集群列表
gcloud container clusters list

# 查看 Fleet 成员
gcloud container fleet memberships list

# 查看 Mesh 状态
gcloud container fleet mesh describe
```

### 验证应用部署

```bash
# 查看 Pod 状态（集群 1）
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-1 \
    get pods -n cymbal-bank

# 查看 Pod 状态（集群 2）
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-2 \
    get pods -n cymbal-bank

# 查看 Service 状态
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-1 \
    get services -n cymbal-bank
```

### 验证多集群服务

```bash
# 查看 Multi Cluster Ingress 状态
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-ingress \
    get ingress -n cymbal-bank

# 获取 Ingress IP
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-ingress \
    get ingress cymbal-bank-ingress -n cymbal-bank -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 测试应用访问
curl http://INGRESS_IP/
```

### 验证服务网格

```bash
# 查看 Envoy Sidecar
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-1 \
    get pods -n cymbal-bank -o jsonpath='{.items[0].spec.containers[*].name}'

# 应该看到类似：frontend istio-proxy
```

---

## 清理资源

```bash
# 删除 Ingress
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-ingress \
    delete -f multi-cluster-ingress.yaml

# 删除应用
kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-1 \
    delete namespace cymbal-bank

kubectl --context=gke_${PROJECT_ID}_${REGION}_gke-app-cluster-2 \
    delete namespace cymbal-bank

# 禁用 Mesh
gcloud container fleet mesh disable

# 取消注册集群
gcloud container fleet memberships unregister gke-ingress
gcloud container fleet memberships unregister gke-app-cluster-1
gcloud container fleet memberships unregister gke-app-cluster-2

# 删除集群
gcloud container clusters delete gke-ingress --region=${REGION} --quiet
gcloud container clusters delete gke-app-cluster-1 --region=${REGION} --quiet
gcloud container clusters delete gke-app-cluster-2 --region=${REGION} --quiet

# 删除 NAT 和 Router
gcloud compute routers nats delete nat-cluster-1 --router=router-cluster-1 --region=${REGION}
gcloud compute routers nats delete nat-cluster-2 --router=router-cluster-2 --region=${REGION}
gcloud compute routers delete router-cluster-1 --region=${REGION}
gcloud compute routers delete router-cluster-2 --region=${REGION}

# 删除防火墙规则
gcloud compute firewall-rules delete allow-inter-cluster
gcloud compute firewall-rules delete allow-health-checks
```

---

## 最佳实践

### 安全最佳实践

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        安全最佳实践                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. 私有集群配置                                                        │
│     ├── 启用私有节点                                                    │
│     ├── 启用私有端点                                                    │
│     ├── 配置授权网络                                                    │
│     └── 禁用基本认证                                                    │
│                                                                          │
│  2. 网络安全                                                            │
│     ├── 使用 VPC 防火墙规则                                             │
│     ├── 限制入站/出站流量                                               │
│     ├── 配置 NAT Gateway                                                │
│     └── 使用 Cloud Armor 保护 Ingress                                   │
│                                                                          │
│  3. 服务网格安全                                                        │
│     ├── 启用 mTLS                                                       │
│     ├── 配置授权策略                                                    │
│     ├── 使用服务账号                                                    │
│     └── 定期轮换证书                                                    │
│                                                                          │
│  4. 访问控制                                                            │
│     ├── 使用 Workload Identity                                          │
│     ├── 最小权限原则                                                    │
│     ├── 审计日志                                                        │
│     └── 定期权限审查                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 高可用最佳实践

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        高可用最佳实践                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. 多集群部署                                                          │
│     ├── 至少 2 个应用集群                                               │
│     ├── 跨区域部署（生产环境）                                          │
│     ├── 多主模式配置                                                    │
│     └── 自动故障转移                                                    │
│                                                                          │
│  2. 负载均衡                                                            │
│     ├── 使用 Multi Cluster Ingress                                      │
│     ├── 配置健康检查                                                    │
│     ├── 会话亲和性（如需要）                                            │
│     └── 流量管理策略                                                    │
│                                                                          │
│  3. 数据层                                                              │
│     ├── 使用托管数据库服务                                              │
│     ├── 配置数据库复制                                                  │
│     ├── 定期备份                                                        │
│     └── 灾难恢复计划                                                    │
│                                                                          │
│  4. 监控告警                                                            │
│     ├── 配置 Cloud Monitoring                                           │
│     ├── 设置关键指标告警                                                │
│     ├── 分布式追踪                                                      │
│     └── 日志聚合                                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 参考链接

- [Cloud Service Mesh 文档](https://cloud.google.com/service-mesh/docs)
- [GKE 私有集群](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)
- [Multi Cluster Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-ingress)
- [Istio 官方文档](https://istio.io/latest/docs/)
- [GKE Fleet 管理](https://cloud.google.com/anthos/fleet-management/docs)
