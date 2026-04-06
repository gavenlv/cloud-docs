# Kubernetes Dashboard 部署与使用指南

## 概述

Kubernetes Dashboard 是 Kubernetes 集群的官方 Web UI，可以可视化方式管理集群资源、部署应用、故障排查等。

---

## 1. Dashboard 介绍

### 1.1 什么是 Kubernetes Dashboard

Kubernetes Dashboard 是一个基于 Web 的通用、可扩展的 Kubernetes 用户界面。它允许用户管理运行在 Kubernetes 集群中的应用程序，并对集群本身进行故障排除。

**核心价值：**
- **可视化操作**：无需记忆复杂的 kubectl 命令，通过图形界面完成日常运维
- **实时监控**：直观查看集群状态、资源使用情况和应用健康度
- **快速入门**：降低 Kubernetes 学习曲线，帮助新手理解集群架构
- **高效排障**：集中展示日志、事件和资源状态，加速问题定位

### 1.2 主要功能

| 功能模块 | 说明 |
|---------|------|
| **集群概览** | 查看 CPU/内存使用率、节点状态、Pod 分布 |
| **工作负载管理** | 创建/编辑 Deployment、StatefulSet、DaemonSet 等 |
| **服务发现** | 管理 Service、Ingress、Endpoint |
| **配置管理** | 编辑 ConfigMap、Secret、资源配额 |
| **存储管理** | 创建 PVC、查看 PV、StorageClass |
| **权限控制** | RBAC 角色绑定、ServiceAccount 管理 |
| **日志查看** | 实时流式日志、历史日志检索 |
| **资源编辑** | 在线 YAML 编辑器，支持语法高亮 |

### 1.3 架构组件

```
┌─────────────────────────────────────────────────────┐
│                    浏览器 (HTTPS)                     │
│                   https://localhost:30443            │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│              kubernetes-dashboard Service             │
│                    (NodePort:30443)                  │
└───────────────────────┬─────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌───────────┐   ┌─────────────┐   ┌─────────────────┐
│ Dashboard │   │ Metrics     │   │ Kube-apiserver  │
│ Web UI    │◄──│ Scraper     │   │ (认证 & 授权)    │
│ :8443     │   │ :8001       │   │                 │
└───────────┘   └─────────────┘   └─────────────────┘
```

**核心组件：**

| 组件 | 说明 |
|------|------|
| **Dashboard** | 主 Web 应用，提供用户界面和 API 代理 |
| **Metrics Scraper** | 收集集群指标数据（CPU、内存），用于图表展示 |
| **Kube-apiserver** | 集群 API 服务端，处理所有请求的认证和授权 |

### 1.4 适用场景

| 场景 | 说明 |
|------|------|
| **开发环境** | 快速部署测试应用，查看 Pod 日志和状态 |
| **学习培训**： | 可视化理解 Kubernetes 资源关系 |
| **生产监控** | 实时查看集群健康度和资源利用率 |
| **故障排查** | 集中查看事件、日志和资源描述 |
| **CI/CD 辅助** | 手动验证部署结果，检查资源配置 |

### 1.5 版本信息

