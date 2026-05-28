# Kubernetes专题

## 概述

本专题提供从基础到专家级的Kubernetes教程，涵盖Kubernetes的核心概念、底层原理、实战案例和最佳实践。每个章节都包含详细的代码示例、原理解释和验证步骤，帮助读者深入理解Kubernetes的工作原理。

## 目录结构

```
kubernetes-specification/
├── README.md                              # 本文件
├── 01-fundamentals/                       # Kubernetes基础和核心原理
│   └── 01-fundamentals.md
├── 02-pod-management/                     # Pod管理
│   ├── 02-pod-management.md
│   └── codes/
│       ├── pod-basic.yaml                 # ✅ 已验证
│       ├── pod-health-checks.yaml
│       ├── pod-multi-container.yaml
│       ├── pod-node-affinity.yaml
│       ├── pod-node-selector.yaml
│       ├── pod-pod-affinity.yaml
│       ├── pod-resources.yaml
│       └── pod-taint-toleration.yaml
├── 03-deployment-replicaset/              # Deployment和ReplicaSet
│   ├── 03-deployment-replicaset.md
│   └── codes/
│       ├── deployment-basic.yaml           # ✅ 已验证
│       ├── deployment-blue-green.yaml
│       ├── deployment-canary.yaml
│       └── deployment-rolling-update.yaml
├── 04-service-ingress/                    # Service和Ingress
│   ├── 04-service-ingress.md
│   └── codes/
│       ├── ingress-auth.yaml
│       ├── ingress-hostname.yaml
│       ├── ingress-path.yaml
│       ├── ingress-rate-limit.yaml
│       ├── service-clusterip.yaml         # ✅ 已验证
│       ├── service-externalname.yaml
│       ├── service-loadbalancer.yaml
│       └── service-nodeport.yaml
├── 05-configmap-secret/                   # ConfigMap和Secret
│   ├── 05-configmap-secret.md
│   └── codes/
│       ├── configmap-basic.yaml            # ✅ 已验证
│       ├── configmap-files.yaml
│       ├── pod-configmap-env.yaml
│       ├── pod-configmap-volume.yaml
│       ├── pod-secret-env.yaml
│       ├── pod-secret-volume.yaml
│       ├── secret-basic.yaml               # ✅ 已验证
│       ├── secret-dockerconfig.yaml
│       └── secret-tls.yaml
├── 06-persistent-volume/                  # PersistentVolume和PersistentVolumeClaim
│   ├── 06-persistent-volume.md
│   └── codes/
│       ├── pod-pvc.yaml
│       ├── pv-aws-ebs.yaml
│       ├── pv-gce-pd.yaml
│       ├── pv-local.yaml
│       ├── pv-nfs.yaml
│       ├── pvc-basic.yaml
│       ├── pvc-block.yaml
│       ├── pvc-dynamic.yaml
│       ├── pvc-readonly.yaml
│       ├── storageclass-aws-ebs.yaml
│       ├── storageclass-gce-pd.yaml
│       ├── storageclass-local.yaml
│       └── storageclass-nfs.yaml
├── 07-statefulset-daemonset/              # StatefulSet和DaemonSet
│   ├── 07-statefulset-daemonset.md
│   └── codes/
│       ├── daemonset-basic.yaml
│       ├── daemonset-node-selector.yaml
│       ├── daemonset-taint-toleration.yaml
│       ├── service-headless.yaml
│       ├── statefulset-basic.yaml
│       └── statefulset-partition.yaml
├── 08-helm-package-manager/               # Helm包管理
│   ├── 08-helm-package-manager.md
│   └── codes/
│       ├── deployment.yaml
│       ├── values.yaml
│       ├── myapp/                         # 完整Chart示例
│       └── myshop/                        # 电商应用Chart
├── 09-best-practices/                    # Kubernetes最佳实践
│   └── 09-best-practices.md
├── 10-troubleshooting/                    # Kubernetes常见错误处理
│   └── 10-troubleshooting.md
├── 11-kubectl-config/                    # kubectl配置详解
│   ├── 11-kubectl-config.md
│   └── codes/
│       └── yaml-1.yaml
├── 12-Kubernetes-Dashboard/              # Kubernetes Dashboard部署
│   ├── 12-Kubernetes-Dashboard.md
│   └── dashboard-adminuser.yaml
├── 12-operator/                          # Kubernetes Operator开发
│   ├── 12-operator.md
│   └── codes/
│       ├── crd.yaml
│       └── webhook.yaml
├── 13-extending-kubernetes/               # Kubernetes定制与扩展
│   ├── 13-extending-kubernetes.md
│   └── codes/
│       ├── apiservice.yaml
│       ├── custom-resource.yaml
│       ├── custom-scheduler.yaml
│       ├── network-policy.yaml
│       └── scheduler-config.yaml
├── 14-kubectl-commands/                   # kubectl命令详解
│   ├── 14-kubectl-commands.md
│   └── codes/
│       └── ingress.yaml
├── 15-gcp-secret-manager/                 # GCP Secret Manager集成
│   ├── 15-gcp-secret-manager.md
│   └── codes/
│       ├── deployment-secrets-store.yaml
│       ├── secret-provider-class.yaml
│       └── service-account.yaml
├── 16-gke-private-cluster/                # GKE私有集群
│   ├── 16-gke-private-cluster.md
│   └── codes/
│       ├── cluster-private.yaml
│       └── firewall-rules.yaml
├── 17-operator-deep-dive/                 # Operator深入
│   ├── 17-operator-deep-dive.md
│   └── pg-operator/                       # PostgreSQL Operator示例
├── 18-gke-cloud-service-mesh/             # GKE Cloud Service Mesh
│   └── 01-gke-cloud-service-mesh.md
├── VERIFICATION.md                        # 代码验证说明
├── verify-kubectl-config.ps1              # kubectl配置验证脚本
├── verify-kubectl-config.sh
└── verify-operator.ps1                     # Operator验证脚本
└── verify-operator.sh
```

