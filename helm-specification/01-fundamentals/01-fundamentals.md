# Helm基础与核心原理

## 1.1 为什么需要Helm

### 1.1.1 Kubernetes部署的演进

```
┌─────────────────────────────────────────────────────────────────┐
│  Kubernetes部署方式演进                                          │
└─────────────────────────────────────────────────────────────────┘

阶段1: 手动kubectl apply
├── 直接应用YAML文件
├── 问题：
│   ├── 配置分散在多个文件
│   ├── 环境差异需要手动修改
│   ├── 无版本管理
│   └── 无回滚能力
└── 适用场景：学习、简单应用

阶段2: kubectl + Kustomize
├── 基于补丁的配置管理
├── 优点：
│   ├── 声明式配置
│   ├── 多环境支持
│   ├── 无需模板
├── 问题：
│   ├── 无版本管理
│   ├── 无依赖管理
│   └── 无发布历史
└── 适用场景：简单应用、GitOps

阶段3: Helm
├── 完整的包管理解决方案
├── 优点：
│   ├── 模板引擎
│   ├── 版本管理
│   ├── 依赖管理
│   ├── 发布历史
│   └── 生态丰富
└── 适用场景：复杂应用、企业级部署
```

### 1.1.2 真实场景痛点

```
┌─────────────────────────────────────────────────────────────────┐
│  场景1: 部署一个Web应用                                         │
└─────────────────────────────────────────────────────────────────┘

需要管理的资源：
├── Deployment (应用部署)
├── Service (服务发现)
├── ConfigMap (配置)
├── Secret (敏感信息)
├── Ingress (入口路由)
├── HPA (自动扩缩容)
├── ServiceAccount (服务账户)
├── RBAC (权限控制)
└── PDB (Pod中断预算)

问题：
1. 文件数量多，管理复杂
2. 资源间存在依赖关系
3. 不同环境需要不同配置
4. 版本升级需要协调多个资源

┌─────────────────────────────────────────────────────────────────┐
│  场景2: 部署一个微服务架构                                       │
└─────────────────────────────────────────────────────────────────┘

需要管理的组件：
├── API Gateway
├── User Service
├── Order Service
├── Payment Service
├── Message Queue (RabbitMQ/Kafka)
├── Cache (Redis)
├── Database (PostgreSQL/MySQL)
└── Monitoring (Prometheus/Grafana)

问题：
1. 组件数量多，部署顺序复杂
2. 组件间存在依赖关系
3. 配置项数量庞大
4. 版本一致性难以保证

┌─────────────────────────────────────────────────────────────────┐
│  场景3: 多环境部署                                              │
└─────────────────────────────────────────────────────────────────┘

环境：
├── Development
│   ├── 单副本
│   ├── 最小资源配置
│   └── 调试模式
├── Staging
│   ├── 多副本
│   ├── 中等资源配置
│   └── 预生产配置
└── Production
    ├── 高可用部署
    ├── 大资源配置
    └── 生产级安全配置

问题：
1. 每个环境需要独立配置
2. 配置差异难以追踪
3. 环境漂移风险
4. 配置变更需要同步
```

### 1.1.3 Helm如何解决这些问题

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm的解决方案                                                  │
└─────────────────────────────────────────────────────────────────┘

问题1: 资源文件碎片化
解决方案: Chart打包
├── 将相关资源打包成单一单元
├── 统一版本管理
├── 一键安装/升级/卸载
└── 可分发、可复用

问题2: 配置管理困难
解决方案: Values + 模板
├── 参数化配置
├── 多环境Values文件
├── 配置优先级机制
└── JSON Schema验证

问题3: 版本管理缺失
解决方案: Release管理
├── 部署历史记录
├── 版本回滚
├── 版本比较
└── 状态追踪

问题4: 依赖关系复杂
解决方案: 依赖管理
├── 声明式依赖
├── 自动下载安装
├── 版本约束
└── 条件依赖

