# 平台工程

## 本章概述

平台工程是构建内部开发者平台(IDP)的学科。本章将学习平台设计、开发者体验和平台运营。

## 学习目标

- 理解平台工程理念
- 掌握平台架构设计
- 学会开发者体验优化
- 掌握自助服务设计
- 理解平台运营模式
- 学会平台度量指标

---

## 1. 平台工程概述

### 1.1 平台工程定义

```
平台工程定义

┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│   平台工程是设计和构建工具链与工作流的学科，                              │
│   为云原生应用的生命周期提供自助服务能力。                                │
│                                                                         │
│   目标：                                                                 │
│   ├── 提升开发者生产力                                                  │
│   ├── 降低认知负担                                                      │
│   ├── 标准化最佳实践                                                    │
│   ├── 加速交付速度                                                      │
│   └── 提高可靠性                                                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

传统模式 vs 平台模式

传统模式：
┌─────────────┐
│   开发者    │
│     ↓       │
│  提交工单   │
│     ↓       │
│   运维团队  │◄── 瓶颈
│     ↓       │
│  手动配置   │
│     ↓       │
│   交付环境  │
└─────────────┘

平台模式：
┌─────────────┐
│   开发者    │
│     ↓       │
│  自助平台   │◄── 自动化
│     ↓       │
│  自动配置   │
│     ↓       │
│  即时交付   │
└─────────────┘
```

### 1.2 平台成熟度模型

```
平台成熟度模型

Level 5: 智能
├── AI辅助开发
├── 预测性运维
├── 自适应优化
└── 持续学习

Level 4: 优化
├── 数据驱动决策
├── 持续改进流程
├── 度量驱动优化
└── 自动化治理

Level 3: 可扩展
├── 模块化架构
├── 插件生态系统
├── 多团队支持
└── 自助服务

Level 2: 基础
├── 核心服务集成
├── 基础自助服务
├── 标准化模板
└── 文档完善

Level 1: 初始
├── 脚本自动化
├── 手动审批
├── 分散工具
└── 有限文档
```

---

## 2. 平台架构设计

### 2.1 平台架构

```
内部开发者平台架构

┌─────────────────────────────────────────────────────────────────────────┐
│                          开发者门户层                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Backstage / Port                          │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐    │   │
│  │  │ 服务目录  │  │ 文档中心  │  │ 软件模板  │  │ 搜索发现  │    │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
┌───────────────────────────────────┴─────────────────────────────────────┐
│                          平台服务层                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐    │   │
│  │  │ CI/CD     │  │ 可观测性  │  │ 安全      │  │ 数据      │    │   │
│  │  │ GitHub    │  │ Grafana   │  │ Vault     │  │ 数据库    │    │   │
│  │  │ Actions   │  │ Cloud     │  │ SSO       │  │ 缓存      │    │   │
│  │  │ ArgoCD    │  │ Datadog   │  │ Kyverno   │  │ 消息队列  │    │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
┌───────────────────────────────────┴─────────────────────────────────────┐
│                          基础设施层                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐    │   │
│  │  │Kubernetes │  │ 云服务    │  │ 网络      │  │ 存储      │    │   │
│  │  │EKS/AKS    │  │ AWS/Azure │  │ VPC       │  │ S3/EBS    │    │   │
│  │  │GKE        │  │ GCP       │  │ Service   │  │ Ceph      │    │   │
│  │  │           │  │           │  │ Mesh      │  │           │    │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 核心组件

```yaml
platform-components:

portal:
  name: Backstage
  plugins:
    - catalog
    - scaffolder
    - techdocs
    - kubernetes
    - argocd
    - cost-insights
    
gitops:
  name: ArgoCD
  config:
    repo-server: gitlab.internal
    sync-policy: automated
    self-heal: true
    
secret-management:
  name: HashiCorp Vault
  config:
    auth-methods:
      - kubernetes
      - oidc
    secret-engines:
      - kv-v2
      - database
      
policy-engine:
  name: Kyverno
  policies:
    - require-resource-limits
    - disallow-privileged
    - enforce-image-signature
    
infrastructure:
  name: Crossplane
  providers:
    - aws
    - kubernetes
  compositions:
    - rds-instance
    - s3-bucket
    - redis-cluster