## 快速开始

### 1. 运行单个YAML文件

```bash
# 运行Pod示例
kubectl apply -f 02-pod-management/codes/pod-basic.yaml

# 查看Pod状态
kubectl get pods

# 删除Pod
kubectl delete -f 02-pod-management/codes/pod-basic.yaml
```

### 2. 批量运行章节示例

```bash
# 进入章节目录
cd 02-pod-management/codes

# 运行所有Pod示例
for file in *.yaml; do kubectl apply -f $file; done

# 查看所有Pod
kubectl get pods

# 清理所有Pod
for file in *.yaml; do kubectl delete -f $file; done
```

### 3. 验证部署

```bash
# 检查资源状态
kubectl get all

# 查看资源详情
kubectl describe <resource-type> <resource-name>

# 查看日志
kubectl logs <pod-name>
```

## 章节运行指南

### 02-pod-management - Pod管理

**运行命令：**
```bash
kubectl apply -f 02-pod-management/codes/pod-basic.yaml
kubectl apply -f 02-pod-management/codes/pod-health-checks.yaml
```

**验证命令：**
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**清理命令：**
```bash
kubectl delete -f 02-pod-management/codes/pod-basic.yaml
kubectl delete -f 02-pod-management/codes/pod-health-checks.yaml
```

### 03-deployment-replicaset - Deployment管理

**运行命令：**
```bash
kubectl apply -f 03-deployment-replicaset/codes/deployment-basic.yaml
```

**验证命令：**
```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods
kubectl rollout status deployment/nginx-deployment
```

**清理命令：**
```bash
kubectl delete -f 03-deployment-replicaset/codes/deployment-basic.yaml
```

### 04-service-ingress - Service配置

**运行命令：**
```bash
kubectl apply -f 03-deployment-replicaset/codes/deployment-basic.yaml
kubectl apply -f 04-service-ingress/codes/service-clusterip.yaml
```

**验证命令：**
```bash
kubectl get services
kubectl get endpoints
curl http://<service-clusterip>:80
```

**清理命令：**
```bash
kubectl delete -f 04-service-ingress/codes/service-clusterip.yaml
kubectl delete -f 03-deployment-replicaset/codes/deployment-basic.yaml
```

### 05-configmap-secret - 配置管理

