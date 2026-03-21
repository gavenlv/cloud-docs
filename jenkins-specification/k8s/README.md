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