问题5: 重复劳动
解决方案: Chart复用
├── 官方Chart仓库
├── 社区Chart仓库
├── 企业私有仓库
└── 快速部署复杂应用
```

---

## 1.2 Helm架构

### 1.2.1 Helm 3架构

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm 3架构                                                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Helm CLI   │────▶│  Kubernetes  │────▶│   K8s API    │
│              │     │   Cluster    │     │   Server     │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │
       │                    │
       ▼                    ▼
┌──────────────┐     ┌──────────────┐
│    Chart     │     │   Release    │
│   (本地/远程) │     │   Storage    │
└──────────────┘     │   (Secret)   │
                     └──────────────┘

核心组件：
├── Helm CLI
│   ├── 本地客户端
│   ├── 无需服务端组件
│   └── 直接与K8s API交互
├── Chart
│   ├── 应用打包格式
│   ├── 包含模板和默认配置
│   └── 可存储在仓库或OCI注册表
├── Release
│   ├── Chart的一次安装实例
│   ├── 存储在K8s Secret中
│   └── 包含部署状态和历史
└── Repository
    ├── Chart存储位置
    ├── HTTP服务器
    └── OCI兼容注册表
```

### 1.2.2 Helm 2 vs Helm 3

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm 2 vs Helm 3 对比                                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Helm 2架构                                                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Helm CLI   │────▶│    Tiller    │────▶│   K8s API    │
│              │     │  (服务端组件) │     │   Server     │
└──────────────┘     └──────────────┘     └──────────────┘

Helm 2问题：
├── Tiller需要集群管理员权限
├── 安全风险大
├── 多租户隔离困难
└── 运维复杂度高

┌─────────────────────────────────────────────────────────────────┐
│  Helm 3改进                                                      │
└─────────────────────────────────────────────────────────────────┘

1. 移除Tiller
   ├── 无需服务端组件
   ├── 使用kubeconfig认证
   └── 更安全的权限模型

2. Release存储改进
   ├── 存储在命名空间的Secret中
   ├── 每个命名空间独立
   └── 支持多租户

3. 三路合并升级
   ├── 考虑当前集群状态
   ├── 更智能的升级策略
   └── 减少意外覆盖

4. OCI支持
   ├── 支持OCI注册表
   ├── 与容器镜像统一管理
   └── 更好的安全性

5. 其他改进
   ├── JSON Schema验证
   ├── Library Chart
   ├── 改进的测试框架
   └── 更好的错误信息
```

### 1.2.3 Release存储机制

```
┌─────────────────────────────────────────────────────────────────┐
│  Release存储                                                     │
└─────────────────────────────────────────────────────────────────┘

存储位置：
├── Kubernetes Secret
├── 命名空间: 与Release相同
├── 标签: 
│   ├── name: <release-name>
│   ├── owner: helm
│   └── status: <deployed/superseded/failed/etc>

Secret结构：
apiVersion: v1
kind: Secret
metadata:
  name: sh.helm.release.v1.myapp.v1
  namespace: default
  labels:
    name: myapp
    owner: helm
    status: deployed
    version: 1
type: helm.sh/release.v1
data:
  release: <base64-encoded-release-object>

Release对象内容：
├── Name: Release名称
├── Namespace: 命名空间
├── Chart: Chart信息
├── Config: 用户配置
├── Manifest: 渲染后的YAML
├── Version: 版本号
├── Status: 状态信息
└── Info: 部署信息

查看Release存储：
kubectl get secret -l owner=helm
kubectl get secret sh.helm.release.v1.myapp.v1 -o yaml
```

---

## 1.3 核心概念

### 1.3.1 Chart

```
┌─────────────────────────────────────────────────────────────────┐
│  Chart概念                                                       │
└─────────────────────────────────────────────────────────────────┘

定义：
Chart是Helm的打包格式，包含：
├── 一组Kubernetes资源模板
├── 默认配置值
├── 元数据信息
└── 可选的依赖

