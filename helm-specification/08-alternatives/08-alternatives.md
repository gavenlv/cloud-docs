# 替代方案对比

## 8.1 为什么需要了解替代方案

```
┌─────────────────────────────────────────────────────────────────┐
│  了解替代方案的价值                                              │
└─────────────────────────────────────────────────────────────────┘

1. 选择合适的工具
   ├── 不同场景有不同最佳选择
   ├── 避免过度工程
   └── 团队技能匹配

2. 理解权衡取舍
   ├── 每种方案都有优缺点
   ├── 理解设计决策背后的原因
   └── 做出明智选择

3. 技术演进
   ├── 工具在不断发展
   ├── 新方案不断涌现
   └── 保持开放心态

4. 组合使用
   ├── 工具可以组合
   ├── 取长补短
   └── 构建最佳方案
```

---

## 8.2 Kustomize

### 8.2.1 Kustomize概述

```
┌─────────────────────────────────────────────────────────────────┐
│  Kustomize简介                                                   │
└─────────────────────────────────────────────────────────────────┘

定义：
├── Kubernetes原生配置管理工具
├── 无模板引擎
├── 基于补丁的定制
└── 声明式配置

核心理念：
├── 纯YAML，无模板语法
├── 基础配置 + 补丁覆盖
├── kubectl内置支持
└── GitOps友好

适用场景：
├── 简单应用部署
├── 多环境配置管理
├── GitOps工作流
└── 不需要复杂模板逻辑
```

### 8.2.2 Kustomize结构

```yaml
# 目录结构
app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── patch-deployment.yaml
    ├── staging/
    │   ├── kustomization.yaml
    │   └── patch-deployment.yaml
    └── prod/
        ├── kustomization.yaml
        └── patch-deployment.yaml

# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  app: myapp

# base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:latest
          ports:
            - containerPort: 80

# overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patch-deployment.yaml

configMapGenerator:
  - name: myapp-config
    literals:
      - ENV=production

# overlays/prod/patch-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:v1.0.0
          resources:
            limits:
              cpu: 1000m
              memory: 1Gi
```

### 8.2.3 Helm vs Kustomize

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm vs Kustomize 对比                                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┬─────────────────┬─────────────────┐
│     特性        │      Helm       │    Kustomize    │
├─────────────────┼─────────────────┼─────────────────┤
│ 学习曲线        │ 中等            │ 低              │
│ 模板能力        │ 强大            │ 无              │
│ 版本管理        │ 内置            │ 需要外部工具    │
│ 依赖管理        │ 内置            │ 无              │
│ 回滚能力        │ 内置            │ 需要外部工具    │
│ GitOps友好      │ 是              │ 是              │
│ 配置验证        │ JSON Schema     │ 无内置          │
│ 生态丰富度      │ 高              │ 中              │
│ 复杂度          │ 较高            │ 较低            │
│ kubectl集成     │ 需要安装        │ 内置            │
└─────────────────┴─────────────────┴─────────────────┘

选择Helm的场景：
├── 需要复杂的模板逻辑
├── 需要版本管理和回滚
├── 需要依赖管理
├── 需要分发可复用的Chart
└── 部署复杂应用

选择Kustomize的场景：
├── 简单应用部署
├── 纯GitOps工作流
├── 不需要模板逻辑
├── 团队熟悉YAML
└── kubectl原生支持
```

### 8.2.4 组合使用

```yaml
# 使用Helm生成基础YAML，然后用Kustomize定制

# 1. 使用Helm模板生成基础配置
helm template myapp ./mychart > base.yaml

# 2. 使用Kustomize进行环境定制
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - base.yaml

patchesStrategicMerge:
  - overlay.yaml

# 3. 应用
kustomize build . | kubectl apply -f -
```

---

## 8.3 Jsonnet

### 8.3.1 Jsonnet概述

```
┌─────────────────────────────────────────────────────────────────┐
│  Jsonnet简介                                                     │
└─────────────────────────────────────────────────────────────────┘

定义：
├── 数据模板语言
├── JSON的超集
├── 支持变量、函数、继承
└── 强大的配置组合能力

特点：
├── 纯函数式
├── 面向对象特性
├── 强类型推断
└── 丰富的标准库

适用场景：
├── 复杂配置管理
├── 大规模Kubernetes配置
├── 需要高度可复用性
└── 配置逻辑复杂
```

### 8.3.2 Jsonnet示例

```jsonnet
// lib/common.libsonnet
{
  local this = self,
  
  name:: error "name is required",
  namespace:: "default",
  labels:: {
    "app.kubernetes.io/name": this.name,
    "app.kubernetes.io/managed-by": "jsonnet",
  },
  
  deployment: {
    apiVersion: "apps/v1",
    kind: "Deployment",
    metadata: {
      name: this.name,
      namespace: this.namespace,
      labels: this.labels,
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: this.labels,
      },
      template: {
        metadata: {
          labels: this.labels,
        },
        spec: {
          containers: [],
        },
      },
    },
  },
}

