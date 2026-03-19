# GCP DevOps实践

## 本章概述

DevOps是一种文化和方法论，旨在缩短软件交付周期、提高质量、降低风险。GCP提供完整的DevOps工具链，涵盖从代码提交到生产部署的完整流程。本章深入讲解Cloud Build持续集成、Cloud Deploy持续部署和Artifact Registry容器镜像管理的原理和实战操作，帮助你理解为什么需要这些工具，以及如何在Windows环境下完成配置。

## 学习目标

- 理解DevOps核心理念和文化
- 掌握Cloud Build流水线配置和原理
- 学会Cloud Deploy多环境部署
- 掌握Artifact Registry镜像管理
- 理解GitOps实践方法论

---

## 1. DevOps核心理念

### 1.1 为什么需要DevOps？

```
传统软件开发 vs DevOps

┌─────────────────────────────────────────────────────────────────────────┐
│                       传统软件开发模式                                    │
│                                                                         │
│  开发 ──────> 测试 ──────> 部署 ──────> 运维                            │
│                                                                         │
│  问题：                                                                 │
│  - 开发、测试、运维各自为政                                              │
│  - 部署周期长（数周甚至数月）                                           │
│  - 部署风险高，每次发布都是冒险                                         │
│  - 问题定位困难，运维不了解代码                                         │
│  - 难以快速响应业务变化                                                 │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                           DevOps模式                                      │
│                                                                         │
│  <─────────────────────────────────────────────────────────────────>   │
│                    持续集成 / 持续交付 / 持续部署                         │
│                                                                         │
│  开发 ──> 构建 ──> 测试 ──> 预发布 ──> 生产                             │
│    ^                                                              │     │
│    └──────────────────────────────────────────────────────────────┘     │
│                                                                         │
│  优势：                                                                 │
│  - 自动化整个流程                                                      │
│  - 快速迭代（每天甚至每小时发布）                                       │
│  - 降低部署风险                                                        │
│  - 快速发现问题                                                        │
│  - 持续改进                                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 DevOps成熟度模型

```
DevOps成熟度

┌─────────────────────────────────────────────────────────────────────────┐
│                        DevOps成熟度级别                                  │
│                                                                         │
│  Level 1: 初始级                                                       │
│  - 手动部署                                                            │
│  - 无自动化测试                                                        │
│  - 缺乏监控                                                            │
│                                                                         │
│  Level 2: 可重复级                                                     │
│  - 自动化构建                                                          │
│  - 基本自动化测试                                                      │
│  - 基础监控                                                            │
│                                                                         │
│  Level 3: 已定义级                                                     │
│  - CI/CD流水线                                                         │
│  - 自动化部署                                                          │
│  - 持续监控                                                            │
│                                                                         │
│  Level 4: 已管理级                                                     │
│  - 完整的DevOps流水线                                                  │
│  - 自动化安全扫描                                                      │
│  - 性能监控                                                            │
│                                                                         │
│  Level 5: 优化级                                                       │
│  - 持续优化                                                            │
│  - A/B测试                                                             │
│  - 自动化修复                                                          │
│  - 预测分析                                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Cloud Build持续集成

### 2.1 理解Cloud Build的工作原理

```
Cloud Build持续集成流程

┌─────────────────────────────────────────────────────────────────────────┐
│                    完整的CI/CD流程                                        │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    1. 代码提交 (Code Commit)                     │   │
│  │                                                                  │   │
│  │  GitHub / GitLab / Cloud Source Repositories                   │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    2. 触发构建 (Trigger Build)                   │   │
│  │                                                                  │   │
│  │  Push / Pull Request / Schedule / Manual                       │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    3. 执行构建步骤 (Build Steps)                  │   │
│  │                                                                  │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │   │
│  │  │ 检出代码 │  │ 依赖安装 │  │ 编译构建 │  │ 运行测试 │           │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    4. 安全扫描 (Security Scan)                    │   │
│  │                                                                  │   │
│  │  Container Analysis / Binary Authorization                      │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    5. 镜像推送 (Image Push)                      │   │
│  │                                                                  │   │
│  │  Artifact Registry / Container Registry                         │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    6. 部署 (Deployment)                          │   │
│  │                                                                  │   │
│  │  Cloud Run / GKE / Compute Engine                                │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Cloud Build详解 - 为什么需要它？

**核心价值：**

```
Cloud Build解决的问题

