# Terraform GCP 认证配置指南

## 概述

本文档介绍 Terraform 与 GCP 集成的认证配置方法，包括本地开发、CI/CD、云端运行等场景。

---

## 1. 认证方式概览

### 1.1 三种主要方式

```
┌─────────────────────────────────────────────────────────────────┐
│                  Terraform GCP 认证方式                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  方式 1：ADC（应用默认凭据）                                     │
│  ─────────────────────────                                      │
│  ├── 命令：gcloud auth application-default login               │
│  ├── 适用：本地开发、测试                                       │
│  ├── 优点：简单易用                                             │
│  └── 缺点：不适合 CI/CD                                         │
│                                                                  │
│  方式 2：服务账号密钥                                           │
│  ─────────────────────────                                      │
│  ├── 配置：GOOGLE_APPLICATION_CREDENTIALS 环境变量             │
│  ├── 适用：CI/CD、自动化                                        │
│  ├── 优点：标准化、可移植                                       │
│  └── 缺点：密钥管理复杂                                         │
│                                                                  │
│  方式 3：Workload Identity                                      │
│  ─────────────────────────                                      │
│  ├── 配置：OIDC 联邦认证                                        │
│  ├── 适用：GitHub Actions、GitLab CI、GKE                       │
│  ├── 优点：无需密钥、最安全                                     │
│  └── 缺点：配置复杂                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 选择指南

| 场景 | 推荐方式 | 原因 |
|------|----------|------|
| 本地开发调试 | ADC | 简单快速 |
| 个人项目 | ADC | 无需额外配置 |
| CI/CD（GitHub Actions） | Workload Identity | 安全、无需管理密钥 |
| CI/CD（传统） | 服务账号密钥 | 兼容性好 |
| GKE/Cloud Run | 自动认证 | 无需配置 |
| 生产环境 | Workload Identity | 安全最佳实践 |

---

## 2. 方式一：ADC 本地开发认证

### 2.1 配置步骤

```bash
# 步骤 1：用户账号登录（用于 gcloud 命令）
gcloud auth login

# 步骤 2：ADC 登录（用于 Terraform）
gcloud auth application-default login

# 步骤 3：设置默认项目
gcloud config set project YOUR_PROJECT_ID

# 步骤 4：验证认证
gcloud auth list
gcloud auth application-default print-access-token
```

### 2.2 Terraform 配置

```hcl
# main.tf - 最简配置
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# 无需指定 credentials，ADC 自动查找
provider "google" {
  project = "my-project-id"
  region  = "asia-east1"
}
```

### 2.3 验证

```bash
# 初始化
terraform init

# 验证配置
terraform plan
```

### 2.4 常见问题

**问题：** `google: could not find default credentials`

**解决：**

```bash
gcloud auth application-default login
```

---

## 3. 方式二：服务账号密钥认证

### 3.1 创建服务账号

```bash
# 1. 创建服务账号
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account"

# 2. 授予必要权限
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# 3. 创建密钥
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account="terraform@PROJECT_ID.iam.gserviceaccount.com"

# 4. 保护密钥文件
chmod 600 terraform-key.json
echo "terraform-key.json" >> .gitignore
```

### 3.2 推荐的服务账号权限

```
┌─────────────────────────────────────────────────────────────────┐
│                  Terraform 服务账号权限建议                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  最小权限原则：                                                  │
│  ─────────────                                                  │
│  ├── roles/compute.admin        - Compute Engine 管理          │
│  ├── roles/storage.admin        - Cloud Storage 管理           │
│  ├── roles/iam.serviceAccountUser - 服务账号使用               │
│  ├── roles/container.admin      - GKE 管理                     │
│  ├── roles/cloudsql.admin       - Cloud SQL 管理               │
│  └── roles/dns.admin            - Cloud DNS 管理               │
│                                                                  │
│  开发环境（简单）：                                              │
│  ─────────────                                                  │
│  └── roles/editor               - 编辑者权限                    │
│                                                                  │
│  生产环境（安全）：                                              │
│  ─────────────                                                  │
│  └── 按资源类型分配最小权限                                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 使用方式

**方式 A：环境变量（推荐）**

