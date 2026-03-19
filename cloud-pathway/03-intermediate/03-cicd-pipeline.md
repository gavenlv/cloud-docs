# CI/CD流水线

## 本章概述

CI/CD是现代软件开发的核心实践。本章将学习构建完整的持续集成和持续部署流水线。

## 学习目标

- 理解CI/CD核心概念
- 掌握Git版本控制最佳实践
- 学会Jenkins流水线配置
- 掌握GitHub Actions
- 了解GitOps与ArgoCD
- 能够构建完整CI/CD流程

---

## 1. CI/CD核心概念

### 1.1 什么是CI/CD

```
CI/CD流程

┌─────────────────────────────────────────────────────────────────────────┐
│                           持续集成 (CI)                                  │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐                │
│  │  代码    │──►│  构建   │──►│  测试   │──►│  分析   │                │
│  │  提交    │   │        │   │        │   │        │                │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘                │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           持续部署 (CD)                                  │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐                │
│  │  制品    │──►│  部署   │──►│  验证   │──►│  监控   │                │
│  │  管理    │   │        │   │        │   │        │                │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘                │
└─────────────────────────────────────────────────────────────────────────┘

CI (持续集成)：
- 频繁集成代码
- 自动化构建
- 自动化测试
- 代码质量检查

CD (持续部署/交付)：
- 自动化部署
- 环境一致性
- 快速反馈
- 回滚机制
```

### 1.2 CI/CD工具对比

| 工具 | 类型 | 特点 | 适用场景 |
|-----|------|------|---------|
| Jenkins | 自托管 | 插件丰富、灵活 | 企业级、复杂流水线 |
| GitHub Actions | 云托管 | 与GitHub深度集成 | GitHub项目 |
| GitLab CI | 自托管/云 | 内置GitLab | GitLab用户 |
| CircleCI | 云托管 | 配置简单 | 中小团队 |
| ArgoCD | GitOps | K8s原生 | Kubernetes部署 |

---

## 2. Git最佳实践

### 2.1 分支策略

```
Git Flow分支策略

                    master (生产)
                       │
                       │
    ┌──────────────────┼──────────────────┐
    │                  │                  │
    │                  │                  │
   v1.0              v2.0              v3.0
    │                  │                  │
    │                  │                  │
    └──────────────────┼──────────────────┘
                       │
                    develop (开发)
                       │
        ┌──────────────┼──────────────┐
        │              │              │
    feature/a     feature/b      feature/c
        │              │              │

分支类型：
├── master/main    生产环境代码
├── develop        开发分支
├── feature/*      功能分支
├── release/*      发布分支
├── hotfix/*       紧急修复
└── bugfix/*       缺陷修复
```

### 2.2 提交规范

```
提交消息格式

<type>(<scope>): <subject>

<body>

<footer>

类型(type)：
├── feat:     新功能
├── fix:      修复bug
├── docs:     文档更新
├── style:    代码格式
├── refactor: 重构
├── test:     测试
├── chore:    构建/工具
└── perf:     性能优化

示例：
feat(api): add user authentication

- Add login endpoint
- Add JWT token validation
- Add password hashing

Closes #123
```

### 2.3 Git钩子

```bash
.husky/pre-commit

#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npm run lint
npm run test:unit
```

```bash
.husky/commit-msg

#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx --no -- commitlint --edit "$1"
```

---

## 3. Jenkins流水线

### 3.1 流水线语法

```groovy
Jenkinsfile

pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'my-app'
        DOCKER_TAG = "${env.BUILD_ID}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm run test:coverage'
            }
            post {
                always {
                    junit 'coverage/junit.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    docker.withRegistry('https://registry.example.com', 'docker-credentials') {
                        def app = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        app.push()
                        app.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh "kubectl set image deployment/my-app my-app=${DOCKER_IMAGE}:${DOCKER_TAG} -n staging"
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sh "kubectl set image deployment/my-app my-app=${DOCKER_IMAGE}:${DOCKER_TAG} -n production"
            }
        }
    }
    
    post {
        success {
            slackSend(
                color: 'good',
                message: "Build ${env.JOB_NAME} #${env.BUILD_NUMBER} succeeded!"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "Build ${env.JOB_NAME} #${env.BUILD_NUMBER} failed!"
            )
        }
    }
}
```

### 3.2 多分支流水线

```groovy
Jenkinsfile (多分支)

pipeline {
    agent none
    
    stages {
        stage('Build') {
            parallel {
                stage('Linux') {
                    agent { label 'linux' }
                    steps {
                        sh 'make build'
                    }
                }
                stage('Windows') {
                    agent { label 'windows' }
                    steps {
                        bat 'build.bat'
                    }
                }
            }
        }
    }
}
```