Chart类型：
├── Application Chart
│   ├── 可部署的应用
│   ├── 包含模板
│   └── 示例: nginx, redis, postgresql
└── Library Chart
    ├── 可复用的模板库
    ├── 不包含资源模板
    └── 示例: common, helpers

Chart版本：
├── version: Chart版本(语义化版本)
├── appVersion: 应用版本
└── 版本号格式: MAJOR.MINOR.PATCH

Chart命名规范：
├── 小写字母
├── 可包含数字和连字符
├── 不允许下划线或点
└── 示例: my-app, nginx-ingress, redis-cluster
```

### 1.3.2 Release

```
┌─────────────────────────────────────────────────────────────────┐
│  Release概念                                                     │
└─────────────────────────────────────────────────────────────────┘

定义：
Release是Chart的一次安装实例：
├── 唯一标识: name + namespace
├── 版本号: 递增整数
├── 状态: deployed/superseded/failed/etc
└── 历史: 所有版本记录

Release状态：
├── unknown: 未知状态
├── deployed: 已部署，当前版本
├── uninstalled: 已卸载
├── superseded: 已被新版本替代
├── failed: 安装/升级失败
├── uninstalling: 正在卸载
└── pending-install/pending-upgrade/pending-rollback: 进行中

Release生命周期：
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ install │───▶│ upgrade │───▶│ rollback│───▶│uninstall│
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │
     ▼              ▼              ▼              ▼
 version 1      version 2      version 3       deleted
                 version 3      version 2

Release命名：
├── 有意义的名称
├── 包含环境信息: myapp-prod, myapp-staging
├── 包含团队信息: team-a-myapp
└── 避免使用随机名称
```

### 1.3.3 Repository

```
┌─────────────────────────────────────────────────────────────────┐
│  Repository概念                                                  │
└─────────────────────────────────────────────────────────────────┘

定义：
Repository是Chart的存储和分发中心：
├── HTTP服务器
├── index.yaml索引文件
└── Chart包存储