```bash
# 设置环境变量
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/terraform-key.json"

# Terraform 配置无需指定 credentials
provider "google" {
  project = "my-project-id"
  region  = "asia-east1"
}

# 运行 Terraform
terraform init
terraform apply
```

**方式 B：Provider 配置**

```hcl
# main.tf
provider "google" {
  credentials = file("terraform-key.json")
  project     = "my-project-id"
  region      = "asia-east1"
}
```

**方式 C：变量注入**

```hcl
# variables.tf
variable "gcp_credentials" {
  description = "GCP credentials JSON"
  type        = string
  sensitive   = true
}

# main.tf
provider "google" {
  credentials = var.gcp_credentials
  project     = "my-project-id"
  region      = "asia-east1"
}
```

```bash
# 使用环境变量传递
export TF_VAR_gcp_credentials='{"type":"service_account",...}'

# 或使用 tfvars 文件（不要提交到 Git）
echo 'gcp_credentials = "..." ' > terraform.tfvars
echo "terraform.tfvars" >> .gitignore
```

### 3.4 CI/CD 配置示例

**GitHub Actions：**

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.GCP_CREDENTIALS }}
        run: terraform init

      - name: Terraform Apply
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.GCP_CREDENTIALS }}
        run: terraform apply -auto-approve
```

**GitLab CI：**

```yaml
# .gitlab-ci.yml
variables:
  GOOGLE_APPLICATION_CREDENTIALS: $GCP_CREDENTIALS

stages:
  - deploy

terraform:
  stage: deploy
  image: hashicorp/terraform:latest
  script:
    - terraform init
    - terraform apply -auto-approve
```

---

## 4. 方式三：Workload Identity（推荐）

### 4.1 原理

```
┌─────────────────────────────────────────────────────────────────┐
│                  Workload Identity 原理                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  传统方式：                                                      │
│  ┌─────────┐     服务账号密钥      ┌─────────┐                  │
│  │ GitHub  │ ──────────────────> │   GCP   │                  │
│  │ Actions │     (长期有效)       │         │                  │
│  └─────────┘                      └─────────┘                  │
│       │                                                          │
│       └──> 问题：密钥泄露风险高                                  │
│                                                                  │
│  Workload Identity：                                             │
│  ┌─────────┐     OIDC Token       ┌─────────┐                  │
│  │ GitHub  │ ──────────────────> │   GCP   │                  │
│  │ Actions │     (短期有效)       │         │                  │
│  └─────────┘                      └─────────┘                  │
│       │                                │                        │
│       │                                │                        │
│       └──> 优势：无需密钥，自动轮换 ──┘                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 配置步骤

**步骤 1：创建服务账号**

```bash
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account"
```

**步骤 2：创建 Workload Identity Pool**

```bash
gcloud iam workload-identity-pools create github-actions \
  --location="global" \
  --display-name="GitHub Actions Pool"
```

**步骤 3：创建 Provider**

```bash
gcloud iam workload-identity-pools providers create-oidc github \
  --workload-identity-pool="github-actions" \
  --location="global" \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository"
```

**步骤 4：绑定服务账号**

```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform@PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/attribute.repository/ORG/REPO"
```

**步骤 5：授予权限**

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"
```

### 4.3 GitHub Actions 配置

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          project_id: my-project-id
          workload_identity_provider: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/providers/github
          service_account: terraform@my-project-id.iam.gserviceaccount.com

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve
```

### 4.4 Terraform 配置

```hcl
# 无需任何认证配置，GitHub Actions 自动注入
provider "google" {
  project = "my-project-id"
  region  = "asia-east1"
}
```

---

## 5. 多环境认证配置

### 5.1 目录结构

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   └── vpc/
└── backend.tf
```

### 5.2 使用别名配置多项目

```hcl
# 多项目配置
provider "google" {
  alias   = "dev"
  project = "dev-project-id"
  region  = "asia-east1"
}

provider "google" {
  alias   = "prod"
  project = "prod-project-id"
  region  = "asia-east1"
}

# 使用指定 provider
resource "google_compute_instance" "dev_server" {
  provider = google.dev
  name     = "dev-server"
  # ...
}