---

## 4. GitHub Actions

### 4.1 工作流语法

```yaml
.github/workflows/ci.yml

name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  DOCKER_IMAGE: my-app
  REGISTRY: ghcr.io

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run linter
      run: npm run lint
    
    - name: Run tests
      run: npm run test:coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info

  build:
    needs: test
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.DOCKER_IMAGE }}
        tags: |
          type=sha
          type=ref,event=branch
          type=semver,pattern={{version}}
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - name: Deploy to staging
      run: |
        kubectl set image deployment/my-app \
          my-app=${{ needs.build.outputs.image_tag }} \
          -n staging

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - name: Deploy to production
      run: |
        kubectl set image deployment/my-app \
          my-app=${{ needs.build.outputs.image_tag }} \
          -n production
```

### 4.2 常用Actions

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v4
    with:
      fetch-depth: 0

  - name: Setup Node.js
    uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'

  - name: Setup Python
    uses: actions/setup-python@v5
    with:
      python-version: '3.11'
      cache: 'pip'

  - name: Cache dependencies
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-node-

  - name: Run script
    run: |
      echo "Hello World"
      npm test

  - name: Upload artifact
    uses: actions/upload-artifact@v3
    with:
      name: build
      path: dist/

  - name: Download artifact
    uses: actions/download-artifact@v3
    with:
      name: build

  - name: Slack notification
    uses: slackapi/slack-github-action@v1
    with:
      channel-id: 'C0123456789'
      slack-message: 'Build completed!'
    env:
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

---

## 5. GitOps与ArgoCD

### 5.1 GitOps原理

```
GitOps工作流程

┌─────────────────────────────────────────────────────────────────────────┐
│                           Git Repository                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    声明式配置 (YAML)                              │   │
│  │  - deployments/                                                  │   │
│  │  - services/                                                     │   │
│  │  - configmaps/                                                   │   │
│  │  - secrets/                                                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    │ Git Push
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            ArgoCD                                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  1. 监听Git仓库变更                                               │   │
│  │  2. 比较Git状态与集群状态                                          │   │
│  │  3. 自动/手动同步                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    │ Apply
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster                                │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                                │
│  │   Pod   │  │   Pod   │  │   Pod   │                                │
│  └─────────┘  └─────────┘  └─────────┘                                │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 ArgoCD配置

```yaml
argocd/application.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/org/k8s-configs.git
    targetRevision: main
    path: apps/my-app
    
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
    
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

### 5.3 Kustomize配置

```
apps/my-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
└── overlays/
    ├── staging/
    │   ├── kustomization.yaml
    │   └── patches/
    └── production/
        ├── kustomization.yaml
        └── patches/
```

```yaml
base/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml
- configmap.yaml

commonLabels:
  app: my-app
```

```yaml
overlays/production/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

resources:
- ../../base

patchesStrategicMerge:
- patches/deployment-replicas.yaml

images:
- name: my-app
  newTag: v1.0.0
```

### 5.4 GitOps深度原理与最佳实践

**GitOps是怎么实现自动化部署的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              GitOps核心机制深度解析                                 │
└─────────────────────────────────────────────────────────────────┘

声明式 vs 命令式：

┌─────────────────────────────────────────────────────────────────┐
│  传统命令式部署：                                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  开发者执行命令：                                        │   │
│  │  kubectl apply -f deployment.yaml                     │   │
│  │  kubectl scale deployment/app --replicas=3           │   │
│  │  kubectl set image deployment/app nginx:v2          │   │
│  │                                                          │   │
│  │  问题：                                                   │   │
│  │  - 集群状态与Git配置不同步                               │   │
│  │  - 无法追溯变更历史                                       │   │
│  │  - 手动操作容易出错                                       │   │
│  │  - 缺乏审计                                             │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  GitOps声明式部署：                                             │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Git作为单一事实来源：                                  │   │
│  │  ├── 所有配置都在Git中                                 │   │
│  │  ├── 通过Git PR进行变更                                │   │
│  │  ├── 自动化CI/CD流程                                   │   │
│  │  └── GitOps工具自动同步到集群                            │   │
│  │                                                          │   │
│  │  优势：                                                   │   │
│  │  - Git作为单一事实来源                                   │   │
│  │  - 完整的变更历史                                       │   │
│  │  - 代码审查流程                                         │   │
│  │  - 自动化部署                                             │   │
│  │  - 配置漂移检测                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