| 项目 | 信息 |
|------|------|
| 当前版本 | v2.7.0 |
| 支持的 K8s 版本 | v1.25 - v1.29+ |
| 仓库地址 | [github.com/kubernetes/dashboard](https://github.com/kubernetes/dashboard) |
| 许可证 | Apache 2.0 |

### 1.6 与其他工具对比

| 工具 | 类型 | 特点 |
|------|------|------|
| **Kubernetes Dashboard** | 官方 Web UI | 功能全面，适合通用场景 |
| **Lens IDE** | 桌面客户端 | 离线可用，多集群管理 |
| **Rancher** | 平台级 UI | 多集群管理，内置 CI/CD |
| **Octant (已归档)** | 开发者工具 | 轻量级，插件化 |

> **推荐**：对于本地开发和学习，Kubernetes Dashboard 是最佳选择；企业生产环境可考虑 Rancher 或商业方案。

---

## 2. Kubernetes RBAC 权限体系

### 2.1 核心概念总览

Kubernetes 使用 **RBAC（Role-Based Access Control）** 进行权限控制。理解这些概念是安全使用 Dashboard 和 Operator 的基础。

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes RBAC 架构                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────┐     ┌───────────┐     ┌──────────────┐   │
│   │ Service     │     │ Role /    │     │ RoleBinding / │   │
│   │ Account     │────▶│ Cluster   │────▶│ ClusterRole  │   │
│   │ (身份)      │     │ Role      │     │ Binding       │   │
│   │             │     │ (权限定义) │     │ (绑定关系)    │   │
│   └─────────────┘     └───────────┘     └──────────────┘   │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│   ┌───────────────────────────────────────────────────┐    │
│   │              Kube-apiserver                       │    │
│   │         (验证身份 + 检查权限)                       │    │
│   └───────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 ServiceAccount（服务账号）

**ServiceAccount** 是 Pod 在集群中的身份标识，类似于"机器用户"。

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa          # 账号名称
  namespace: default       # 命名空间范围
```

| 属性 | 说明 |
|------|------|
| **作用范围** | 仅在创建的命名空间内有效 |
| **用途** | 为 Pod 提供访问 API Server 的身份 |
| **Token** | 自动挂载到 `/var/run/secrets/kubernetes.io/serviceaccount/` |
| **最佳实践** | 每个 Operator/应用使用独立的 SA |

**为什么需要 ServiceAccount：**
- Pod 需要身份才能调用 Kubernetes API（如创建/删除资源）
- 不同应用需要不同的权限隔离
- 审计日志可以追踪到具体哪个应用执行了操作

### 2.3 Role 与 ClusterRole（角色定义）

#### Role - 命名空间级别权限

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default        # 只在 default 命名空间生效
rules:
- apiGroups: [""]           # "" 表示核心 API Group
  resources: ["pods"]       # 可操作的资源类型
  verbs: ["get", "list", "watch"]  # 允许的操作
```

#### ClusterRole - 集群级别权限

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin       # 集群范围，无 namespace
rules:
- apiGroups: ["*"]          # 所有 API Group
  resources: ["*"]          # 所有资源
  verbs: ["*"]              # 所有操作
```

| 对比项 | Role | ClusterRole |
|--------|------|-------------|
| **作用域** | 单个命名空间 | 整个集群 |
| **适用场景** | 应用级权限、namespace 内资源 | 集群级资源（Node、PV、Namespace） |
| **可管理资源** | Pod、Service、ConfigMap 等 | Node、ClusterRole、CRD 等 |

**常用 verbs（操作动词）：**

| Verb | 说明 | 示例 |
|------|------|------|
| `get` | 获取单个资源 | `kubectl get pod/my-pod` |
| `list` | 列出资源集合 | `kubectl get pods` |
| `watch` | 监听资源变化 | 监控 Pod 状态变更 |
| `create` | 创建资源 | `kubectl apply -f app.yaml` |
| `update` | 更新资源 | 更新 Deployment 配置 |
| `patch` | 部分更新 | 修改副本数 |
| `delete` | 删除资源 | `kubectl delete pod/my-pod` |

### 2.4 RoleBinding 与 ClusterRoleBinding（角色绑定）

#### RoleBinding - 绑定 Role 到主体

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:                        # 授权给谁
- kind: ServiceAccount
  name: my-app-sa
  namespace: default
roleRef:                         # 绑定哪个角色
  kind: Role
  name: pod-reader
```

#### ClusterRoleBinding - 绑定 ClusterRole 到主体

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user-binding
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
roleRef:
  kind: ClusterRole
  name: cluster-admin            # 绑定内置的 cluster-admin 角色
```

**RBAC 权限检查流程：**

```
请求进入 → 识别身份(ServiceAccount) → 查找Binding → 匹配Role → 检查verbs → 允许/拒绝
```

### 2.5 常用内置 ClusterRole

| ClusterRole | 权限范围 | 适用场景 |
|-------------|----------|----------|
| **cluster-admin** | 超级管理员 | Dashboard 管理员、运维工具 |
| **admin** | 命名空间管理员 | 开发者管理自己的 namespace |
| **edit** | 读写权限（不含RBAC） | 应用开发者 |
| **view** | 只读权限 | 监控、审计人员 |

### 2.6 RBAC 最佳实践

| 原则 | 说明 |
|------|------|
| **最小权限原则** | 只授予必要的最小权限集 |
| **命名空间隔离** | 使用 Role 限制在特定 namespace |
| **定期审计** | 定期检查不必要的权限 |
| **避免使用 cluster-admin** | 生产环境禁止普通应用使用 |
|- **ServiceAccount 隔离** | 每个 Operator 使用独立 SA |

---

## 3. Operator 权限详解

### 3.1 什么是 Kubernetes Operator

**Operator** 是一种使用自定义资源（CRD）和控制器模式来管理应用的 Kubernetes 扩展。它将运维知识编码为软件，实现应用的自动化管理。

```
┌─────────────────────────────────────────────────────────────┐
│                    Operator 工作原理                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   用户创建 CR ──▶ Controller 检测变化 ──▶ Reconcile 逻辑     │
│        │                │                   │              │
│        │                ▼                   ▼              │
│        │         ┌───────────┐    ┌─────────────────┐      │
│        │         │ Watch CRD │    │ 调用 K8s API     │      │
│        │         │ 变化事件   │    │ 创建/更新/删除   │      │
│        │         └───────────┘    │ Pod、Service等   │      │
│        │                          └─────────────────┘      │
│        ▼                                                   │
│   CustomResource (CR)                                       │
│   - MySQLCluster                                           │
│   - RedisCluster                                           │
│   - Prometheus                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Operator 为什么需要特殊权限

Operator 与普通应用不同，它需要代表用户管理其他 Kubernetes 资源：

| 能力 | 说明 |
|------|------|
| **资源创建** | 根据用户定义的 CR 创建 Pod、Service、PVC 等 |
| **状态监控** | Watch 自己管理的资源状态变化 |
| **自动修复** | 检测到异常时自动重建或迁移资源 |
| **配置更新** | 更新 ConfigMap、Secret 等配置 |
| **CRD 管理** | 注册和管理自定义资源定义 |

### 3.3 Operator 必需的核心权限

#### 基础 RBAC 配置模板

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-operator-controller-manager
  namespace: my-operator-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: my-operator-manager-role
rules:
  # 1. 管理 Operator 自身的 CRD 和 CR
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # 2. 管理自定义资源实例
  - apiGroups: ["my.operator.io"]          # 替换为你的 API Group
    resources: ["*"]                        # 所有自定义资源
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # 3. 管理核心工作负载资源
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets",
                "persistentvolumeclaims", "events"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # 4. 管理应用编排资源
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "daemonsets",
                "replicasets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # 5. 管理网络资源
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses", "networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

  # 6. 读写状态（用于 Leader Election）
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-operator-manager-rolebinding
roleRef:
  kind: ClusterRole
  name: my-operator-manager-role
subjects:
- kind: ServiceAccount
  name: my-operator-controller-manager
  namespace: my-operator-system
```

### 3.4 权限详细解析

#### 1️⃣ CRD 管理权限（必须）

```yaml
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**为什么需要：**
- Operator 启动时需要检查 CRD 是否已注册
- 安装/升级时需要创建或更新 CRD 定义
- 清理时可能需要删除 CRD

#### 2️⃣ 自定义资源权限（必须）

```yaml
- apiGroups: ["my.operator.io"]  # 你的 API Group
  resources: ["*"]               # 所有 CR 类型
  verbs: ["*"]                   # 全部操作
```

**为什么需要：**
- **Watch**: 监听用户新建/修改/删除 CR 的事件
- **Get/List**: 读取 CR 规格以决定如何部署
- **Update/Patch**: 更新 CR 的 status 字段（如副本数、版本）

#### 3️⃣ Pod 管理权限（核心）

```yaml
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**为什么需要：**
- **Create**: 根据 CR 创建工作 Pod
- **Get/Watch**: 监控 Pod 运行状态、健康检查
- **Delete**: 故障 Pod 需要被删除并重建
- **Update**: 更新 Pod 标签或注解（如版本标记）

#### 4️⃣ Service 管理权限（核心）

```yaml
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**为什么需要：**
- 为有状态应用创建 Headless Service（StatefulSet 需要）
- 为无状态应用创建 ClusterIP Service
- 更新 Service Selector 以匹配新的 Pod

#### 5️⃣ Deployment/StatefulSet 权限（核心）

```yaml
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**为什么需要：**
- **Deployment**: 无状态应用的标准部署方式
- **StatefulSet**: 有状态应用（数据库）需要有序部署、稳定标识
- **Update**: 滚动更新、扩缩容操作

#### 6️⃣ ConfigMap & Secret 权限（重要）

```yaml
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**为什么需要：**
- **ConfigMap**: 存储应用配置文件、初始化脚本
- **Secret**: 存储数据库密码、TLS 证书、API 密钥
- Operator 通常需要动态生成和轮换这些敏感信息

#### 7️⃣ PVC 权限（存储相关 Operator 必须）

```yaml
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**为什么需要：**
- 数据库 Operator 需要为每个实例创建持久化存储卷
- StatefulSet 自动关联 PVC 进行数据持久化
- 扩缩容时需要动态调整存储资源

#### 8️⃣ Event 记录权限（推荐）

```yaml
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch", "create", "patch"]
```

**为什么需要：**
- 记录 Operator 操作日志（如"已创建Pod"、"检测到故障"）
- 用户通过 `kubectl describe` 或 Dashboard 查看事件了解状态
- 便于故障排查和审计追踪

#### 9️⃣ Lease 权限（高可用必须）

```yaml
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**为什么需要：**
- **Leader Election**: 多副本 Operator 只有一个 Leader 处理 reconcile
- 防止多个实例同时操作同一资源导致冲突
- 使用 `client-go` 的 leaderelection 包实现

### 3.5 不同类型 Operator 的权限差异

| Operator 类型 | 特殊需要的权限 | 原因 |
|--------------|----------------|------|
| **数据库 Operator** | PVC, PV, StorageClass | 需要管理持久化数据和备份 |
| **监控 Operator** | PrometheusRule, ServiceMonitor, Alertmanager | 需要创建监控规则和告警 |
| **网络 Operator** | NetworkPolicy, Ingress, Service | 需要配置网络策略和服务发现 |
| **安全 Operator** | Secret, CertificateSigningRequest | 需要管理证书和凭证 |
| **CI/CD Operator** | PipelineRun, TaskRun, CronJob | 需要触发和管理流水线 |

### 3.6 实际案例：MySQL Operator 权限分析

```yaml
# mysql-operator-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: mysql-operator
rules:
  # CRD 管理
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["*"]

  # MySQL 自定义资源
  - apiGroups: ["mysql.oracle.com"]
    resources: ["mysqlclusters", "mysqlbackups", "mysqlrestores"]
    verbs: ["*"]

  # 核心工作负载
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets",
                "persistentvolumeclaims", "events"]
    verbs: ["*"]

  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "replicasets"]
    verbs: ["*"]

  # 存储相关（数据库特别需要）
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch"]

  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]

  # 备份相关（S3/OSS 对象存储访问）
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["*"]

  # Leader Election
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["*"]
```

**权限解析：**

| 权限组 | 用途 | 为什么 MySQL Operator 需要 |
|--------|------|--------------------------|
| `persistentvolumes` | 查看 PV 绑定情况 | 确保 PVC 正确绑定到合适的存储类 |
| `storageclasses` | 查看可用存储类 | 为新集群选择正确的存储配置 |
| `jobs/cronjobs` | 执行备份任务 | 定期执行逻辑备份和数据恢复 |
| `mysqlclusters` | 管理 MySQL 集群 CR | 用户定义的集群规格（副本数、版本等） |
| `mysqlbackups` | 管理备份任务 CR | 触发即时备份或定时备份 |
| `mysqlrestores` | 管理恢复任务 CR | 从备份恢复到指定时间点 |

### 3.7 安全建议与常见错误

#### ❌ 常见错误

| 错误做法 | 风险 | 正确做法 |
|----------|------|----------|
| 直接使用 `cluster-admin` | 权限过大，可删除任何资源 | 创建专用 ClusterRole，只包含必要权限 |
| verbs 使用 `["*"]` | 可能意外修改不应触碰的资源 | 明确列出需要的动词 |
| 不限制 apiGroups | 未来新增 API 组也会被授权 | 明确指定所需的 API Group |
| 多个 Operator 共用一个 SA | 无法区分哪个 Operator 执行了操作 | 每个 Operator 使用独立的 ServiceAccount |

#### ✅ 最佳实践

```yaml
# 推荐：细粒度权限定义
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secure-operator-role
rules:
  # ✅ 明确指定 API Group
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    # ✅ 分离读写权限
    verbs: ["get", "list", "watch", "create", "update"]

  # ✅ secrets 只允许特定操作
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["my-app-tls", "my-app-db-password"]  # 限定名称
    verbs: ["get", "update"]

  # ❌ 避免：通配符
  # - apiGroups: ["*"]
  #   resources: ["*"]
  #   verbs: ["*"]
```

---

## 4. 环境要求

- Docker Desktop 已启用 Kubernetes 或 kubeconfig 已配置
- kubectl 已安装并可访问集群
- 网络可访问 GitHub 下载清单文件

---

## 5. 一键部署

### 5.1 PowerShell（Windows）

```powershell
# 下载并执行部署脚本
.\deploy-dashboard.ps1
```

### 5.2 Bash（Linux/Mac）

```bash
# 添加执行权限并运行
chmod +x deploy-dashboard.sh
./deploy-dashboard.sh
```

### 5.3 手动部署

如果脚本执行有问题，可以手动执行以下步骤：

```bash
# 1. 部署 Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 2. 创建管理员账号
kubectl apply -f dashboard-adminuser.yaml

# 3. 配置 NodePort 外部访问
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8443,"nodePort":30443}]}}'

# 4. 获取长期令牌
kubectl create token admin-user -n kubernetes-dashboard --duration=87600h
```

---

## 6. 永久外部访问配置

### 6.1 NodePort 方式（推荐用于开发）

NodePort 已在一键部署中自动配置，访问地址：

```
https://localhost:30443
或
https://<节点IP>:30443
```

### 6.2 Ingress 方式（推荐用于生产）

创建 Ingress 实现 HTTPS 访问：

```bash
# 应用 Ingress 配置
kubectl apply -f dashboard-ingress.yaml

# 修改域名和证书配置
# 编辑 dashboard-ingress.yaml 中的 dashboard.example.com 和证书配置
```

### 6.3 LoadBalancer 方式（云环境）

```bash
# 修改 Service 为 LoadBalancer
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}'

# 查看分配的外部IP
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -w
```

---

## 7. 长期认证配置

### 7.1 获取长期有效令牌（1年）

```bash
# 创建1年有效期的令牌
kubectl create token admin-user -n kubernetes-dashboard --duration=87600h
```

### 7.2 Kubeconfig 文件登录（推荐）

1. 创建 kubeconfig 文件 `dashboard-kubeconfig.yaml`
2. 获取长期令牌并替换文件中的 `<TOKEN>`
3. 在 Dashboard 登录页面选择 "Kubeconfig" 上传文件

```bash
# 获取令牌
TOKEN=$(kubectl create token admin-user -n kubernetes-dashboard --duration=87600h)

# 替换令牌到 kubeconfig 文件
sed -i "s/<TOKEN>/$TOKEN/g" dashboard-kubeconfig.yaml
```

### 7.3 Secret Token 方式

```bash
# 创建 Secret
kubectl apply -f dashboard-token-secret.yaml

# 获取令牌
kubectl get secret dashboard-admin-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

---

## 8. 访问 Dashboard

### 8.1 登录方式

**方式1: Token 登录**
1. 浏览器打开 `https://localhost:30443`
2. 选择 "Token" 选项
3. 粘贴令牌
4. 点击 "Sign in"

**方式2: Kubeconfig 登录**
1. 浏览器打开 `https://localhost:30443`
2. 选择 "Kubeconfig" 选项
3. 上传 `dashboard-kubeconfig.yaml` 文件
4. 点击 "Sign in"

---

## 9. 快速命令参考

| 操作 | 命令 |
|------|------|
| PowerShell一键部署 | `.\deploy-dashboard.ps1` |
| Bash一键部署 | `./deploy-dashboard.sh` |
| 手动部署 | `kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml` |
| 创建管理员账号 | `kubectl apply -f dashboard-adminuser.yaml` |
| 获取长期令牌 | `kubectl create token admin-user -n kubernetes-dashboard --duration=87600h` |
| 查看Pod状态 | `kubectl get pods -n kubernetes-dashboard` |
| 查看服务端口 | `kubectl get svc kubernetes-dashboard -n kubernetes-dashboard` |
| 删除Dashboard | `kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml` |

---

## 10. Dashboard 功能概览

### 10.1 资源管理

- **Workloads**：Deployment、Pod、ReplicaSet、DaemonSet、StatefulSet、CronJob、Job
- **Service**：ClusterIP、NodePort、LoadBalancer、Ingress
- **Config 和 Storage**：ConfigMap、Secret、PersistentVolume、StorageClass
- **RBAC**：ServiceAccount、Role、ClusterRole、RoleBinding、ClusterRoleBinding

### 10.2 主要功能

| 功能 | 说明 |
|------|------|
| 资源浏览 | 可视化查看所有 Kubernetes 资源 |
| 应用部署 | 通过 UI 部署新的应用 |
| 日志查看 | 实时查看 Pod 和容器日志 |
| 故障排查 | 查看资源状态、事件、描述信息 |
| 资源编辑 | 直接通过 UI 编辑 YAML 配置 |
| 扩缩容 | 调整 Deployment 副本数 |
| 端口转发 | 为本地端口转发到 Pod |

---

## 11. 安全注意事项

### 11.1 令牌安全

- 短期令牌（约15分钟）：适合临时测试
- 长期令牌（1年）：适合日常使用，请妥善保管
- 定期轮换：建议每3个月更新一次令牌

### 11.2 网络访问控制

> **警告**：NodePort 方式暴露的端口（30443）在生产环境应配合防火墙规则限制访问来源。

```powershell
# 示例: 使用 Windows 防火墙限制访问
New-NetFirewallRule -DisplayName "K8s Dashboard" -Direction Inbound -Protocol TCP -LocalPort 30443 -RemoteAddress 192.168.1.0/24 -Action Allow
```

### 11.3 生产环境建议

> **重要**：以下配置仅适用于本地开发环境。生产环境请：
> - 使用 Ingress + HTTPS + 认证代理
> - 配置 NetworkPolicy 限制访问
> - 启用 RBAC 细粒度授权
> - 使用企业 IdP 进行 SSO 认证

---

## 12. 故障排查

### 12.1 Pod 无法启动

```bash
# 查看详细状态
kubectl describe pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard

# 查看日志
kubectl logs -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard

# 如果是镜像拉取失败，可以手动拉取镜像
docker pull kubernetesui/dashboard:v2.7.0
docker pull kubernetesui/metrics-scraper:v1.0.8
```

### 12.2 无法访问 Dashboard

1. 确认 Service 类型正确：
   ```bash
   kubectl get svc kubernetes-dashboard -n kubernetes-dashboard
   ```

2. 确认 Pod 状态为 Running：
   ```bash
   kubectl get pods -n kubernetes-dashboard
   ```

3. 测试端口连通性：
   ```bash
   # Windows
   Test-NetConnection -ComputerName localhost -Port 30443

   # Linux/Mac
   curl -k https://localhost:30443
   ```

### 12.3 令牌无效

1. 确认令牌未过期
2. 确认复制的令牌完整（无省略号）
3. 确认使用正确的 namespace

```bash
# 重新获取令牌
kubectl get secret -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `deploy-dashboard.ps1` | PowerShell 一键部署脚本 |
| `deploy-dashboard.sh` | Bash 一键部署脚本 |
| `dashboard-adminuser.yaml` | 管理员账号配置 |
| `dashboard-ingress.yaml` | Ingress HTTPS 配置 |
| `dashboard-kubeconfig.yaml` | Kubeconfig 登录配置 |
| `dashboard-token-secret.yaml` | 永久 Secret Token |

---

## 参考链接

- [Kubernetes Dashboard 官方文档](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- [Dashboard GitHub 仓库](https://github.com/kubernetes/dashboard)
- [RBAC 授权文档](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