// app.jsonnet
local common = import "lib/common.libsonnet";

local myapp = common {
  name:: "myapp",
  namespace:: "production",
  
  deployment+: {
    spec+: {
      replicas: 3,
      template+: {
        spec+: {
          containers: [
            {
              name: "myapp",
              image: "myapp:v1.0.0",
              ports: [
                {
                  containerPort: 80,
                },
              ],
            },
          ],
        },
      },
    },
  },
};

{
  deployment: myapp.deployment,
}
```

### 8.3.3 Helm vs Jsonnet

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm vs Jsonnet 对比                                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┬─────────────────┬─────────────────┐
│     特性        │      Helm       │     Jsonnet     │
├─────────────────┼─────────────────┼─────────────────┤
│ 语言类型        │ Go模板          │ 数据语言        │
│ 学习曲线        │ 中等            │ 较高            │
│ 表达能力        │ 中等            │ 强大            │
│ 类型安全        │ 无              │ 有              │
│ 继承/组合       │ 有限            │ 强大            │
│ 版本管理        │ 内置            │ 需要外部工具    │
│ 生态            │ 丰富            │ 较小            │
│ 工具链          │ 成熟            │ 发展中          │
└─────────────────┴─────────────────┴─────────────────┘

选择Jsonnet的场景：
├── 配置逻辑非常复杂
├── 需要高度可复用的配置库
├── 团队有编程背景
├── 需要类型安全
└── 大规模配置管理
```

---

## 8.4 CD工具(ArgoCD/Flux)

### 8.4.1 GitOps概述

```
┌─────────────────────────────────────────────────────────────────┐
│  GitOps概念                                                      │
└─────────────────────────────────────────────────────────────────┘

定义：
├── Git作为单一事实来源
├── 声明式配置
├── 自动化同步
└── 审计和追溯

核心原则：
├── 声明式：描述期望状态
├── 版本化：Git管理所有配置
├── 自动化：自动应用变更
└── 持续协调：确保状态一致

GitOps工具：
├── ArgoCD
├── Flux
├── Rancher Fleet
└── Spinnaker
```

### 8.4.2 ArgoCD

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/myorg/myapp-config.git
    targetRevision: main
    path: overlays/production
    
  destination:
    server: https://kubernetes.default.svc
    namespace: production
    
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true

# 使用Helm + ArgoCD
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: 15.0.0
    helm:
      values: |
        replicaCount: 3
        service:
          type: ClusterIP
          
  destination:
    server: https://kubernetes.default.svc
    namespace: production
```

### 8.4.3 Flux

```yaml
# Flux HelmRelease
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  
  chart:
    spec:
      chart: nginx
      version: "15.x"
      sourceRef:
        kind: HelmRepository
        name: bitnami
        namespace: flux-system
      interval: 1m
      
  values:
    replicaCount: 3
    service:
      type: ClusterIP
      
  valuesFrom:
    - kind: ConfigMap
      name: myapp-values
    - kind: Secret
      name: myapp-secrets
```

### 8.4.4 Helm vs GitOps工具

```
┌─────────────────────────────────────────────────────────────────┐
│  Helm vs GitOps工具                                              │
└─────────────────────────────────────────────────────────────────┘

Helm:
├── 包管理工具
├── 命令式操作(helm install/upgrade)
├── 版本管理和回滚
└── 适合手动操作

GitOps工具(ArgoCD/Flux):
├── 持续部署工具
├── 声明式配置
├── 自动同步
└── 适合自动化部署

组合使用：
├── Helm管理Chart打包和分发
├── GitOps工具管理部署流程
├── Git作为配置存储
└── 自动化整个流程

最佳实践：
├── 开发阶段：使用Helm手动测试
├── CI阶段：使用Helm打包和验证
├── CD阶段：使用GitOps工具部署
└── 生产环境：GitOps + Helm
```

---

## 8.5 其他工具

### 8.5.1 Tanka

```
┌─────────────────────────────────────────────────────────────────┐
│  Tanka简介                                                       │
└─────────────────────────────────────────────────────────────────┘

定义：
├── Jsonnet的Kubernetes封装
├── Grafana Labs开发
├── 简化Jsonnet使用
└── 类似Helm的工作流