ArgoCD同步机制：

┌─────────────────────────────────────────────────────────────────┐
│  ArgoCD同步流程：                                               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 监控Git仓库                                        │   │
│  │  ├── 定期轮询Git仓库                                    │   │
│  │  ├── 监听Git Webhook                                    │   │
│  │  ├── 检测配置变更                                       │   │
│  │  └── 触发同步流程                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  2. 比较状态                                            │   │
│  │  ├── Git状态：期望状态                                   │   │
│  │  ├── 集群状态：实际状态                                   │   │
│  │  ├── 计算差异：create/update/delete                     │   │
│  │  └── 生成同步计划                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  3. 应用变更                                            │   │
│  │  ├── 按依赖顺序应用                                     │   │
│  │  ├── 使用kubectl apply                                  │   │
│  │  ├── 实时显示同步状态                                   │   │
│  │  └── 处理失败和重试                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  4. 验证结果                                            │   │
│  │  ├── 检查资源是否创建成功                               │   │
│  │  ├── 验证Pod是否Running                                 │   │
│  │  ├── 运行健康检查                                       │   │
│  │  └── 更新同步状态                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

配置漂移检测：

┌─────────────────────────────────────────────────────────────────┐
│  ArgoCD配置漂移检测机制：                                      │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  什么是配置漂移？                                        │   │
│  │  ├── Git中的配置：期望状态                               │   │
│  │  ├── 集群中的配置：实际状态                              │   │
│  │  ├── 两者不一致：配置漂移                                │   │
│  │  └── 原因：手动修改、自动扩缩容等                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  检测流程：                                              │   │
│  │  ├── 定期比较Git和集群状态                               │   │
│  │  ├── 发现漂移后标记为OutOfSync                     │   │
│  │  ├── 提供自动修复选项                                   │   │
│  │  └── 发送告警通知                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  处理策略：                                              │   │
│  │  ├── 自动同步：自动修复漂移                               │   │
│  │  ├── 手动同步：需要人工确认                               │   │
│  │  ├── 仅告警：不自动修复                                   │   │
│  │  └── 策略可按应用配置                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. 实操项目

### 项目：完整CI/CD流水线

```yaml
.github/workflows/full-pipeline.yml

name: Full CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        ignore-unfixed: true
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  test:
    runs-on: ubuntu-latest
    needs: security
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
        - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run linting
      run: npm run lint
    
    - name: Run tests
      run: npm run test:ci
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3

  build:
    runs-on: ubuntu-latest
    needs: test
    permissions:
      contents: read
      packages: write
    
    outputs:
      image_digest: ${{ steps.build.outputs.digest }}
      image_tag: ${{ steps.meta.outputs.tags }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
    
    - name: Build and push
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy-staging:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.example.com
    
    steps:
    - name: Deploy to staging
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.STAGING_HOST }}
        username: ${{ secrets.SSH_USER }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          kubectl set image deployment/my-app \
            my-app=${{ needs.build.outputs.image_tag }} \
            -n staging

  deploy-production:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://example.com
    
    steps:
    - name: Deploy to production
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.PRODUCTION_HOST }}
        username: ${{ secrets.SSH_USER }}
        key: ${{ secrets.SSH_KEY }}
        script: |
          kubectl set image deployment/my-app \
            my-app=${{ needs.build.outputs.image_tag }} \
            -n production
    
    - name: Create GitHub release
      uses: softprops/action-gh-release@v1
      with:
        generate_release_notes: true
```

---

## 7. 知识检测

### 选择题

1. CI代表什么？
   - A. Continuous Integration
   - B. Continuous Improvement
   - C. Code Integration
   - D. Container Integration

2. GitOps的核心原则是什么？
   - A. 使用Git作为唯一事实来源
   - B. 使用Docker容器
   - C. 使用Kubernetes
   - D. 使用Jenkins

3. GitHub Actions的工作流文件存放在哪个目录？
   - A. .github/workflows/
   - B. .actions/
   - C. .workflows/
   - D. .ci/

---

## 8. 扩展阅读

- [Jenkins官方文档](https://www.jenkins.io/doc/)
- [GitHub Actions文档](https://docs.github.com/en/actions)
- [ArgoCD文档](https://argo-cd.readthedocs.io/)

---

## 学习进度

- [ ] 理解CI/CD核心概念
- [ ] 掌握Git最佳实践
- [ ] 学会Jenkins流水线
- [ ] 掌握GitHub Actions
- [ ] 了解GitOps与ArgoCD
- [ ] 完成实操项目