┌─────────────────────────────────────────────────────────────────────────┐
│                    为什么需要Cloud Build？                               │
│                                                                         │
│  1. 自动化构建                                                          │
│     ├── 消除手动构建的错误                                              │
│     ├── 确保构建一致性                                                  │
│     └── 节省时间                                                        │
│                                                                         │
│  2. 可追溯性                                                            │
│     ├── 每次构建都有记录                                                │
│     ├── 便于问题定位                                                    │
│     └── 审计追踪                                                        │
│                                                                         │
│  3. 安全性                                                              │
│     ├── 隔离的执行环境                                                  │
│     ├── 敏感信息管理                                                   │
│     └── 合规性                                                          │
│                                                                         │
│  4. 可扩展性                                                            │
│     ├── 按需分配资源                                                    │
│     ├── 并行执行                                                        │
│     └── 成本优化                                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Cloud Build配置 - Windows PowerShell

```powershell
# ============================================================
# Cloud Build操作 - Windows PowerShell
# ============================================================

# ========== 1. 启用Cloud Build ==========

gcloud services enable cloudbuild.googleapis.com

# ========== 2. 创建构建触发器 ==========

# 创建GitHub Push触发器
gcloud builds triggers create github `
    --repo-name=my-repo `
    --repo-owner=my-owner `
    --branch-pattern="^main$" `
    --build-config=cloudbuild.yaml `
    --description="Build on main branch push"

# 创建Pull Request触发器
gcloud builds triggers create github `
    --repo-name=my-repo `
    --repo-owner=my-owner `
    --pull-request-pattern="^.*$" `
    --build-config=cloudbuild.yaml `
    --description="Build on PR"

# 创建定时触发器（每天凌晨2点）
gcloud builds triggers create schedule `
    --name=daily-build `
    --schedule="0 2 * * *" `
    --build-config=cloudbuild.yaml `
    --description="Daily build at 2 AM"

# 列出触发器
gcloud builds triggers list

# 查看触发器详情
gcloud builds triggers describe TRIGGER_NAME

# 删除触发器
gcloud builds triggers delete TRIGGER_NAME

# ========== 3. 手动触发构建 ==========

# 使用提交SHA触发
gcloud builds submit --config=cloudbuild.yaml .

# 使用 substitutions 变量
gcloud builds submit --config=cloudbuild.yaml . `
    --substitutions _VERSION=1.0.0,_ENV=production

# 查看构建历史
gcloud builds list --limit=10

# 查看特定构建详情
gcloud builds describe BUILD_ID

# 获取构建日志
gcloud builds log BUILD_ID

# ========== 4. Worker Pool（私有构建环境）==========
# 创建私有Worker Pool
gcloud builds worker-pools create my-pool `
    --region=us-central1 `
    --machine-type=e2-standard-4 `
    --disk-size=100GB

# 配置使用私有Worker Pool
# 在cloudbuild.yaml中添加：
# options:
#   workerPool: projects/PROJECT_ID/locations/us-central1/workerPools/my-pool
```

### 2.4 cloudbuild.yaml配置详解

