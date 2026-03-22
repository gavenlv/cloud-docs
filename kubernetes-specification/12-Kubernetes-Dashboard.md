# Kubernetes Dashboard 部署与使用指南

## 概述

Kubernetes Dashboard 是 Kubernetes 集群的官方 Web UI，可以可视化方式管理集群资源、部署应用、故障排查等。

---

## 1. 环境要求

- Docker Desktop 已启用 Kubernetes
- kubectl 已配置并可访问集群
- 网络可访问 GitHub 下载清单文件

---

## 2. 部署 Kubernetes Dashboard

### 2.1 一键部署

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

**输出示例：**
```
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
```

### 2.2 验证部署状态

```bash
kubectl get pods -n kubernetes-dashboard
```

**输出示例：**
```
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-5ffb7d645f-92vhz   1/1     Running   0          30s
kubernetes-dashboard-6c7b75ffc-qj4kp         1/1     Running   0          30s
```

---

## 3. 创建管理员访问令牌

### 3.1 创建 ServiceAccount 和 ClusterRoleBinding

创建 `dashboard-adminuser.yaml` 文件：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

### 3.2 应用配置

```bash
kubectl apply -f dashboard-adminuser.yaml
```

### 3.3 生成访问令牌

```bash
kubectl create token admin-user -n kubernetes-dashboard
```

> **注意**：令牌有效期约 15 分钟，过期后重新生成即可。

---

## 4. 访问 Dashboard

### 4.1 启动 kubectl 代理

```bash
kubectl proxy
```

保持此终端窗口运行，不要关闭。

### 4.2 打开浏览器

访问以下地址：

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### 4.3 登录

1. 浏览器打开上述地址后，选择 **"Token"** 登录选项
2. 复制令牌（不含引号）粘贴到 Token 输入框
3. 点击 **"Sign in"** 按钮

---

## 5. 快速命令参考

| 操作 | 命令 |
|------|------|
| 部署 Dashboard | `kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml` |
| 创建管理员账号 | `kubectl apply -f dashboard-adminuser.yaml` |
| 获取访问令牌 | `kubectl create token admin-user -n kubernetes-dashboard` |
| 查看 Pod 状态 | `kubectl get pods -n kubernetes-dashboard` |
| 启动代理 | `kubectl proxy` |
| 删除 Dashboard | `kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml` |

---

## 6. Dashboard 功能概览

### 6.1 资源管理

- **Workloads**：Deployment、Pod、ReplicaSet、DaemonSet、StatefulSet、CronJob、Job
- **Service**：ClusterIP、NodePort、LoadBalancer、Ingress
- **Config 和 Storage**：ConfigMap、Secret、PersistentVolume、StorageClass
- **RBAC**：ServiceAccount、Role、ClusterRole、RoleBinding、ClusterRoleBinding

### 6.2 主要功能

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

## 7. 注意事项

### 7.1 代理运行

- 访问 Dashboard 期间，`kubectl proxy` 必须保持运行
- 关闭代理后需要重新访问

### 7.2 令牌过期

- 默认令牌约 15 分钟后过期
- 过期后重新生成：
  ```bash
  kubectl create token admin-user -n kubernetes-dashboard
  ```

### 7.3 生产环境

> **警告**：本配置仅适用于本地开发环境。生产环境请参考 [官方安全文档](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) 配置适当的认证和授权机制。

---

## 8. 故障排查

### 8.1 Pod 无法启动

```bash
# 查看详细状态
kubectl describe pod <pod-name> -n kubernetes-dashboard

# 查看日志
kubectl logs <pod-name> -n kubernetes-dashboard
```

### 8.2 无法访问 Dashboard

1. 确认 `kubectl proxy` 正在运行
2. 确认 Dashboard Pod 状态为 Running
3. 检查浏览器是否允许 localhost 连接

### 8.3 令牌无效

1. 重新生成令牌
2. 确认复制的令牌完整且无误

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `dashboard-adminuser.yaml` | 管理员账号配置 |
| `kubernetes-specification/` | 相关 YAML 示例文件目录 |

---

## 参考链接

- [Kubernetes Dashboard 官方文档](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- [Dashboard GitHub 仓库](https://github.com/kubernetes/dashboard)
