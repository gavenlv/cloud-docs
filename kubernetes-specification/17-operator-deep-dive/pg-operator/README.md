# PostgreSQL Operator

一个完整的 Kubernetes Operator，用于管理 PostgreSQL 集群的生命周期。

## 项目结构

```
pg-operator/
├── api/v1/                          # CRD 类型定义
│   ├── groupversion_info.go         # GroupVersion 信息
│   ├── postgrescluster_types.go     # PostgresCluster CRD 定义
│   └── zz_generated.deepcopy.go     # DeepCopy 方法
├── controllers/                      # Controller 实现
│   └── postgrescluster_controller.go # Reconcile 逻辑
├── config/
│   ├── crd/bases/                   # CRD YAML
│   ├── rbac/                        # RBAC 配置
│   ├── manager/                     # Operator 部署配置
│   └── samples/                     # 示例 CR
├── main.go                          # 入口文件
├── Dockerfile                       # Docker 构建文件
├── Makefile                         # 构建脚本
├── go.mod                           # Go 模块定义
└── go.sum                           # Go 依赖校验
```

## 功能特性

- ✅ 创建 PostgreSQL 单实例/高可用集群
- ✅ 自动创建 StatefulSet、Service、ConfigMap、Secret
- ✅ 水平扩缩容
- ✅ 滚动升级
- ✅ 持久化存储管理
- ✅ 读写分离 Service（primary/replica）
- ✅ 自动密码生成
- ✅ 自定义 PostgreSQL 参数
- ✅ 状态监控和条件更新

## 前置要求

- Go 1.21+
- Docker
- kubectl
- Kubernetes 集群（支持 kind、minikube、GKE、AKS、EKS 等）

## 快速开始

### 方式一：本地运行（开发模式）

```bash
# 1. 进入项目目录
cd pg-operator

# 2. 下载依赖
go mod tidy

# 3. 安装 CRD
kubectl apply -f config/crd/bases

# 4. 创建 namespace 和 RBAC
kubectl apply -f config/rbac

# 5. 本地运行 Operator
go run ./main.go
```

### 方式二：部署到集群

```bash
# 1. 构建镜像
docker build -t postgres-operator:latest .

# 2. 加载镜像到集群（以 kind 为例）
kind load docker-image postgres-operator:latest

# 3. 部署 Operator
kubectl apply -f config/crd/bases
kubectl apply -f config/rbac
kubectl apply -f config/manager

# 4. 查看 Operator 状态
kubectl get pods -n postgres-operator
kubectl logs -f -n postgres-operator -l control-plane=controller-manager
```

### 方式三：使用 Makefile

```bash
# 安装 CRD
make install

# 部署 Operator（需要先构建镜像）
make docker-build
make deploy

# 卸载
make undeploy
```

## 创建 PostgreSQL 集群

### 单实例集群

```bash
# 创建单实例集群
kubectl apply -f - <<EOF
apiVersion: postgresql.k8s.example.com/v1
kind: PostgresCluster
metadata:
  name: my-postgres
spec:
  instances: 1
  postgresqlVersion: "16"
  database: myapp
  storage:
    size: 1Gi
  resources:
    requests:
      cpu: "100m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
EOF
```

### 高可用集群

```bash
# 创建高可用集群
kubectl apply -f - <<EOF
apiVersion: postgresql.k8s.example.com/v1
kind: PostgresCluster
metadata:
  name: prod-postgres
spec:
  instances: 3
  postgresqlVersion: "16"
  database: production
  storage:
    size: 10Gi
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  highAvailability:
    enabled: true
  parameters:
    max_connections: "200"
    shared_buffers: "512MB"
EOF
```

## 查看集群状态

```bash
# 查看所有集群
kubectl get pg

# 查看集群详情
kubectl describe pg my-postgres

# 查看创建的资源
kubectl get all -l cluster=my-postgres

# 查看集群状态
kubectl get pg my-postgres -o yaml | grep -A30 status:
```

## 连接数据库

```bash
# 获取密码
PASSWORD=$(kubectl get secret my-postgres-secret -o jsonpath='{.data.postgres-password}' | base64 -d)

# 端口转发
kubectl port-forward svc/my-postgres 5432:5432

# 连接数据库
psql -h localhost -U postgres -d myapp
# 密码: $PASSWORD
```

## 扩缩容

```bash
# 扩容到 3 个实例
kubectl patch pg my-postgres --type merge -p '{"spec":{"instances":3}}'

# 缩容到 1 个实例
kubectl patch pg my-postgres --type merge -p '{"spec":{"instances":1}}'
```

## 升级版本

```bash
# 升级到 PostgreSQL 17
kubectl patch pg my-postgres --type merge -p '{"spec":{"postgresqlVersion":"17"}}'
```

## 删除集群

```bash
# 删除集群（会自动清理所有资源）
kubectl delete pg my-postgres
```

## 故障排除

```bash
# 查看 Operator 日志
kubectl logs -n postgres-operator -l control-plane=controller-manager

# 查看 CR 事件
kubectl describe pg my-postgres

# 查看 Pod 状态
kubectl get pods -l cluster=my-postgres

# 查看 Pod 日志
kubectl logs my-postgres-0
```

## 配置说明

### PostgresClusterSpec

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| instances | int32 | 是 | 实例数量 |
| postgresqlVersion | string | 是 | PostgreSQL 版本 |
| database | string | 否 | 默认数据库名 |
| storage.size | string | 是 | 存储大小 |
| storage.storageClass | string | 否 | 存储类名 |
| resources | ResourceRequirements | 否 | 资源请求和限制 |
| highAvailability.enabled | bool | 否 | 启用高可用 |
| backup.enabled | bool | 否 | 启用备份 |
| parameters | map[string]string | 否 | PostgreSQL 参数 |

## 开发指南

### 本地测试

```bash
# 运行测试
make test

# 代码格式化
make fmt

# 代码检查
make vet
```

### 添加新功能

1. 修改 `api/v1/postgrescluster_types.go` 添加新字段
2. 修改 `controllers/postgrescluster_controller.go` 实现新逻辑
3. 更新 CRD YAML: `config/crd/bases/postgresql.k8s.example.com_postgresclusters.yaml`
4. 测试并验证

## 许可证

Apache 2.0
