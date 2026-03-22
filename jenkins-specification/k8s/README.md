# Jenkins Kubernetes部署

## 前提条件

- Kubernetes集群已启动 (kubectl已配置)
- Ingress控制器已部署 (可选)
- StorageClass已配置 (默认使用hostpath)

## 快速部署

```bash
# 进入目录
cd jenkins-specification/k8s

# 创建namespace和资源
kubectl apply -f namespace.yaml
kubectl apply -f pvc.yaml
kubectl apply -f rbac.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

# 查看Pod状态
kubectl get pods -n jenkins

# 查看服务
kubectl get svc -n jenkins
```

## 访问Jenkins

### NodePort方式

- URL: http://<node-ip>:30080

### Ingress方式

- 需要在hosts添加: `127.0.0.1 jenkins.local`
- URL: http://jenkins.local

## 获取初始密码

```bash
kubectl exec -n jenkins deploy/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

## Agent配置

Agent通过JNLP自动连接，需要在Jenkins中添加节点:

1. Manage Jenkins → Manage Nodes → New Node
2. 名称: `kubernetes-agent`
3. 选择: Permanent Agent
4. 启动方式: Launch agent via connecting to the master
5. 生成JNLP secret并配置Agent

## 资源限制

| 组件 | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------|-------------|-----------|----------------|--------------|
| Jenkins Master | 100m | 500m | 256Mi | 1Gi |
| Jenkins Agent | 50m | 200m | 128Mi | 256Mi |

## 清理

```bash
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f agent-deployment.yaml
kubectl delete -f rbac.yaml
kubectl delete -f pvc.yaml
kubectl delete -f namespace.yaml
```

---

## YAML配置文件详解

### 资源创建顺序

```
1. namespace.yaml    # 创建命名空间
2. pvc.yaml         # 创建持久化存储
3. rbac.yaml        # 创建ServiceAccount和RBAC权限
4. deployment.yaml   # 创建Jenkins Master
5. service.yaml     # 暴露服务
6. ingress.yaml      # 配置Ingress (可选)
7. agent-deployment.yaml  # 创建Agent (可选)
```

### 字段说明索引

| 文件 | 资源类型 | 说明 |
|------|----------|------|
| [namespace.yaml](namespace.yaml) | Namespace | 命名空间，用于资源隔离 |
| [pvc.yaml](pvc.yaml) | PersistentVolumeClaim | 持久化存储声明 |
| [deployment.yaml](deployment.yaml) | Deployment | Jenkins Master无状态部署 |
| [service.yaml](service.yaml) | Service | 服务暴露 |
| [ingress.yaml](ingress.yaml) | Ingress | HTTP/HTTPS路由 |
| [rbac.yaml](rbac.yaml) | ServiceAccount/Role/RoleBinding | 权限控制 |
| [agent-deployment.yaml](agent-deployment.yaml) | Deployment | Jenkins Agent部署 |

### 常用资源类型

| kind | 说明 | apiVersion |
|------|------|------------|
| Namespace | 命名空间 | v1 |
| Pod | Pod | v1 |
| Service | 服务 | v1 |
| Deployment | 无状态部署 | apps/v1 |
| StatefulSet | 有状态部署 | apps/v1 |
| DaemonSet | 每节点Pod | apps/v1 |
| ConfigMap | 配置 | v1 |
| Secret | 密钥 | v1 |
| PersistentVolumeClaim | 存储声明 | v1 |
| Ingress | HTTP路由 | networking.k8s.io/v1 |
| ServiceAccount | 服务账户 | v1 |
| Role | 角色(NS级) | rbac.authorization.k8s.io/v1 |
| ClusterRole | 角色(集群级) | rbac.authorization.k8s.io/v1 |
| RoleBinding | 角色绑定 | rbac.authorization.k8s.io/v1 |
| ConfigMap | 配置映射 | v1 |

### 常用注解 (annotations)

| 注解 | 说明 | 可选值 |
|------|------|--------|
| nginx.ingress.kubernetes.io/ssl-redirect | SSL重定向 | "true", "false" |
| nginx.ingress.kubernetes.io/proxy-body-size | 请求体大小 | "10m", "100m" |
| nginx.ingress.kubernetes.io/proxy-connect-timeout | 连接超时 | 秒数 |
| nginx.ingress.kubernetes.io/proxy-read-timeout | 读取超时 | 秒数 |

### 常用标签 (labels)

| 标签键 | 说明 | 示例值 |
|--------|------|--------|
| app | 应用名称 | jenkins, nginx, mysql |
| tier | 层级 | frontend, backend, database |
| environment | 环境 | dev, staging, production |
| version | 版本 | v1, v2, latest |