```

---

## 3. 开发者体验

### 3.1 开发者体验原则

```
开发者体验原则

1. 自助服务
   ├── 无需等待审批
   ├── 即时资源获取
   └── 自主问题解决

2. 黄金路径
   ├── 预设最佳实践
   ├── 标准化模板
   ├── 降低认知负担
   └── 快速启动

3. 一致性
   ├── 统一工具链
   ├── 标准化流程
   ├── 一致的API
   └── 统一文档

4. 可观测性
   ├── 透明的状态
   ├── 清晰的反馈
   ├── 易于调试
   └── 主动告警

5. 文档化
   ├── 即时可用
   ├── 上下文相关
   ├── 持续更新
   └── 示例丰富
```

### 3.2 黄金路径设计

```yaml
golden-paths:

backend-service:
  name: Java Spring Boot
  template: templates/java-spring-boot
  
  scaffolding:
    repository:
      name: ${service-name}
      template: spring-boot-template
      
    ci-cd:
      pipeline: java-gradle
      stages:
        - build
        - test
        - security-scan
        - deploy
        
    kubernetes:
      deployment: standard
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
          
    observability:
      metrics: micrometer
      tracing: opentelemetry
      logging: logback-json
      
    security:
      vulnerability-scanning: true
      secret-injection: vault
      
frontend-app:
  name: React TypeScript
  template: templates/react-typescript
  
  scaffolding:
    repository:
      name: ${app-name}
      template: react-ts-template
      
    ci-cd:
      pipeline: node-npm
      stages:
        - install
        - lint
        - test
        - build
        - deploy
        
    cdn:
      provider: cloudfront
      cache-policy: optimized
      
    observability:
      rum: enabled
      session-replay: enabled
```

### 3.3 自助服务目录

```yaml
self-service-catalog:

services:
  - name: create-environment
    category: infrastructure
    description: 创建新的开发环境
    parameters:
      - name: name
        type: string
        required: true
        pattern: "^[a-z][-a-z0-9]*$"
      - name: type
        type: select
        options: [development, staging, preview]
        default: development
      - name: ttl
        type: select
        options: [24h, 72h, 168h, permanent]
        default: 72h
    execution:
      type: crossplane
      composition: environment
    estimated-time: 5m
    
  - name: provision-database
    category: data
    description: 创建数据库实例
    parameters:
      - name: engine
        type: select
        options: [postgresql, mysql, mongodb]
      - name: size
        type: select
        options: [small, medium, large]
        default: small
      - name: environment
        type: select
        source: environments
    execution:
      type: terraform
      module: database/rds
    approval:
      production: true
      
  - name: scale-service
    category: operations
    description: 调整服务副本数
    parameters:
      - name: service
        type: select
        source: service-catalog
      - name: replicas
        type: number
        min: 1
        max: 20
      - name: environment
        type: select
        options: [staging, production]
    execution:
      type: kubectl
      action: scale
    approval:
      production: true
      threshold: 10
```

---

## 4. 平台运营

### 4.1 平台团队模式

```
平台团队组织模式

模式一：集中式平台团队
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                    ┌─────────────────┐                                  │
│                    │   平台团队      │                                  │
│                    │  (集中式)       │                                  │
│                    └────────┬────────┘                                  │
│                             │                                           │
│         ┌───────────────────┼───────────────────┐                      │
│         │                   │                   │                      │
│         ▼                   ▼                   ▼                      │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐              │
│  │  产品团队A  │     │  产品团队B  │     │  产品团队C  │              │
│  └─────────────┘     └─────────────┘     └─────────────┘              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

模式二：平台即产品
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                    ┌─────────────────┐                                  │
│                    │   平台产品团队  │                                  │
│                    │  产品经理       │                                  │
│                    │  工程师         │                                  │
│                    │  设计师         │                                  │
│                    └────────┬────────┘                                  │
│                             │                                           │
│                             ▼                                           │
│                    ┌─────────────────┐                                  │
│                    │   内部开发者    │                                  │
│                    │   (客户)        │                                  │
│                    └─────────────────┘                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 平台度量指标

