# Kubernetes代码验证说明

## 验证概述

本专题的所有代码示例都经过验证，确保可以正常运行。每个章节都包含：

- 完整的代码示例
- 详细的注释说明
- 执行步骤说明
- 预期输出结果

## 验证方法

### 手动验证

1. 进入codes目录：`cd <chapter-dir>/codes`
2. 运行 `kubectl apply -f <file>` 应用配置
3. 运行 `kubectl get <resource>` 查看资源状态
4. 验证资源创建成功
5. 清理资源：`kubectl delete -f <file>`

### 自动验证

使用提供的验证脚本自动验证所有代码示例。

## 验证状态

| 章节 | 文件 | 状态 | 验证日期 |
|------|------|------|----------|
| 02-pod-management | pod-basic.yaml | ✅ 已验证 | 2026-03-22 |
| 03-deployment-replicaset | deployment-basic.yaml | ✅ 已验证 | 2026-03-22 |
| 04-service-ingress | service-clusterip.yaml | ✅ 已验证 | 2026-03-22 |
| 05-configmap-secret | configmap-basic.yaml | ✅ 已验证 | 2026-03-22 |
| 05-configmap-secret | secret-basic.yaml | ✅ 已验证 | 2026-03-22 |

## 环境准备

```bash
kubectl version --short
kubectl cluster-info
kubectl get nodes
```

## 快速验证流程

### Pod管理验证

```bash
cd 02-pod-management/codes
kubectl apply -f pod-basic.yaml
kubectl get pods
kubectl describe pod nginx-pod
kubectl delete -f pod-basic.yaml
```

### Deployment验证

```bash
cd 03-deployment-replicaset/codes
kubectl apply -f deployment-basic.yaml
kubectl get deployments
kubectl get replicasets
kubectl rollout status deployment/nginx-deployment
kubectl delete -f deployment-basic.yaml
```

### Service验证

```bash
cd 03-deployment-replicaset/codes && kubectl apply -f deployment-basic.yaml
cd ../04-service-ingress/codes && kubectl apply -f service-clusterip.yaml
kubectl get services
kubectl delete -f service-clusterip.yaml
cd ../../03-deployment-replicaset/codes && kubectl delete -f deployment-basic.yaml
```

### ConfigMap和Secret验证

```bash
cd 05-configmap-secret/codes
kubectl apply -f configmap-basic.yaml
kubectl apply -f secret-basic.yaml
kubectl get configmaps
kubectl get secrets
kubectl describe configmap app-config
kubectl delete -f configmap-basic.yaml
kubectl delete -f secret-basic.yaml
```

## 常见问题排查

### Pod一直处于Pending

检查是否有足够的资源或缺少必需的PVC。

### Pod一直处于ContainerCreating

使用 `kubectl describe pod <name>` 检查是否有缺失的ConfigMap或Secret。

### Service无法访问

检查Endpoints是否正确配置：`kubectl get endpoints <service-name>`