```yaml
# cloudbuild.yaml - 完整配置示例
# ============================================================
# 原理说明：
# cloudbuild.yaml 是 Cloud Build 的配置文件
# 定义了构建的步骤、环境变量、工作目录等
# ============================================================

# 替换变量
substitutions:
  _VERSION: "1.0.0"
  _ENV: "production"
  _SERVICE_NAME: "my-app"

# 选项配置
options:
  # 日志选项
  logging: CLOUD_LOGGING_ONLY
  
  # 超时时间（最大60分钟）
  timeout: 1800s
  
  # 环境变量
  env:
    - NODE_ENV=production
  
  # 替代Dockerfile构建
  # dockerImage: gcr.io/cloud-builders/docker

# 可用机器类型
# e2-medium (默认), e2-standard-4, n1-highmem-8 等

# 构建步骤
steps:
  # ============================================================
  # 步骤1: 安装依赖
  # ============================================================
  - name: 'gcr.io/cloud-builders/npm'
    args: ['install']
    env: ['NODE_ENV=${_ENV}']
    id: 'install-dependencies'
    entrypoint: 'npm'
  
  # ============================================================
  # 步骤2: 代码检查
  # ============================================================
  - name: 'gcr.io/cloud-builders/npm'
    args: ['run', 'lint']
    env: ['NODE_ENV=${_ENV}']
    id: 'code-lint'
    entrypoint: 'npm'
  
  # ============================================================
  # 步骤3: 运行测试
  # ============================================================
  - name: 'gcr.io/cloud-builders/npm'
    args: ['test', '--', '--coverage', '--passWithNoTests']
    env: ['NODE_ENV=test']
    id: 'run-tests'
    entrypoint: 'npm'
  
  # ============================================================
  # 步骤4: 构建应用
  # ============================================================
  - name: 'gcr.io/cloud-builders/npm'
    args: ['run', 'build']
    env: ['NODE_ENV=${_ENV}']
    id: 'build-app'
    entrypoint: 'npm'
  
  # ============================================================
  # 步骤5: 构建Docker镜像
  # ============================================================
  - name: 'gcr.io/cloud-builders/docker'
    args: [
      'build',
      '-t', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${_VERSION}',
      '-t', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:latest',
      '-t', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${SHORT_SHA}',
      '.'
    ]
    id: 'build-docker-image'
  
  # ============================================================
  # 步骤6: 漏洞扫描（可选）
  # ============================================================
  - name: 'gcr.io/cloud-builders/docker'
    args: [
      'run', '--rm',
      '-v', '/workspace:/workspace',
      'aquasec/trivy:latest',
      'image',
      '--severity', 'CRITICAL,HIGH',
      '--exit-code', '1',
      '--ignore-unfixed',
      'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${_VERSION}'
    ]
    id: 'vulnerability-scan'
  
  # ============================================================
  # 步骤7: 推送镜像
  # ============================================================
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${_VERSION}']
    id: 'push-version'
  
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:latest']
    id: 'push-latest'
  
  # ============================================================
  # 步骤8: 部署到Cloud Run
  # ============================================================
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args: [
      'run', 'deploy',
      '${_SERVICE_NAME}',
      '--image', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${_VERSION}',
      '--region', 'us-central1',
      '--platform', 'managed',
      '--allow-unauthenticated',
      '--set-env-vars', 'VERSION=${_VERSION},ENV=${_ENV}'
    ]
    id: 'deploy-cloud-run'

# 镜像
images:
  - 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${_VERSION}'
  - 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:latest'

# 等待触发的构建完成
# timeout: 1800s

# tags用于过滤日志
tags:
  - '${_SERVICE_NAME}'
  - 'build'
  - '${_ENV}'
```

---

## 3. Cloud Deploy持续部署

### 3.1 理解Cloud Deploy的工作原理

**为什么需要Cloud Deploy？**

```
传统部署 vs Cloud Deploy

┌─────────────────────────────────────────────────────────────────────────┐
│                       传统部署方式                                        │
│                                                                         │
│  手动部署流程：                                                         │
│                                                                         │
│  开发 ──> 手动打包 ──> 手动上传 ──> 手动部署 ──> 验证                   │
│       │                                    │                           │
│       │                                    ▼                           │
│       │                              手动回滚困难                       │
│       │                                                                     │
│       └────────────── 容易出错，版本混乱 ◄──────────────┘               │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    Cloud Deploy 部署方式                                 │
│                                                                         │
│  自动化部署流程：                                                       │
│                                                                         │
│  代码 ──> 构建 ──> 推广 ──> 验证 ──> 完成                              │
│       │         │                                                      │
│       │         ▼                                                      │
│       │    分阶段推广                                                   │
│       │    (canary 10% -> 50% -> 100%)                                 │
│       │                                                      │
│       │         ▼                                                      │
│       │    一键回滚（秒级）                                            │
│       │                                                      │
│       └────────────── 可追溯，可控制 ◄──────────────┘                   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Cloud Deploy核心概念

```
Cloud Deploy架构

┌─────────────────────────────────────────────────────────────────────────┐
│                    Cloud Deploy 核心概念                                │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    交付流水线 (Delivery Pipeline)                 │   │
│  │   定义部署流程：dev -> staging -> production                     │   │
│  │                                                                  │   │
│  │   ┌─────────┐    ┌─────────┐    ┌─────────┐                   │   │
│  │   │  Dev    │───>│ Staging │───>│   Prod  │                   │   │
│  │   │ 开发环境 │    │ 预发布  │    │ 生产环境 │                   │   │
│  │   └─────────┘    └─────────┘    └─────────┘                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    发布 (Release)                                 │   │
│  │   特定版本的配置和清单                                           │   │
│  │   - Skaffold配置                                                │   │
│  │   - Kubernetes manifests                                        │   │
│  │   - Helm charts                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    目标 (Target)                                  │   │
│  │   部署的目标环境                                                 │   │
│  │   - GKE集群                                                     │   │
│  │   - Cloud Run服务                                               │   │
│  │   - Anthos集群                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    推广 (Rollout)                                 │   │
│  │   在目标环境创建资源的过程                                       │   │
│  │   支持：金丝雀、蓝绿、滚动更新                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Cloud Deploy操作 - Windows PowerShell