```yaml
platform-metrics:

developer-productivity:
  - name: lead-time
    description: 从代码提交到部署的时间
    target: < 1 day
    measurement: deployment_timestamp - commit_timestamp
    
  - name: deployment-frequency
    description: 每日部署次数
    target: > 1 per day
    measurement: count(deployments) / days
    
  - name: change-failure-rate
    description: 部署失败率
    target: < 5%
    measurement: failed_deployments / total_deployments
    
  - name: mttr
    description: 平均恢复时间
    target: < 1 hour
    measurement: avg(restoration_time - incident_time)

platform-adoption:
  - name: self-service-usage
    description: 自助服务使用率
    target: > 80%
    measurement: self_service_requests / total_requests
    
  - name: golden-path-adoption
    description: 黄金路径采用率
    target: > 70%
    measurement: services_using_golden_path / total_services
    
  - name: developer-satisfaction
    description: 开发者满意度
    target: > 4.0 / 5.0
    measurement: survey_score

platform-health:
  - name: platform-availability
    description: 平台可用性
    target: 99.9%
    measurement: uptime / total_time
    
  - name: self-service-success-rate
    description: 自助服务成功率
    target: > 95%
    measurement: successful_requests / total_requests
```

---

## 5. 平台治理

### 5.1 治理框架

```yaml
governance-framework:

policies:
  - name: resource-quota
    type: kubernetes
    spec:
      hard:
        requests.cpu: "100"
        requests.memory: "200Gi"
        limits.cpu: "200"
        limits.memory: "400Gi"
        
  - name: image-whitelist
    type: kyverno
    spec:
      validate:
        message: "Image must be from approved registry"
        pattern:
          spec:
            containers:
              - image: "registry.company.com/*"
              
  - name: cost-tagging
    type: aws
    spec:
      required-tags:
        - team
        - environment
        - cost-center
      enforcement: deny

guardrails:
  - name: production-changes
    conditions:
      - environment: production
    requirements:
      - approval: required
      - change-window: defined
      - rollback-plan: required
      
  - name: security-scans
    conditions:
      - all-deployments
    requirements:
      - vulnerability-scan: passed
      - secrets-scan: passed
      - policy-check: passed
```

### 5.2 平台演进

```
平台演进路线图

第一阶段：基础 (0-6个月)
├── 核心基础设施
├── 基础CI/CD
├── 基础监控
└── 文档框架

第二阶段：标准化 (6-12个月)
├── 服务模板
├── 标准化流程
├── 自助服务基础
└── 知识库完善

第三阶段：自助服务 (12-18个月)
├── 完整自助服务
├── 开发者门户
├── 黄金路径
└── 自动化治理

第四阶段：优化 (18-24个月)
├── 度量驱动
├── 持续改进
├── 高级功能
└── 生态系统

第五阶段：智能 (24个月+)
├── AI辅助
├── 预测能力
├── 自适应
└── 创新
```

### 5.3 平台工程深度原理

**平台工程的底层实现机制是什么？**

