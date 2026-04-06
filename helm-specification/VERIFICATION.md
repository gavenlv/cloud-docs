# 代码验证说明

本文档说明如何验证 helm-specification 专题中的代码示例。

## 环境要求

### 必需工具

- Helm >= 3.0
- Kubernetes集群 (可用kind/minikube)
- kubectl

### 推荐工具

- kind 或 minikube (本地Kubernetes)
- helmfile
- helm-diff插件
- helm-secrets插件

## 验证步骤

### 1. 环境准备

```bash
# 安装Helm
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm

# 验证安装
helm version

# 创建本地Kubernetes集群 (使用kind)
kind create cluster --name helm-test

# 验证集群连接
kubectl cluster-info
```

### 2. 章节验证

#### 01-fundamentals - Helm基础

```bash
cd 01-fundamentals/codes

# 验证Helm安装
helm version
helm env

# 添加常用仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 测试安装
helm install test-nginx bitnami/nginx --dry-run
```

#### 02-chart-structure - Chart结构

```bash
cd 02-chart-structure/codes

# 创建Chart
helm create mychart

# 验证Chart
helm lint mychart

# 查看模板渲染
helm template myapp mychart

# 打包Chart
helm package mychart

# 验证打包
helm show all mychart-*.tgz
```

#### 03-templates - 模板引擎

```bash
cd 03-templates/codes

# 创建测试Chart
helm create template-test

# 测试模板渲染
helm template myapp template-test --debug

# 测试条件渲染
helm template myapp template-test --set ingress.enabled=true

# 测试循环
helm template myapp template-test --debug

# 验证模板语法
helm lint template-test --strict
```

#### 04-values-management - Values配置

```bash
cd 04-values-management/codes

# 创建测试Chart
helm create values-test

# 测试多Values文件
helm template myapp values-test -f values.yaml -f values-prod.yaml

# 测试--set
helm template myapp values-test --set replicaCount=5

# 测试--set-string
helm template myapp values-test --set-string port="8080"

# 测试Values优先级
helm template myapp values-test \
  -f values.yaml \
  -f values-prod.yaml \
  --set replicaCount=10 \
  --debug
```

#### 05-chart-dependencies - Chart依赖

```bash
cd 05-chart-dependencies/codes

# 创建父Chart
helm create parent-chart

# 编辑Chart.yaml添加依赖
# 然后更新依赖
helm dependency update parent-chart

# 查看依赖
helm dependency list parent-chart

# 测试安装
helm template myapp parent-chart --debug
```

#### 06-chart-repository - Chart仓库

```bash
cd 06-chart-repository/codes

# 添加仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 搜索Chart
helm search repo nginx

# 拉取Chart
helm pull bitnami/nginx --untar

# 测试OCI (如果有注册表访问权限)
# helm registry login registry.example.com
# helm push mychart-0.1.0.tgz oci://registry.example.com/charts
```

#### 07-advanced-patterns - 高级模式

```bash
cd 07-advanced-patterns/codes

# 创建Umbrella Chart
mkdir -p umbrella-chart/charts

# 创建子Chart
helm create umbrella-chart/charts/frontend
helm create umbrella-chart/charts/backend

# 创建父Chart.yaml
# 添加依赖并更新
helm dependency update umbrella-chart

# 测试安装
helm template myapp umbrella-chart --debug
```

#### 08-alternatives - 替代方案

```bash
cd 08-alternatives/codes

# 测试Kustomize (需要安装kustomize)
kustomize build overlays/production

# 或使用kubectl
kubectl kustomize overlays/production

# 比较Helm和Kustomize输出
helm template myapp ./helm-chart > helm-output.yaml
kustomize build ./kustomize/overlays/production > kustomize-output.yaml
diff helm-output.yaml kustomize-output.yaml
```

#### 09-troubleshooting - 故障排除

```bash
cd 09-troubleshooting/codes

# 测试调试命令
helm create debug-chart

# 模板调试
helm template myapp debug-chart --debug

# 模拟安装
helm install myapp debug-chart --dry-run --debug

# 测试lint
helm lint debug-chart --strict

# 测试验证
helm template myapp debug-chart --validate
```

## 验证清单

### 基础验证

- [ ] Helm版本 >= 3.0
- [ ] Kubernetes集群可访问
- [ ] kubectl配置正确
- [ ] 基本命令可用 (helm list, helm repo list)

### Chart验证

- [ ] helm lint 通过
- [ ] helm template 渲染成功
- [ ] helm install --dry-run 通过
- [ ] 资源创建成功

### 模板验证

- [ ] 变量替换正确
- [ ] 条件判断正常
- [ ] 循环迭代正常
- [ ] 助手模板工作正常

### Values验证

- [ ] 默认值正确
- [ ] 覆盖值生效
- [ ] 多文件合并正确
- [ ] Schema验证通过

### 依赖验证

- [ ] 依赖下载成功
- [ ] 版本约束正确
- [ ] 条件依赖工作正常
- [ ] 子Chart配置正确

### 安装验证

- [ ] helm install 成功
- [ ] helm upgrade 成功
- [ ] helm rollback 成功
- [ ] helm uninstall 成功

## 常见问题

### Q: helm install 卡住

A: 检查Pod状态和事件：
```bash
kubectl get pods -w
kubectl get events --sort-by='.lastTimestamp'
```

### Q: 模板渲染错误

A: 使用--debug查看详细信息：
```bash
helm template myapp ./mychart --debug
```

### Q: 依赖下载失败

A: 更新仓库并检查网络：
```bash
helm repo update
curl -I https://charts.bitnami.com/bitnami/index.yaml
```

### Q: 权限不足

A: 检查kubeconfig和权限：
```bash
kubectl auth can-i create deployments --namespace default
```

## 清理环境

```bash
# 删除所有测试Release
helm list --all-namespaces | grep test | awk '{print $1}' | xargs helm uninstall

# 删除测试命名空间
kubectl delete namespace helm-test --ignore-not-found

# 删除kind集群
kind delete cluster --name helm-test

# 清理本地缓存
rm -rf ~/.cache/helm
```