**运行命令：**
```bash
kubectl apply -f 05-configmap-secret/codes/configmap-basic.yaml
kubectl apply -f 05-configmap-secret/codes/secret-basic.yaml
```

**验证命令：**
```bash
kubectl get configmaps
kubectl get secrets
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

**清理命令：**
```bash
kubectl delete -f 05-configmap-secret/codes/configmap-basic.yaml
kubectl delete -f 05-configmap-secret/codes/secret-basic.yaml
```

### 07-statefulset-daemonset - 有状态应用

**运行命令：**
```bash
kubectl apply -f 07-statefulset-daemonset/codes/service-headless.yaml
kubectl apply -f 07-statefulset-daemonset/codes/statefulset-basic.yaml
```

**验证命令：**
```bash
kubectl get statefulsets
kubectl get pods -l app=web
kubectl describe statefulset web
```

**清理命令：**
```bash
kubectl delete -f 07-statefulset-daemonset/codes/statefulset-basic.yaml
kubectl delete -f 07-statefulset-daemonset/codes/service-headless.yaml
```

### 12-Kubernetes-Dashboard - Dashboard部署

**部署命令：**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl apply -f 12-Kubernetes-Dashboard/dashboard-adminuser.yaml
```

**获取访问令牌：**
```bash
kubectl create token admin-user -n kubernetes-dashboard
```

**启动代理：**
```bash
kubectl proxy
```

**访问Dashboard：**
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**清理命令：**
```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

## 代码验证状态

| 章节 | 文件 | 状态 |
|------|------|------|
| 02-pod-management | pod-basic.yaml | ✅ 已验证 |
| 03-deployment-replicaset | deployment-basic.yaml | ✅ 已验证 |
| 04-service-ingress | service-clusterip.yaml | ✅ 已验证 |
| 05-configmap-secret | configmap-basic.yaml | ✅ 已验证 |
| 05-configmap-secret | secret-basic.yaml | ✅ 已验证 |

## 学习路径

### 初级路径

1. [02-pod-management](./02-pod-management/) - 掌握Pod管理
2. [03-deployment-replicaset](./03-deployment-replicaset/) - 掌握Deployment管理
3. [04-service-ingress](./04-service-ingress/) - 实现服务发现

### 中级路径

1. [05-configmap-secret](./05-configmap-secret/) - 掌握配置管理
2. [06-persistent-volume](./06-persistent-volume/) - 实现数据持久化
3. [07-statefulset-daemonset](./07-statefulset-daemonset/) - 掌握有状态应用

### 高级路径

1. [08-helm-package-manager](./08-helm-package-manager/) - 掌握Helm包管理
2. [11-kubectl-config](./11-kubectl-config/) - 精通kubectl配置
3. [12-operator](./12-operator/) - 开发Kubernetes Operator
4. [13-extending-kubernetes](./13-extending-kubernetes/) - 扩展Kubernetes
5. [15-gcp-secret-manager](./15-gcp-secret-manager/) - GCP Secret Manager集成
6. [16-gke-private-cluster](./16-gke-private-cluster/) - GKE私有集群
7. [17-operator-deep-dive](./17-operator-deep-dive/) - Operator深入实践
8. [18-gke-cloud-service-mesh](./18-gke-cloud-service-mesh/) - GKE Cloud Service Mesh

## 前置要求

### 必备工具

- kubectl >= 1.24
- Docker Desktop (已启用Kubernetes) 或 Minikube/Kind
- Git

### 可选工具

- Helm >= 3.0
- k9s (终端UI)
- Lens (可视化IDE)

## 常见问题

### Q: Pod一直处于ContainerCreating状态？

A: 检查是否缺少必需的ConfigMap或Secret：
```bash
kubectl describe pod <pod-name>
# 查看Events中的错误信息
```

### Q: 如何查看所有命名空间的资源？

```bash
kubectl get pods -A
kubectl get services -A
```

### Q: 如何进入Pod内部调试？

```bash
kubectl exec -it <pod-name> -- /bin/sh
```

## 贡献指南

欢迎贡献代码、提出建议或报告问题。

## 许可证

MIT License