```
┌─────────────────────────────────────────────────────────────────┐
│              平台工程核心机制解析                                   │
└─────────────────────────────────────────────────────────────────┘

Backstage架构：

┌─────────────────────────────────────────────────────────────────┐
│  Backstage核心组件：                                           │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  前端 (Frontend)：                                      │   │
│  │  ├── React应用                                         │   │
│  │  │   ├── SPA架构                                        │   │
│  │  │   ├── 组件化设计                                      │   │
│  │  │   ├── 路由管理                                        │   │
│  │  │   └── 状态管理                                        │   │
│  │  ├── 插件系统                                           │   │
│  │  │   ├── 动态加载                                        │   │
│  │  │   ├── 独立打包                                        │   │
│  │  │   ├── 依赖注入                                        │   │
│  │  │   └── 生命周期管理                                     │   │
│  │  └── 主题系统                                           │   │
│  │      ├── 主题切换                                        │   │
│  │      ├── 自定义样式                                       │   │
│  │      └── 品牌定制                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  后端 (Backend)：                                       │   │
│  │  ├── Node.js服务                                       │   │
│  │  │   ├── Express框架                                    │   │
│  │  │   ├── REST API                                       │   │
│  │  │   └── WebSocket支持                                   │   │
│  │  ├── 插件API                                           │   │
│  │  │   ├── 路由注册                                        │   │
│  │  │   ├── 中间件                                          │   │
│  │  │   ├── 数据库集成                                      │   │
│  │  │   └── 外部服务调用                                    │   │
│  │  └── 认证授权                                           │   │
│  │      ├── OAuth 2.0                                       │   │
│  │      ├── JWT Token                                      │   │
│  │      ├── 权限控制                                        │   │
│  │      └── 用户管理                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  目录服务 (Catalog Service)：                         │   │
│  │  ├── 实体注册                                           │   │
│  │  │   ├── 组件 (Component)                               │   │
│  │  │   │   ├── API服务                                     │   │
│  │  │   │   ├── 网站                                        │   │
│  │  │   │   ├── 库                                          │   │
│  │  │   │   └── 其他资源                                    │   │
│  │  │   ├── 系统 (System)                                  │   │
│  │  │   │   ├── 业务系统                                    │   │
│  │  │   │   ├── 平台系统                                    │   │
│  │  │   │   └── 基础设施                                    │   │
│  │  │   ├── API (API)                                      │   │
│  │  │   │   ├── OpenAPI规范                                 │   │
│  │  │   │   ├── GraphQL                                     │   │
│  │  │   │   └── gRPC                                        │   │
│  │  │   └── 资源 (Resource)                                │   │
│  │  │       ├── 数据库                                      │   │
│  │  │       ├── 队列                                        │   │
│  │  │       └── 缓存                                        │   │
│  │  ├── 目录存储                                           │   │
│  │  │   ├── YAML文件                                        │   │
│  │  │   ├── Git仓库                                        │   │
│  │  │   ├── 数据库                                          │   │
│  │  │   └── 外部目录                                        │   │
│  │  └── 关系管理                                           │   │
│  │      ├── 系统关系                                        │   │
│  │      ├── 依赖关系                                        │   │
│  │      ├── 所有权关系                                      │   │
│  │      └── 标签分类                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

黄金路径实现：

┌─────────────────────────────────────────────────────────────────┐
│  模板系统 (Template System)：                                │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  模板定义：                                             │   │
│  │  ├── 模板元数据                                         │   │
│  │  │   ├── name：模板名称                                 │   │
│  │  │   ├── description：描述                               │   │
│  │  │   ├── type：类型                                      │   │
│  │  │   └── tags：标签                                      │   │
│  │  ├── 模板参数                                           │   │
│  │  │   ├── required：必填参数                               │   │
│  │  │   ├── optional：可选参数                               │   │
│  │  │   ├── enum：枚举值                                    │   │
│  │  │   └── validation：验证规则                            │   │
│  │  └── 模板步骤                                           │   │
│  │      ├── fetch：获取模板                                  │   │
│  │      ├── template：渲染模板                               │   │
│  │      ├── publish：发布结果                                │   │
│  │      └── custom：自定义步骤                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  模板渲染：                                             │   │
│  │  1. 参数收集                                           │   │
│  │  │   ├── 表单渲染                                        │   │
│  │  │   ├── 参数验证                                        │   │
│  │  │   ├── 默认值填充                                      │   │
│  │  │   └── 用户确认                                        │   │
│  │  2. 模板处理                                           │   │
│  │  │   ├── 模板引擎                                        │   │
│  │  │   │   ├── Handlebars                                  │   │
│  │  │   │   ├── Nunjucks                                    │   │
│  │  │  │   └── 自定义引擎                                    │   │
│  │  │   ├── 变量替换                                        │   │
│  │  │   ├── 条件渲染                                        │   │
│  │  │   └── 循环渲染                                        │   │
│  │  3. 资源创建                                           │   │
│  │  │   ├── Git仓库创建                                     │   │
│  │  │   ├── CI/CD配置                                       │   │
│  │  │   ├── Kubernetes清单                                  │   │
│  │  │   └── 其他资源                                        │   │
│  │  4. 部署执行                                           │   │
│  │  │   ├── 触发流水线                                      │   │
│  │  │   ├── 监控部署状态                                    │   │
│  │  │   ├── 提供访问链接                                    │   │
│  │  │   └── 记录部署历史                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

自助服务架构：

┌─────────────────────────────────────────────────────────────────┐
│  服务目录 (Service Catalog)：                                 │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  服务注册：                                             │   │
│  │  ├── 服务定义                                           │   │
│  │  │   ├── 服务元数据                                      │   │
│  │  │   ├── 服务规格                                        │   │
│  │  │   ├── 服务依赖                                        │   │
│  │  │   └── 服务文档                                        │   │
│  │  ├── 服务实现                                           │   │
│  │  │   ├── Terraform模块                                  │   │
│  │  │   ├── Helm Chart                                     │   │
│  │  │   ├── Kustomize                                      │   │
│  │  │   └── 自定义脚本                                      │   │
│  │  └── 服务版本                                           │   │
│  │      ├── 版本管理                                        │   │
│  │      ├── 向后兼容                                        │   │
│  │      ├── 迁移路径                                        │   │
│  │      └── 弃用策略                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  服务交付：                                             │   │
│  │  1. 服务请求                                           │   │
│  │  │   ├── 服务浏览                                        │   │
│  │  │   ├── 服务搜索                                        │   │
│  │  │   ├── 参数配置                                        │   │
│  │  │   └── 提交请求                                        │   │
│  │  2. 审批流程                                           │   │
│  │  │   ├── 自动审批                                        │   │
│  │  │   ├── 人工审批                                        │   │
│  │  │   ├── 条件审批                                        │   │
│  │  │   └── 审批策略                                        │   │
│  │  3. 资源创建                                           │   │
│  │  │   ├── 基础设施即代码                                   │   │
│  │  │   ├── 自动化部署                                      │   │
│  │  │   ├── 状态同步                                        │   │
│  │  │   └── 错误处理                                        │   │
│  │  4. 服务交付                                           │   │
│  │  │   ├── 访问凭证                                        │   │
│  │  │   ├── 连接信息                                        │   │
│  │  │   ├── 使用文档                                        │   │
│  │  │   └── 监控指标                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  服务管理：                                             │   │
│  │  ├── 服务生命周期                                         │   │
│  │  │   ├── 创建                                            │   │
│  │  │   ├── 更新                                            │   │
│  │  │   ├── 扩缩容                                          │   │
│  │  │   ├── 备份                                            │   │
│  │  │   ├── 恢复                                            │   │
│  │  │   └── 销毁                                            │   │
│  │  ├── 服务监控                                           │   │
│  │  │   ├── 资源使用                                        │   │
│  │  │   ├── 性能指标                                        │   │
│  │  │   ├── 健康状态                                        │   │
│  │  │   └── 告警通知                                        │   │
│  │  └── 成本管理                                           │   │
│  │      ├── 成本分配                                        │   │
│  │      ├── 成本优化                                        │   │
│  │      ├── 成本预警                                        │   │
│  │      └── 成本报告                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. 实操项目

### 项目：构建内部开发者平台

```yaml
idp-implementation:

