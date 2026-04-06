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

## 2. 环境要求

- Docker Desktop 已启用 Kubernetes 或 kubeconfig 已配置
- kubectl 已安装并可访问集群
- 网络可访问 GitHub 下载清单文件

---

## 3. 一键部署

### 3.1 PowerShell（Windows）

```powershell
# 下载并执行部署脚本
.\deploy-dashboard.ps1
```

### 3.2 Bash（Linux/Mac）

```bash
# 添加执行权限并运行
chmod +x deploy-dashboard.sh
./deploy-dashboard.sh
```

### 3.3 手动部署

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

## 4. 永久外部访问配置

### 4.1 NodePort 方式（推荐用于开发）

NodePort 已在一键部署中自动配置，访问地址：

```
https://localhost:30443
或
https://<节点IP>:30443
```

### 4.2 Ingress 方式（推荐用于生产）

创建 Ingress 实现 HTTPS 访问：

```bash
# 应用 Ingress 配置
kubectl apply -f dashboard-ingress.yaml

# 修改域名和证书配置
# 编辑 dashboard-ingress.yaml 中的 dashboard.example.com 和证书配置
```

### 4.3 LoadBalancer 方式（云环境）

```bash
# 修改 Service 为 LoadBalancer
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}'

# 查看分配的外部IP
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -w
```

---

## 5. 长期认证配置

### 5.1 获取长期有效令牌（1年）

```bash
# 创建1年有效期的令牌
kubectl create token admin-user -n kubernetes-dashboard --duration=87600h
```

### 5.2 Kubeconfig 文件登录（推荐）

1. 创建 kubeconfig 文件 `dashboard-kubeconfig.yaml`
2. 获取长期令牌并替换文件中的 `<TOKEN>`
3. 在 Dashboard 登录页面选择 "Kubeconfig" 上传文件

```bash
# 获取令牌
TOKEN=$(kubectl create token admin-user -n kubernetes-dashboard --duration=87600h)

# 替换令牌到 kubeconfig 文件
sed -i "s/<TOKEN>/$TOKEN/g" dashboard-kubeconfig.yaml
```

### 5.3 Secret Token 方式

```bash
# 创建 Secret
kubectl apply -f dashboard-token-secret.yaml

# 获取令牌
kubectl get secret dashboard-admin-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

---

## 6. 访问 Dashboard

### 6.1 登录方式

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

## 7. 快速命令参考

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

## 8. Dashboard 功能概览

### 8.1 资源管理

- **Workloads**：Deployment、Pod、ReplicaSet、DaemonSet、StatefulSet、CronJob、Job
- **Service**：ClusterIP、NodePort、LoadBalancer、Ingress
- **Config 和 Storage**：ConfigMap、Secret、PersistentVolume、StorageClass
- **RBAC**：ServiceAccount、Role、ClusterRole、RoleBinding、ClusterRoleBinding

### 8.2 主要功能

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

## 9. 安全注意事项

### 9.1 令牌安全

- 短期令牌（约15分钟）：适合临时测试
- 长期令牌（1年）：适合日常使用，请妥善保管
- 定期轮换：建议每3个月更新一次令牌

### 9.2 网络访问控制

> **警告**：NodePort 方式暴露的端口（30443）在生产环境应配合防火墙规则限制访问来源。

```powershell
# 示例: 使用 Windows 防火墙限制访问
New-NetFirewallRule -DisplayName "K8s Dashboard" -Direction Inbound -Protocol TCP -LocalPort 30443 -RemoteAddress 192.168.1.0/24 -Action Allow
```

### 9.3 生产环境建议

> **重要**：以下配置仅适用于本地开发环境。生产环境请：
> - 使用 Ingress + HTTPS + 认证代理
> - 配置 NetworkPolicy 限制访问
> - 启用 RBAC 细粒度授权
> - 使用企业 IdP 进行 SSO 认证

---

## 10. 故障排查

### 10.1 Pod 无法启动

```bash
# 查看详细状态
kubectl describe pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard

# 查看日志
kubectl logs -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard

# 如果是镜像拉取失败，可以手动拉取镜像
docker pull kubernetesui/dashboard:v2.7.0
docker pull kubernetesui/metrics-scraper:v1.0.8
```

### 10.2 无法访问 Dashboard

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

### 10.3 令牌无效

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