仓库类型：
├── 公共仓库
│   ├── Artifact Hub (https://artifacthub.io/)
│   ├── Bitnami (https://charts.bitnami.com/bitnami)
│   └── 官方仓库 (https://charts.helm.sh/stable)
├── 私有仓库
│   ├── ChartMuseum
│   ├── Harbor
│   └── S3/GCS存储
└── OCI注册表
    ├── Docker Hub
    ├── GitHub Container Registry
    ├── AWS ECR
    └── Harbor

index.yaml结构：
apiVersion: v1
entries:
  nginx:
    - name: nginx
      version: 15.0.0
      description: NGINX Open Source
      urls:
        - https://charts.bitnami.com/bitnami/nginx-15.0.0.tgz
      digest: sha256:xxx
      created: "2024-01-15T00:00:00Z"
  redis:
    - name: redis
      version: 17.0.0
      ...

仓库管理命令：
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
helm search repo nginx
```

### 1.3.4 Values

```
┌─────────────────────────────────────────────────────────────────┐
│  Values概念                                                      │
└─────────────────────────────────────────────────────────────────┘

定义：
Values是Chart的配置参数：
├── 默认值: values.yaml
├── 覆盖值: -f/--values
├── 命令行值: --set
└── 合并策略: 深度合并

Values来源（优先级从高到低）：
├── --set-file
├── --set-string
├── --set
├── -f/--values (最后一个文件优先级最高)
├── values.yaml
└── Chart默认值

Values结构：
replicaCount: 3

image:
  repository: nginx
  tag: "1.25.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  hosts: []

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

Values访问：
├── .Values.replicaCount
├── .Values.image.repository
├── .Values.service.type
└── .Values.ingress.enabled
```

---

## 1.4 Release生命周期

### 1.4.1 安装(install)

```
┌─────────────────────────────────────────────────────────────────┐
│  helm install 流程                                               │
└─────────────────────────────────────────────────────────────────┘

流程：
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ 加载Chart│──▶│ 合并Values│──▶│ 渲染模板 │──▶│ 验证YAML │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
      │              │              │              │
      ▼              ▼              ▼              ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ 解析依赖 │   │ 深度合并 │   │ Go模板   │   │ Schema   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
                                                │
                                                ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ 创建Secret│◀──│ 等待就绪 │◀──│ 应用资源 │◀──│ 发送到K8s│
│ (Release)│   │(可选)    │   │(kubectl) │   │ API      │
└──────────┘   └──────────┘   └──────────┘   └──────────┘

命令示例：
helm install myapp ./mychart \
  --namespace production \
  --values values-prod.yaml \
  --set image.tag=v1.2.3 \
  --wait \
  --timeout 5m

安装选项：
├── --namespace: 目标命名空间
├── --values/-f: 指定Values文件
├── --set: 命令行设置值
├── --set-file: 从文件读取值
├── --set-string: 强制字符串类型
├── --wait: 等待资源就绪
├── --timeout: 超时时间
├── --dry-run: 模拟运行
├── --debug: 调试输出
└── --create-namespace: 自动创建命名空间
```

### 1.4.2 升级(upgrade)

```
┌─────────────────────────────────────────────────────────────────┐
│  helm upgrade 流程                                               │
└─────────────────────────────────────────────────────────────────┘

三路合并策略：
┌─────────────────────────────────────────────────────────────────┐
│  Helm 3三路合并                                                  │
└─────────────────────────────────────────────────────────────────┘

当前状态        期望状态        集群实际状态
(version 1)    (version 2)    (可能被修改)
     │              │              │
     └──────────────┼──────────────┘
                    ▼
              三路合并计算
                    │
                    ▼
              最终应用状态

合并规则：
├── 如果用户修改了值，使用新值
├── 如果集群状态被外部修改，保留修改
├── 如果模板发生变化，应用新模板
└── 冲突时，用户值优先

命令示例：
helm upgrade myapp ./mychart \
  --namespace production \
  --values values-prod.yaml \
  --set replicaCount=5 \
  --atomic \
  --history-max 10

升级选项：
├── --install: 如果不存在则安装
├── --atomic: 失败时自动回滚
├── --reset-values: 重置为默认值
├── --reuse-values: 复用上次值
├── --history-max: 历史版本数量限制
├── --cleanup-on-fail: 失败时清理新资源
└── --force: 强制重新创建资源
```

### 1.4.3 回滚(rollback)

```
┌─────────────────────────────────────────────────────────────────┐
│  helm rollback 流程                                              │
└─────────────────────────────────────────────────────────────────┘

回滚场景：
├── 升级后发现问题
├── 配置错误需要恢复
├── 应用版本回退
└── 紧急故障恢复

命令示例：
helm rollback myapp 1
helm rollback myapp --wait

查看历史：
helm history myapp

输出：
REVISION        UPDATED                         STATUS          CHART           DESCRIPTION
1               Mon Jan 15 10:00:00 2024        superseded      myapp-0.1.0     Install complete
2               Mon Jan 15 11:00:00 2024        superseded      myapp-0.2.0     Upgrade complete
3               Mon Jan 15 12:00:00 2024        deployed        myapp-0.1.0     Rollback to 1

回滚选项：
├── --wait: 等待资源就绪
├── --timeout: 超时时间
├── --dry-run: 模拟运行
└── --force: 强制重新创建资源
```

### 1.4.4 卸载(uninstall)

```
┌─────────────────────────────────────────────────────────────────┐
│  helm uninstall 流程                                             │
└─────────────────────────────────────────────────────────────────┘

卸载流程：
├── 获取Release信息
├── 删除Kubernetes资源
├── 删除Release Secret
└── 清理相关资源

命令示例：
helm uninstall myapp
helm uninstall myapp --namespace production
helm uninstall myapp --keep-history

卸载选项：
├── --keep-history: 保留Release历史
├── --wait: 等待删除完成
└── --timeout: 超时时间

注意事项：
├── CRD不会被自动删除
├── PVC默认不会被删除
├── 外部资源需要手动清理
└── 建议使用--dry-run预览
```

---

## 1.5 Helm环境配置

### 1.5.1 安装Helm

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm

# 验证安装
helm version

# 输出：
# version.BuildInfo{Version:"v3.13.0", GitCommit:"xxx", GitTreeState:"clean", GoVersion:"go1.20.8"}
```

### 1.5.2 环境变量

```bash
# 查看Helm环境
helm env

# 输出：
# HELM_NAMESPACE="default"
# HELM_KUBECONTEXT=""
# HELM_DEBUG="false"
# HELM_REGISTRY_CONFIG="/Users/user/.config/helm/registry.json"
# HELM_REPOSITORY_CACHE="/Users/user/.cache/helm/repository"
# HELM_REPOSITORY_CONFIG="/Users/user/.config/helm/repositories.yaml"
# HELM_PLUGINS="/Users/user/.local/share/helm/plugins"
# HELM_CACHE_HOME="/Users/user/.cache/helm"
# HELM_CONFIG_HOME="/Users/user/.config/helm"
# HELM_DATA_HOME="/Users/user/.local/share/helm"

# 常用环境变量
export HELM_NAMESPACE=production
export HELM_KUBECONTEXT=my-cluster
export HELM_DEBUG=true
```

### 1.5.3 配置kubeconfig

```bash
# 查看当前上下文
kubectl config current-context

# 切换上下文
kubectl config use-context my-cluster

# Helm使用特定kubeconfig
helm list --kubeconfig ~/.kube/config-prod

# 使用特定命名空间
helm list -n production
```

---

## 1.6 常用命令速查

### 1.6.1 Release管理

```bash
# 安装
helm install [NAME] [CHART] [flags]
helm install myapp ./mychart
helm install myapp bitnami/nginx

# 升级
helm upgrade [RELEASE] [CHART] [flags]
helm upgrade myapp ./mychart
helm upgrade myapp ./mychart --install

# 回滚
helm rollback [RELEASE] [REVISION]
helm rollback myapp 1

# 卸载
helm uninstall [RELEASE]
helm uninstall myapp

# 查看列表
helm list
helm list -n production
helm list --all-namespaces

# 查看状态
helm status [RELEASE]
helm status myapp

# 查看历史
helm history [RELEASE]
helm history myapp

# 查看manifest
helm get manifest [RELEASE]
helm get manifest myapp

# 查看values
helm get values [RELEASE]
helm get values myapp --all
```

### 1.6.2 Chart管理

```bash
# 创建Chart
helm create [NAME]
helm create mychart

# 验证Chart
helm lint [CHART]
helm lint ./mychart

# 打包Chart
helm package [CHART_PATH]
helm package ./mychart

# 查看模板渲染结果
helm template [NAME] [CHART]
helm template myapp ./mychart

# 拉取Chart
helm pull [REPO]/[CHART]
helm pull bitnami/nginx
helm pull bitnami/nginx --untar

# 显示Chart信息
helm show [command] [CHART]
helm show all bitnami/nginx
helm show values bitnami/nginx
helm show readme bitnami/nginx
```

### 1.6.3 仓库管理

```bash
# 添加仓库
helm repo add [NAME] [URL]
helm repo add bitnami https://charts.bitnami.com/bitnami

# 更新仓库
helm repo update

# 列出仓库
helm repo list

# 移除仓库
helm repo remove [NAME]
helm repo remove bitnami

# 搜索Chart
helm search repo [KEYWORD]
helm search repo nginx

# 搜索Hub
helm search hub [KEYWORD]
helm search hub nginx
```

### 1.6.4 调试命令

```bash
# 模拟安装
helm install myapp ./mychart --dry-run --debug

# 模拟升级
helm upgrade myapp ./mychart --dry-run --debug

# 查看渲染结果
helm template myapp ./mychart --debug

# 验证Chart
helm lint ./mychart --strict

# 查看Release notes
helm get notes myapp

# 查看所有信息
helm get all myapp
```
