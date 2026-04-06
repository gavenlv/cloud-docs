# Kubernetes Dashboard 部署与使用指南

## 概述

Kubernetes Dashboard 是 Kubernetes 集群的官方 Web UI，可以可视化方式管理集群资源、部署应用、故障排查等。

---

## 1. 环境要求

- Docker Desktop 已启用 Kubernetes 或 kubeconfig 已配置
- kubectl 已安装并可访问集群
- 网络可访问 GitHub 下载清单文件

---

## 2. 一键部署

### 2.1 PowerShell（Windows）

```powershell
# 下载并执行部署脚本
.\deploy-dashboard.ps1
```

### 2.2 Bash（Linux/Mac）

```bash
# 添加执行权限并运行
chmod +x deploy-dashboard.sh
./deploy-dashboard.sh
```

### 2.3 手动部署

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

## 3. 永久外部访问配置

### 3.1 NodePort 方式（推荐用于开发）

NodePort 已在一键部署中自动配置，访问地址：

```
https://localhost:30443
或
https://<节点IP>:30443
```

### 3.2 Ingress 方式（推荐用于生产）

创建 Ingress 实现 HTTPS 访问：

```bash
# 应用 Ingress 配置
kubectl apply -f dashboard-ingress.yaml

# 修改域名和证书配置
# 编辑 dashboard-ingress.yaml 中的 dashboard.example.com 和证书配置
```

### 3.3 LoadBalancer 方式（云环境）

```bash
# 修改 Service 为 LoadBalancer
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}'

# 查看分配的外部IP
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -w
```

---

## 4. 长期认证配置

### 4.1 获取长期有效令牌（1年）

```bash
# 创建1年有效期的令牌
kubectl create token admin-user -n kubernetes-dashboard --duration=87600h
```

### 4.2 Kubeconfig 文件登录（推荐）

1. 创建 kubeconfig 文件 `dashboard-kubeconfig.yaml`
2. 获取长期令牌并替换文件中的 `<TOKEN>`
3. 在 Dashboard 登录页面选择 "Kubeconfig" 上传文件

```bash
# 获取令牌
TOKEN=$(kubectl create token admin-user -n kubernetes-dashboard --duration=87600h)

# 替换令牌到 kubeconfig 文件
sed -i "s/<TOKEN>/$TOKEN/g" dashboard-kubeconfig.yaml
```

### 4.3 Secret Token 方式

```bash
# 创建 Secret
kubectl apply -f dashboard-token-secret.yaml

# 获取令牌
kubectl get secret dashboard-admin-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```

---

## 5. 访问 Dashboard

### 5.1 登录方式

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

## 6. 快速命令参考

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

## 7. Dashboard 功能概览

### 7.1 资源管理

- **Workloads**：Deployment、Pod、ReplicaSet、DaemonSet、StatefulSet、CronJob、Job
- **Service**：ClusterIP、NodePort、LoadBalancer、Ingress
- **Config 和 Storage**：ConfigMap、Secret、PersistentVolume、StorageClass
- **RBAC**：ServiceAccount、Role、ClusterRole、RoleBinding、ClusterRoleBinding

### 7.2 主要功能

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

## 8. 安全注意事项

### 8.1 令牌安全

- 短期令牌（约15分钟）：适合临时测试
- 长期令牌（1年）：适合日常使用，请妥善保管
- 定期轮换：建议每3个月更新一次令牌

### 8.2 网络访问控制

> **警告**：NodePort 方式暴露的端口（30443）在生产环境应配合防火墙规则限制访问来源。

```powershell
# 示例: 使用 Windows 防火墙限制访问
New-NetFirewallRule -DisplayName "K8s Dashboard" -Direction Inbound -Protocol TCP -LocalPort 30443 -RemoteAddress 192.168.1.0/24 -Action Allow
```

### 8.3 生产环境建议

> **重要**：以下配置仅适用于本地开发环境。生产环境请：
> - 使用 Ingress + HTTPS + 认证代理
> - 配置 NetworkPolicy 限制访问
> - 启用 RBAC 细粒度授权
> - 使用企业 IdP 进行 SSO 认证

---

## 9. 故障排查

### 9.1 Pod 无法启动

```bash
# 查看详细状态
kubectl describe pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard

# 查看日志
kubectl logs -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard

# 如果是镜像拉取失败，可以手动拉取镜像
docker pull kubernetesui/dashboard:v2.7.0
docker pull kubernetesui/metrics-scraper:v1.0.8
```

### 9.2 无法访问 Dashboard

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

### 9.3 令牌无效

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