resource "google_compute_instance" "prod_server" {
  provider = google.prod
  name     = "prod-server"
  # ...
}
```

### 5.3 使用变量切换环境

```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_ids" {
  description = "Project IDs per environment"
  type        = map(string)
  default = {
    dev     = "dev-project-id"
    staging = "staging-project-id"
    prod    = "prod-project-id"
  }
}

# main.tf
provider "google" {
  project = var.project_ids[var.environment]
  region  = "asia-east1"
}
```

```bash
# 部署到不同环境
terraform apply -var="environment=dev"
terraform apply -var="environment=prod"
```

---

## 6. 远程 State 认证

### 6.1 GCS Backend 配置

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "terraform/state"
  }
}
```

### 6.2 Backend 认证方式

```bash
# 方式 1：ADC
gcloud auth application-default login

# 方式 2：服务账号
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"

# 方式 3：在 backend 配置中指定
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "terraform/state"
    credentials = "terraform-key.json"
  }
}
```

### 6.3 State 文件权限

```bash
# 创建 State 存储桶
gcloud storage buckets create gs://my-terraform-state \
  --location=asia-east1 \
  --uniform-bucket-level-access

# 授予服务账号权限
gcloud storage buckets add-iam-policy-binding gs://my-terraform-state \
  --member="serviceAccount:terraform@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

---

## 7. 安全最佳实践

### 7.1 凭据管理

```
┌─────────────────────────────────────────────────────────────────┐
│                    凭据管理最佳实践                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 永远不要将密钥提交到 Git                                    │
│     ├── 添加到 .gitignore                                       │
│     ├── 使用 pre-commit hook 检查                               │
│     └── 使用 git-secrets 工具                                   │
│                                                                  │
│  2. 使用环境变量                                                │
│     ├── GOOGLE_APPLICATION_CREDENTIALS                         │
│     ├── TF_VAR_xxx                                              │
│     └── CI/CD Secrets                                           │
│                                                                  │
│  3. 定期轮换密钥                                                │
│     ├── 设置密钥过期时间                                        │
│     ├── 自动化轮换流程                                          │
│     └── 使用 Workload Identity 避免密钥                         │
│                                                                  │
│  4. 最小权限原则                                                │
│     ├── 只授予必要的角色                                        │
│     ├── 使用自定义角色                                          │
│     └── 定期审计权限                                            │
│                                                                  │
│  5. 审计日志                                                    │
│     ├── 启用 Cloud Audit Logs                                  │
│     ├── 监控异常访问                                            │
│     └── 设置告警                                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 .gitignore 配置

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!example.tfvars
.terraform.lock.hcl

# GCP 凭据
*.json
!*.tf.json
terraform-key.json
service-account-*.json

# 环境变量
.env
.env.*
```

### 7.3 pre-commit hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# 检查是否包含私钥
if git diff --cached --name-only | xargs grep -l "private_key" 2>/dev/null; then
  echo "ERROR: Commit contains private key!"
  exit 1
fi

# 检查是否包含服务账号密钥
if git diff --cached --name-only | xargs grep -l '"type": "service_account"' 2>/dev/null; then
  echo "ERROR: Commit contains service account key!"
  exit 1
fi
```

---

## 8. 故障排查

### 8.1 常见错误

**错误 1：could not find default credentials**

```bash
# 原因：未配置 ADC
# 解决：
gcloud auth application-default login
```

**错误 2：Permission denied**

```bash
# 原因：服务账号权限不足
# 解决：
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"
```

**错误 3：API not enabled**

```bash
# 原因：API 未启用
# 解决：
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

**错误 4：Quota exceeded**

```bash
# 原因：配额不足
# 解决：在 GCP Console 申请配额提升
```

### 8.2 调试命令

```bash
# 查看当前认证账号
gcloud auth list

# 查看 ADC 状态
gcloud auth application-default print-access-token

# 测试 API 访问
gcloud compute instances list

# 查看 Terraform 调试日志
export TF_LOG=DEBUG
terraform apply

# 查看服务账号权限
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:terraform@"
```

---

## 参考链接

- [GCP Authentication](https://cloud.google.com/docs/authentication)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GCP IAM Roles](https://cloud.google.com/iam/docs/understanding-roles)