特点：
├── 使用Jsonnet作为配置语言
├── 支持环境管理
├── 内置diff和apply
└── 与Grafana生态集成

适用场景：
├── Grafana技术栈
├── 需要Jsonnet能力
├── 复杂配置管理
└── 团队熟悉Jsonnet
```

### 8.5.2 Pulumi

```
┌─────────────────────────────────────────────────────────────────┐
│  Pulumi简介                                                      │
└─────────────────────────────────────────────────────────────────┘

定义：
├── 基础设施即代码工具
├── 使用通用编程语言
├── 支持多种云平台
└── 声明式配置

特点：
├── TypeScript/Python/Go/C#
├── 完整的编程能力
├── 状态管理
├── 类型安全

适用场景：
├── 混合云部署
├── 复杂基础设施
├── 需要编程能力
└── 跨云管理
```

### 8.5.3 CDK for Kubernetes (cdk8s)

```
┌─────────────────────────────────────────────────────────────────┐
│  cdk8s简介                                                       │
└─────────────────────────────────────────────────────────────────┘

定义：
├── AWS开发的Kubernetes配置工具
├── 使用编程语言定义配置
├── 编译生成YAML
└── 类型安全

特点：
├── TypeScript/Python/Go/Java
├── 面向对象API
├── 自动生成YAML
└── 可测试

适用场景：
├── 需要类型安全
├── 复杂配置逻辑
├── 团队有编程背景
└── 需要可测试性
```

---

## 8.6 选择指南

### 8.6.1 决策矩阵

```
┌─────────────────────────────────────────────────────────────────┐
│  工具选择决策矩阵                                                │
└─────────────────────────────────────────────────────────────────┘

场景: 简单应用部署
├── 推荐: Kustomize
├── 备选: Helm
└── 理由: 学习成本低，kubectl内置

场景: 复杂应用部署
├── 推荐: Helm
├── 备选: Jsonnet
└── 理由: 模板能力强，生态丰富

场景: 企业级多环境
├── 推荐: Helm + GitOps
├── 备选: Kustomize + GitOps
└── 理由: 自动化，可追溯

场景: 微服务架构
├── 推荐: Helm + ArgoCD
├── 备选: Helm + Flux
└── 理由: 统一管理，自动化

场景: 需要分发Chart
├── 推荐: Helm
├── 备选: 无
└── 理由: 唯一成熟的包管理方案

场景: 纯GitOps工作流
├── 推荐: Kustomize + ArgoCD
├── 备选: Helm + Flux
└── 理由: 简单直接，无模板

场景: 复杂配置逻辑
├── 推荐: Jsonnet
├── 备选: Pulumi
└── 理由: 表达能力强

场景: 团队技能有限
├── 推荐: Kustomize
├── 备选: Helm
└── 理由: 学习曲线平缓
```

### 8.6.2 组合策略

```
┌─────────────────────────────────────────────────────────────────┐
│  工具组合策略                                                    │
└─────────────────────────────────────────────────────────────────┘

策略1: Helm + Kustomize
├── Helm: 打包和分发
├── Kustomize: 环境定制
└── 适用: 需要Chart分发能力

策略2: Helm + ArgoCD
├── Helm: Chart管理
├── ArgoCD: 持续部署
└── 适用: 企业级GitOps

策略3: Helm + Flux
├── Helm: Chart管理
├── Flux: 持续部署
└── 适用: CNCF生态

策略4: Jsonnet + Tanka
├── Jsonnet: 配置语言
├── Tanka: 工作流管理
└── 适用: 复杂配置需求

策略5: Helm + helmfile
├── Helm: Chart管理
├── helmfile: 声明式管理
└── 适用: 多Chart管理
```

### 8.6.3 迁移建议

```
┌─────────────────────────────────────────────────────────────────┐
│  迁移建议                                                        │
└─────────────────────────────────────────────────────────────────┘

从纯YAML迁移到Helm:
1. 创建基本Chart结构
2. 将YAML转为模板
3. 提取可变部分为Values
4. 逐步增加模板逻辑
5. 添加测试和文档

从Helm迁移到Kustomize:
1. 导出Helm渲染的YAML
2. 创建base目录
3. 创建overlays目录
4. 编写kustomization.yaml
5. 配置CI/CD

从Kustomize迁移到Helm:
1. 创建Chart结构
2. 将base YAML转为模板
3. 将overlays转为Values文件
4. 处理补丁逻辑
5. 测试和验证

引入GitOps:
1. 选择GitOps工具(ArgoCD/Flux)
2. 配置Git仓库
3. 定义Application/HelmRelease
4. 配置同步策略
5. 逐步自动化
```