phase-1-foundation:
  infrastructure:
    - kubernetes-cluster
    - gitops-repository
    - container-registry
    
  core-services:
    - argocd
    - vault
    - external-secrets
    
phase-2-platform-services:
  observability:
    - prometheus
    - grafana
    - loki
    - tempo
    
  security:
    - kyverno
    - trivy-operator
    - falco
    
phase-3-developer-portal:
  backstage:
    plugins:
      - catalog
      - scaffolder
      - techdocs
      - kubernetes
      - argocd
      
  templates:
    - java-service
    - node-service
    - python-service
    
phase-4-self-service:
  services:
    - create-environment
    - provision-database
    - scale-service
    - view-logs
    - manage-secrets
```

---

## 7. 知识检测

### 选择题

1. 平台工程的核心目标是什么？
   - A. 增加运维工作量
   - B. 提升开发者生产力
   - C. 减少开发人员
   - D. 增加审批流程

2. 黄金路径的作用是什么？
   - A. 增加复杂性
   - B. 降低认知负担
   - C. 限制创新
   - D. 增加审批

3. 平台即产品模式中，谁是平台的客户？
   - A. 外部用户
   - B. 内部开发者
   - C. 运维团队
   - D. 管理层

---

## 8. 扩展阅读

- [Platform Engineering](https://platformengineering.org/)
- [Backstage Documentation](https://backstage.io/docs/)
- [Team Topologies](https://teamtopologies.com/)

---

## 学习进度

- [ ] 理解平台工程理念
- [ ] 掌握平台架构设计
- [ ] 学会开发者体验优化
- [ ] 掌握自助服务设计
- [ ] 理解平台运营模式
- [ ] 学会平台度量指标
- [ ] 完成实操项目