```powershell
# ============================================================
# Cloud Deploy操作 - Windows PowerShell
# ============================================================

# ========== 1. 启用Cloud Deploy ==========

gcloud services enable deploy.googleapis.com

# ========== 2. 创建Skaffold配置 ==========
# Skaffold是Cloud Deploy的配置文件格式

# 创建基本的skaffold.yaml
@"
apiVersion: skaffold/v4beta1
kind: Config
build:
  artifacts:
    - image: gcr.io/`$PROJECT_ID/my-app
      docker:
        dockerfile: Dockerfile
deploy:
  kubectl:
    manifests:
      - manifests/*.yaml
"@ | Out-File -FilePath skaffold.yaml -Encoding UTF8

# ========== 3. 创建Cloud Deploy流水线配置 ==========

# 创建delivery-pipeline.yaml
@"
apiVersion: deploy.googleapis.com/v1
kind: DeliveryPipeline
metadata:
  name: my-app-pipeline
  description: My application delivery pipeline
spec:
  id: my-app-pipeline
  stages:
    - targetId: dev
      profiles: []
    - targetId: staging
      profiles: []
    - targetId: production
      profiles: []
"@ | Out-File -FilePath delivery-pipeline.yaml -Encoding UTF8

# ========== 4. 创建目标环境配置 ==========

# 创建targets/dev.yaml
@"
apiVersion: deploy.googleapis.com/v1
kind: Target
metadata:
  name: dev
spec:
  run:
    location: projects/`$PROJECT_ID/locations/us-central1
  executionTimeout: 600s
"@ | Out-File -FilePath targets/dev.yaml -Encoding UTF8

# 创建targets/production.yaml
@"
apiVersion: deploy.googleapis.com/v1
kind: Target
metadata:
  name: production
spec:
  run:
    location: projects/`$PROJECT_ID/locations/us-central1
  executionTimeout: 1800s
"@ | Out-File -FilePath targets/production.yaml -Encoding UTF8

# ========== 5. 应用配置 ==========

# 注册流水线
gcloud deploy apply --file=delivery-pipeline.yaml

# 注册目标环境
gcloud deploy apply --file=targets/dev.yaml
gcloud deploy apply --file=targets/production.yaml

# ========== 6. 创建发布 ==========

# 创建发布（会自动部署到第一个阶段）
gcloud deploy releases create release-001 `
    --delivery-pipeline=my-app-pipeline `
    --skaffold-file=skaffold.yaml

# ========== 7. 管理发布 ==========

# 列出所有发布
gcloud deploy releases list --delivery-pipeline=my-app-pipeline

# 查看发布详情
gcloud deploy releases describe release-001 `
    --delivery-pipeline=my-app-pipeline

# ========== 8. 推广 ==========

# 手动推广到下一阶段
gcloud deploy releases promote `
    --release=release-001 `
    --delivery-pipeline=my-app-pipeline `
    --to-target=staging

# ========== 9. 回滚 ==========

# 回滚到之前的版本
gcloud deploy rollouts undo release-001 `
    --delivery-pipeline=my-app-pipeline `
    --phase-id=production

# ========== 10. 查看状态 ==========

# 查看部署状态
gcloud deploy rollouts list `
    --release=release-001 `
    --delivery-pipeline=my-app-pipeline

# 查看特定部署详情
gcloud deploy rollouts describe rollout-001 `
    --release=release-001 `
    --delivery-pipeline=my-app-pipeline
```

---

## 4. Artifact Registry

### 4.1 理解Artifact Registry的作用

```
为什么需要Artifact Registry？

┌─────────────────────────────────────────────────────────────────────────┐
│                    镜像管理的重要性                                       │
│                                                                         │
│  问题：                                                                 │
│  1. 镜像存储在哪里？                                                     │
│     - 分散在各个服务器                                                  │
│     - 难以管理                                                          │
│                                                                         │
│  2. 版本如何控制？                                                       │
│     - 手动命名，容易混乱                                                │
│     - 无法追踪                                                          │
│                                                                         │
│  3. 访问如何控制？                                                       │
│     - 谁可以下载镜像？                                                  │
│     - 敏感镜像如何保护？                                                │
│                                                                         │
│  4. 性能如何优化？                                                       │
│     - 拉取速度                                                          │
│     - 全球分发                                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    Artifact Registry 解决方案                           │
│                                                                         │
│  1. 集中存储                                                            │
│     └── 一个地方管理所有镜像                                             │
│                                                                         │
│  2. 版本控制                                                            │
│     └── 自动版本标记，保留历史                                           │
│                                                                         │
│  3. 访问控制                                                            │
│     └── IAM精确控制                                                     │
│                                                                         │
│  4. 性能优化                                                            │
│     └── 全球分布式CDN                                                   │
│                                                                         │
│  5. 漏洞扫描                                                            │
│     └── 自动发现安全问题                                                 │
│                                                                         │
│  6. 依赖扫描                                                            │
│     └── 扫描依赖漏洞                                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Artifact Registry操作 - Windows PowerShell

```powershell
# ============================================================
# Artifact Registry操作 - Windows PowerShell
# ============================================================

# ========== 1. 启用Artifact Registry ==========

gcloud services enable artifactregistry.googleapis.com

# ========== 2. 创建Docker仓库 ==========

gcloud artifacts repositories create my-docker-repo `
    --repository-format=docker `
    --location=us-central1 `
    --description="My Docker repository"

# 创建Maven仓库（Java依赖）
gcloud artifacts repositories create my-maven-repo `
    --repository-format=maven `
    --location=us-central1 `
    --description="My Maven repository"

# 创建npm仓库
gcloud artifacts repositories create my-npm-repo `
    --repository-format=npm `
    --location=us-central1 `
    --description="My npm repository"

# 列出仓库
gcloud artifacts repositories list

# 查看仓库详情
gcloud artifacts repositories describe my-docker-repo --location=us-central1

# ========== 3. 配置Docker认证 ==========

# 为Docker配置Artifact Registry认证
gcloud auth configure-docker us-central1-docker.pkg.dev

# 手动配置（如果上面命令不工作）
# 创建Docker配置
@"
{
  "credHelpers": {
    "us-central1-docker.pkg.dev": "gcloud"
  }
}
"@ | Out-File -Path "$env:USERPROFILE/.docker/config.json" -Encoding UTF8

# ========== 4. 推送镜像 ==========

# 标记镜像
docker tag my-app:latest us-central1-docker.pkg.dev/PROJECT_ID/my-docker-repo/my-app:latest

# 推送镜像
docker push us-central1-docker.pkg.dev/PROJECT_ID/my-docker-repo/my-app:latest

# 推送多架构镜像
docker buildx build --push `
    --platform linux/amd64,linux/arm64 `
    -t us-central1-docker.pkg.dev/PROJECT_ID/my-docker-repo/my-app:latest .

# ========== 5. 拉取镜像 ==========

docker pull us-central1-docker.pkg.dev/PROJECT_ID/my-docker-repo/my-app:latest

# ========== 6. 版本管理 ==========

# 列出镜像版本
gcloud artifacts versions list `
    --package=my-app `
    --repository=my-docker-repo `
    --location=us-central1

# 删除镜像版本
gcloud artifacts versions delete my-app-version `
    --package=my-app `
    --repository=my-docker-repo `
    --location=us-central1

# ========== 7. 访问控制 ==========

# 授予读取权限
gcloud artifacts repositories add-iam-policy-binding my-docker-repo `
    --location=us-central1 `
    --member=user:dev@example.com `
    --role=roles/artifactregistry.reader

# 授予写入权限
gcloud artifacts repositories add-iam-policy-binding my-docker-repo `
    --location=us-central1 `
    --member=serviceAccount:build@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/artifactregistry.writer

# 授予管理员权限
gcloud artifacts repositories add-iam-policy-binding my-docker-repo `
    --location=us-central1 `
    --member=group:admins@example.com `
    --role=roles/artifactregistry.admin

# ========== 8. 漏洞扫描 ==========

# 查看镜像漏洞
gcloud artifacts docker images list us-central1-docker.pkg.dev/PROJECT_ID/my-docker-repo

# 获取漏洞报告
gcloud artifacts docker images describe us-central1-docker.pkg.dev/PROJECT_ID/my-docker-repo/my-app:latest --show-package-vulnerabilities

# ========== 9. 清理 ==========

# 删除仓库（谨慎操作）
gcloud artifacts repositories delete my-docker-repo --location=us-central1 --async
```

---

## 5. GitOps实践

### 5.1 什么是GitOps？

```
GitOps工作流程

┌─────────────────────────────────────────────────────────────────────────┐
│                       GitOps 核心理念                                    │
│                                                                         │
│  1. 基础设施即代码 (Infrastructure as Code)                              │
│     └── 所有配置存储在Git中                                              │
│                                                                         │
│  2. 声明式配置 (Declarative Configuration)                              │
│     └── 定义"什么"而非"如何"                                             │
│                                                                         │
│  3. 单一事实来源 (Single Source of Truth)                                │
│     └── Git是期望状态的唯一来源                                          │
│                                                                         │
│  4. 自动同步 (Automatic Synchronization)                                │
│     └── 自动将Git中的变更应用到集群                                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    GitOps 工作流程                                       │
│                                                                         │
│  1. 开发者在Git中提交变更                                                │
│     └── 修改Kubernetes manifests或Helm charts                          │
│                                                                         │
│  2. CI流水线触发                                                        │
│     └── 构建镜像，推送到Artifact Registry                                │
│                                                                         │
│  3. CD工具检测变更                                                       │
│     └── Config Sync / Argo CD / Flux                                   │
│                                                                         │
│  4. 自动部署到集群                                                       │
│     └── 比较Git状态与集群状态，自动同步                                 │
│                                                                         │
│  5. 集群状态反馈                                                         │
│     └── 验证部署成功                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 GitOps工具配置

```powershell
# ============================================================
# GitOps工具配置 - Windows PowerShell
# ============================================================

# ========== 1. 安装Config Sync (GKE场景) ==========

# 在GKE集群上启用Config Sync
gcloud container clusters update my-cluster `
    --enable-config-sync `
    --config-sync-namespace=config-management-system

# 配置Config Sync
@"
apiVersion: configmanagement.gke.io/v1
kind: ConfigSync
metadata:
  name: config-management
spec:
  git:
    repo: https://github.com/my-org/my-configs
    branch: main
    dir: ""
    auth: token
    token: SECRET_TOKEN
"@ | Out-File -FilePath config-sync.yaml -Encoding UTF8

# 应用配置
kubectl apply -f config-sync.yaml

# ========== 2. 安装Argo CD（非GKE场景） ==========

# 创建命名空间
kubectl create namespace argocd

# 安装Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 获取初始密码
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# 暴露Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# ========== 3. 创建Argo CD应用 ==========

@"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app-configs
    targetRevision: HEAD
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
"@ | Out-File -FilePath argo-app.yaml -Encoding UTF8

# 应用应用配置
kubectl apply -f argo-app.yaml
```

---

## 6. 完整CI/CD流水线示例

### 6.1 端到端流水线架构

```
完整CI/CD架构

┌─────────────────────────────────────────────────────────────────────────┐
│                    完整CI/CD流水线架构                                    │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    代码管理 (Code Management)                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │   │
│  │  │ Source     │  │ Pull        │  │ Merge      │              │   │
│  │  │ Repository │  │ Request    │  │ to Main   │              │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    持续集成 (Continuous Integration)              │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐              │   │
│  │  │ Build   │  │  Test   │  │  Scan   │  │  Tag   │              │   │
│  │  │ 编译构建 │  │ 单元测试 │  │ 安全扫描 │  │ 版本标记 │              │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    镜像管理 (Image Management)                     │   │
│  │  ┌─────────────────────────────────────────────────────────┐     │   │
│  │  │              Artifact Registry                           │     │   │
│  │  │  - 存储镜像                                               │     │   │
│  │  │  - 版本管理                                               │     │   │
│  │  │  - 漏洞扫描                                               │     │   │
│  │  └─────────────────────────────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    持续部署 (Continuous Deployment)                │   │
│  │                                                                  │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐                     │   │
│  │  │  Dev    │───>│ Staging │───>│   Prod  │                     │   │
│  │  │ 自动部署 │    │ 手动门禁 │    │ 金丝雀   │                     │   │
│  │  └─────────┘    └─────────┘    └─────────┘                     │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    监控与反馈 (Monitoring & Feedback)              │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐              │   │
│  │  │ Metrics │  │ Logs    │  │ Alerts  │  │ Rollback│              │   │
│  │  │ 指标    │  │ 日志    │  │ 告警    │  │ 自动回滚│              │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 最佳实践总结

```
CI/CD最佳实践

┌─────────────────────────────────────────────────────────────────────────┐
│                    CI/CD 最佳实践                                         │
│                                                                         │
│  构建优化：                                                             │
│  ├── 使用缓存减少构建时间                                               │
│  ├── 并行执行独立步骤                                                   │
│  └── 最小化镜像大小                                                     │
│                                                                         │
│  测试最佳实践：                                                         │
│  ├── 单元测试覆盖核心逻辑                                               │
│  ├── 集成测试验证组件协作                                              │
│  ├── 端到端测试验证完整流程                                            │
│  └── 性能测试确保响应时间                                               │
│                                                                         │
│  安全最佳实践：                                                         │
│  ├── 依赖漏洞扫描                                                       │
│  ├── 镜像漏洞扫描                                                       │
│  ├── 容器最佳实践扫描                                                   │
│  └── 敏感信息不打包进镜像                                              │
│                                                                         │
│  部署最佳实践：                                                         │
│  ├── 使用金丝雀部署降低风险                                             │
│  ├── 保持向后兼容                                                       │
│  ├── 快速回滚能力                                                       │
│  └── 监控部署后的指标                                                   │
│                                                                         │
│  Git最佳实践：                                                         │
│  ├── 使用Feature Branch开发                                            │
│  ├── 代码审查合并                                                        │
│  ├── 小而频繁的提交                                                     │
│  └── 清晰的提交信息                                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.3 Cloud Build底层执行原理

**Cloud Build是怎么实现隔离构建的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              Cloud Build执行架构                                  │
└─────────────────────────────────────────────────────────────────┘

Cloud Build使用Google Cloud的高性能网络和计算资源执行构建

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  构建请求 ──→ Cloud Build API                                    │
│                     │                                            │
│                     ▼                                            │
│         ┌─────────────────────────┐                             │
│         │  Build Request Manager │                             │
│         │    (管理构建请求队列)    │                             │
│         └───────────┬─────────────┘                             │
│                     │                                            │
│         ┌───────────▼─────────────┐                             │
│         │   Worker Pool           │                             │
│         │  (隔离的构建环境)        │                             │
│         │                         │                             │
│         │  ┌─────┐  ┌─────┐  ┌─────┐                           │
│         │  │ VM1 │  │ VM2 │  │ VMn │  ← 每次构建一个VM        │
│         │  │  n-1 │  │  n-2 │  │  ... │                           │
│         │  └─────┘  └─────┘  └─────┘                           │
│         │                         │                             │
│         └───────────────────────────┘                             │
│                       │                                           │
│                       ▼                                           │
│         ┌─────────────────────────┐                             │
│         │   Result Aggregator    │                             │
│         │     (聚合构建结果)       │                             │
│         └─────────────────────────┘                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

隔离构建环境（Secure Build）：

┌─────────────────────────────────────────────────────────────────┐
│  为什么需要隔离？                                                │
│                                                                  │
│  1. 防止构建之间的相互影响                                       │
│  2. 防止未授权访问其他项目的资源                                 │
│  3. 确保构建可重复性                                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Cloud Build VMs特性：                                          │
│                                                                  │
│  - 每次构建使用新的VM（干净环境）                               │
│  - VM生命周期 = 构建生命周期                                    │
│  - 构建完成后VM销毁                                              │
│  - 网络隔离（只能访问配置的VPC或互联网）                       │
│  - 服务账号权限控制                                              │
└─────────────────────────────────────────────────────────────────┘

构建缓存机制：

┌─────────────────────────────────────────────────────────────────┐
│  本地缓存（Local Cache）                                        │
│                                                                  │
│  在同一个构建中复用之前步骤的产物                                 │
│                                                                  │
│  steps:                                                         │
│  - name: 'docker:latest'                                       │
│    entrypoint: 'docker'                                         │
│    args: ['build', '-t', 'image', '.']                         │
│    id: 'build'                                                 │
│                                                                  │
│  - name: 'docker:latest'                                       │
│    entrypoint: 'docker'                                         │
│    args: ['push', 'image']                                     │
│    waitFor: ['build']  ← 等待build步骤完成                     │
│                                                                  │
│  问题：跨构建无法复用                                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  远程缓存（Remote Cache）                                        │
│                                                                  │
│  缓存层（Artifact Registry）                                    │
│       ▲                                        ▲                │
│       │                                        │                │
│  ┌────┴────┐                             ┌────┴────┐           │
│  │ Build 1 │                             │ Build 2 │           │
│  │ 缓存miss│                             │ 缓存hit │           │
│  └─────────┘                             └─────────┘           │
│                                                                  │
│  配置：                                                          │
│  buildArgs:                                                    │
│    CACHE: 'projects/$PROJECT_ID/locations/us/cache/ache_name' │
│                                                                  │
│  效果：依赖安装等步骤可跳过，显著加速构建                      │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Cloud Deploy金丝雀部署原理

**Cloud Deploy是怎么实现金丝雀部署的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              Cloud Deploy部署流程                                 │
└─────────────────────────────────────────────────────────────────┘

Cloud Deploy使用Skaffold作为核心，自动化Kubernetes部署

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Skaffold工作流：                                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    skaffold.yaml                         │   │
│  │                                                          │   │
│  │  apiVersion: skaffold/v4                                 │   │
│  │  kind: Config                                             │   │
│  │  manifests:                                               │   │
│  │    kustomize:                                             │   │
│  │      paths:                                               │   │
│  │      - overlays/$ENV                                      │   │
│  │  deploy:                                                  │   │
│  │    kubectl: {}                                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

部署流程图解：

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Phase 1: 准备阶段                                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. Skaffold读取配置文件                                  │   │
│  │  2. 生成manifests（Kustomize/Helm）                     │   │
│  │  3. 创建Deployment/Service等资源                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  Phase 2: 金丝雀部署                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 更新主版本Deployment（保持旧版本）                   │   │
│  │  2. 创建金丝雀Deployment（新品版）                       │   │
│  │  3. Service同时指向两个版本                              │   │
│  │  4. 初始流量：金丝雀5%，主版本95%                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  Phase 3: 监控和判断                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 分析错误率、延迟、成功率等指标                       │   │
│  │  2. 达到阈值 → 自动提升                                 │   │
│  │  3. 未达标 → 自动回滚                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  Phase 4: 完成部署                                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 金丝雀版本100%流量                                   │   │
│  │  2. 删除旧版本Deployment                                │   │
│  │  3. 新版本成为"主版本"                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

金丝雀配置示例（Skaffold + Kustomize）：

┌─────────────────────────────────────────────────────────────────┐
│  overlays/production/kustomization.yaml                        │
│                                                                  │
│  apiVersion: kustomize.config.k8s.io/v1beta1                   │
│  kind: Kustomization                                            │
│  bases:                                                         │
│  - ../../base                                                   │
│  patches:                                                       │
│  - patch.yaml                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  overlays/production/patch.yaml                                 │
│                                                                  │
│  apiVersion: apps/v1                                            │
│  kind: Deployment                                               │
│  metadata:                                                      │
│  name: my-app                                                   │
│  spec:                                                          │
│  replicas: 10                                                   │
│  strategy:                                                     │
│    type: RollingUpdate                                          │
│    rollingUpdate:                                               │
│      maxSurge: 2                                                │
│      maxUnavailable: 0                                         │
│                                                                  │
│  说明：                                                          │
│  - maxSurge: 最多超出20%个实例（10+2=12）                      │
│  - maxUnavailable: 0表示零停机更新                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Windows PowerShell命令速查

```powershell
# ============================================================
# DevOps命令速查
# ============================================================

# ---------- Cloud Build ----------
# 启用服务
gcloud services enable cloudbuild.googleapis.com

# 手动触发构建
gcloud builds submit --config=cloudbuild.yaml .

# 列出构建
gcloud builds list --limit=10

# 查看构建日志
gcloud builds log BUILD_ID

# ---------- Cloud Deploy ----------
# 启用服务
gcloud services enable deploy.googleapis.com

# 创建发布
gcloud deploy releases create RELEASE_NAME --delivery-pipeline=PIPELINE_NAME --skaffold-file=skaffold.yaml

# 推广
gcloud deploy releases promote --release=RELEASE_NAME --delivery-pipeline=PIPELINE_NAME --to-target=TARGET

# 回滚
gcloud deploy rollouts undo RELEASE_NAME --delivery-pipeline=PIPELINE_NAME --phase-id=TARGET

# ---------- Artifact Registry ----------
# 创建仓库
gcloud artifacts repositories create REPO --repository-format=docker --location=LOCATION

# 配置认证
gcloud auth configure-docker LOCATION-docker.pkg.dev

# 推送镜像
docker push LOCATION-docker.pkg.dev/PROJECT_ID/REPO/IMAGE:TAG

# 拉取镜像
docker pull LOCATION-docker.pkg.dev/PROJECT_ID/REPO/IMAGE:TAG

# 列出镜像
gcloud artifacts repositories list
```

---

## 8. 知识检测

### 选择题

1. Cloud Build主要用于什么场景？
   - A. 代码存储
   - B. 持续集成 ✓
   - C. 日志分析
   - D. 监控告警

2. Cloud Deploy的核心概念中，什么是"Target"？
   - A. 部署的源代码
   - B. 部署的目标环境 ✓
   - C. 部署的用户
   - D. 部署的时间

3. Artifact Registry的主要优势是什么？
   - A. 完全免费
   - B. 集中管理和漏洞扫描 ✓
   - C. 只支持Docker
   - D. 无法访问控制

4. GitOps的核心原则是什么？
   - A. 手动部署
   - B. Git作为唯一事实来源 ✓
   - C. 不使用配置文件
   - D. 每周发布一次

---

## 学习进度

- [ ] 理解DevOps核心理念
- [ ] 掌握Cloud Build流水线
- [ ] 学会Cloud Deploy部署
- [ ] 掌握Artifact Registry
- [ ] 理解GitOps实践
- [ ] 完成实战项目
