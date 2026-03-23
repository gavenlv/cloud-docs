# Terraform工作空间和环境管理

## 4.1 工作空间原理

### 4.1.1 为什么需要工作空间？

```
工作空间解决的问题：

┌─────────────────────────────────────────────────────────────────┐
│  问题：多环境管理混乱                                   │
└─────────────────────────────────────────────────────────────────┘

场景：管理dev、staging、prod三个环境

方案1：使用不同目录
terraform-dev/
├── main.tf
├── terraform.tfstate
└── .terraform/

terraform-staging/
├── main.tf
├── terraform.tfstate
└── .terraform/

terraform-prod/
├── main.tf
├── terraform.tfstate
└── .terraform/

问题：
├── 代码重复（三个目录的main.tf几乎相同）
├── 配置分散，难以同步
├── 变量文件重复
└── 维护成本高

方案2：使用不同状态文件
terraform/
├── main.tf
├── terraform-dev.tfstate
├── terraform-staging.tfstate
└── terraform-prod.tfstate

问题：
├── 需要手动指定状态文件
├── 容易出错（忘记切换状态文件）
├── 无法自动化
└── 不符合Terraform最佳实践

┌─────────────────────────────────────────────────────────────────┐
│  解决方案：工作空间 (Workspaces)                       │
└─────────────────────────────────────────────────────────────────┘

terraform/
├── main.tf（单一配置文件）
├── terraform.tfstate.d/
│   ├── default.tfstate
│   ├── dev.tfstate
│   ├── staging.tfstate
│   └── prod.tfstate
└── .terraform/

优势：
├── 单一配置文件，代码不重复
├── 状态文件自动隔离
├── 变量文件可以共享
├── 切换环境简单
└── 符合Terraform最佳实践
```

### 4.1.2 工作空间工作原理

```
工作空间实现机制：

┌─────────────────────────────────────────────────────────────────┐
│  工作空间目录结构                                      │
└─────────────────────────────────────────────────────────────────┘

terraform/
├── main.tf
├── variables.tf
├── terraform.tfvars
├── terraform.tfstate.d/
│   ├── default.tfstate
│   ├── dev.tfstate
│   ├── staging.tfstate
│   └── prod.tfstate
└── .terraform/
    └── environment
        └── dev  # 当前工作空间

┌─────────────────────────────────────────────────────────────────┐
│  工作空间切换流程                                      │
└─────────────────────────────────────────────────────────────────┘

1. 查看当前工作空间
   $ terraform workspace show
   default

2. 列出所有工作空间
   $ terraform workspace list
   * default
     dev
     staging
     prod

3. 切换工作空间
   $ terraform workspace select dev
   Switched to workspace "dev"

4. 验证当前工作空间
   $ terraform workspace show
   dev

5. 执行操作（使用dev状态文件）
   $ terraform apply
   # 使用 terraform.tfstate.d/dev.tfstate

6. 切换到prod
   $ terraform workspace select prod
   Switched to workspace "prod"

7. 执行操作（使用prod状态文件）
   $ terraform apply
   # 使用 terraform.tfstate.d/prod.tfstate
```

### 4.1.3 工作空间和状态文件的关系

```
状态文件命名规则：

┌─────────────────────────────────────────────────────────────────┐
│  本地后端                                              │
└─────────────────────────────────────────────────────────────────┘

terraform.tfstate.d/
├── default.tfstate      # default工作空间
├── dev.tfstate         # dev工作空间
├── staging.tfstate     # staging工作空间
└── prod.tfstate        # prod工作空间

┌─────────────────────────────────────────────────────────────────┐
│  远程后端（GCS）                                        │
└─────────────────────────────────────────────────────────────────┘

gs://terraform-state/
├── env:/default/terraform.tfstate      # default工作空间
├── env:/dev/terraform.tfstate         # dev工作空间
├── env:/staging/terraform.tfstate     # staging工作空间
└── env:/prod/terraform.tfstate        # prod工作空间

注意：远程后端使用工作空间名称作为目录前缀
```

---

## 4.2 环境隔离策略

### 4.2.1 环境隔离层次

```
环境隔离策略：

┌─────────────────────────────────────────────────────────────────┐
│  层次1：工作空间隔离                                   │
└─────────────────────────────────────────────────────────────────┘

优势：
├── 状态文件隔离
├── 简单快速
├── 适合小型项目
└── 无需额外配置

劣势：
├── 配置文件共享
├── 变量文件共享
├── 容易误操作（在dev工作空间应用prod配置）
└── 资源命名需要区分

适用场景：
├── 单一项目
├── 环境差异小
├── 团队规模小
└── 快速原型开发

┌─────────────────────────────────────────────────────────────────┐
│  层次2：目录隔离                                       │
└─────────────────────────────────────────────────────────────────┘

project/
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
└── modules/

优势：
├── 配置文件隔离
├── 变量文件隔离
├── 减少误操作
├── 可以独立测试
└── 适合大型项目

劣势：
├── 代码可能重复
├── 维护成本高
├── 需要同步变更
└── 状态文件管理复杂

适用场景：
├── 多个项目
├── 环境差异大
├── 团队规模大
└── 需要独立测试

┌─────────────────────────────────────────────────────────────────┐
│  层次3：混合隔离                                       │
└─────────────────────────────────────────────────────────────────┘

project/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       └── terraform.tfvars
├── modules/
└── backend.tf

优势：
├── 配置文件隔离
├── 状态文件隔离
├── 模块共享
├── 灵活性高
└── 适合企业级项目

适用场景：
├── 企业级项目
├── 多个团队协作
├── 需要严格隔离
└── 复杂的基础设施
```

### 4.2.2 资源命名规范

```bash
# 工作空间隔离的命名规范

# dev环境
resource "google_compute_instance" "web_server" {
  name = "${terraform.workspace}-web-server"
  # dev-web-server
}

# staging环境
resource "google_compute_instance" "web_server" {
  name = "${terraform.workspace}-web-server"
  # staging-web-server
}

# prod环境
resource "google_compute_instance" "web_server" {
  name = "${terraform.workspace}-web-server"
  # prod-web-server
}
```

### 4.2.3 变量文件隔离

```bash
# 目录结构
environments/
├── dev/
│   └── terraform.tfvars
├── staging/
│   └── terraform.tfvars
└── prod/
    └── terraform.tfvars

# dev/terraform.tfvars
project_id      = "dev-project-id"
instance_count = 1
instance_type  = "e2-small"

# staging/terraform.tfvars
project_id      = "staging-project-id"
instance_count = 2
instance_type  = "e2-medium"

# prod/terraform.tfvars
project_id      = "prod-project-id"
instance_count = 3
instance_type  = "e2-highcpu-4"

# 使用
cd environments/dev
terraform apply -var-file="terraform.tfvars"

cd environments/staging
terraform apply -var-file="terraform.tfvars"

cd environments/prod
terraform apply -var-file="terraform.tfvars"
```

---

## 4.3 工作空间实战

### 4.3.1 创建工作空间

```bash
# 1. 初始化项目
mkdir terraform-workspace-demo
cd terraform-workspace-demo

# 2. 创建配置文件
cat > main.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "my-project-id"
  region  = "us-central1"
}

resource "google_compute_network" "vpc" {
  name = "${terraform.workspace}-network"
  auto_create_subnetworks = false
}

output "network_name" {
  value = google_compute_network.vpc.name
}
EOF

# 3. 初始化
terraform init

# 4. 查看当前工作空间
terraform workspace show
# default

# 5. 创建新工作空间
terraform workspace new dev
# Created and switched to workspace "dev"!

terraform workspace new staging
# Created and switched to workspace "staging"!

terraform workspace new prod
# Created and switched to workspace "prod"!

# 6. 列出所有工作空间
terraform workspace list
#   default
# * dev
#   staging
#   prod

# 7. 切换工作空间
terraform workspace select dev
# Switched to workspace "dev"

terraform workspace show
# dev
```

### 4.3.2 在不同工作空间中应用配置

```bash
# 1. 切换到dev工作空间
terraform workspace select dev

# 2. 查看执行计划
terraform plan

# 输出：
# Terraform will perform the following actions:
#
#   # google_compute_network.vpc will be created
#   + resource "google_compute_network" "vpc" {
#       + name = "dev-network"
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.

# 3. 应用配置
terraform apply -auto-approve

# 4. 验证资源
gcloud compute networks list
# NAME: dev-network

# 5. 切换到staging工作空间
terraform workspace select staging

# 6. 查看执行计划
terraform plan

# 输出：
# Terraform will perform the following actions:
#
#   # google_compute_network.vpc will be created
#   + resource "google_compute_network" "vpc" {
#       + name = "staging-network"
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.

# 7. 应用配置
terraform apply -auto-approve

# 8. 验证资源
gcloud compute networks list
# NAME: dev-network
# NAME: staging-network

# 9. 切换到prod工作空间
terraform workspace select prod

# 10. 查看执行计划
terraform plan

# 输出：
# Terraform will perform the following actions:
#
#   # google_compute_network.vpc will be created
#   + resource "google_compute_network" "vpc" {
#       + name = "prod-network"
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.

# 11. 应用配置
terraform apply -auto-approve

# 12. 验证所有资源
gcloud compute networks list
# NAME: dev-network
# NAME: staging-network
# NAME: prod-network
```

### 4.3.3 工作空间状态管理

```bash
# 1. 查看dev工作空间状态
terraform workspace select dev
terraform state list
# google_compute_network.vpc

# 2. 查看staging工作空间状态
terraform workspace select staging
terraform state list
# google_compute_network.vpc

# 3. 查看prod工作空间状态
terraform workspace select prod
terraform state list
# google_compute_network.vpc

# 4. 查看状态文件位置
terraform output -json | jq '.backend'

# 输出：
# {
#   "type": "local",
#   "path": "./terraform.tfstate.d"
# }

# 5. 查看实际状态文件
ls -la terraform.tfstate.d/
# total 24
# drwxr-xr-x  2 user user 4096 Jan 15 10:30 .
# drwxr-xr-x  5 user user 4096 Jan 15 10:30 ..
# -rw-r--r--  1 user user 1234 Jan 15 10:30 default.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:31 dev.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:32 staging.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:33 prod.tfstate
```

### 4.3.4 删除工作空间

```bash
# 1. 列出所有工作空间
terraform workspace list
#   default
# * dev
#   staging
#   prod

# 2. 切换到要删除的工作空间
terraform workspace select dev

# 3. 删除工作空间中的所有资源
terraform destroy -auto-approve

# 4. 删除工作空间
terraform workspace delete dev

# 输出：
# Deleted workspace "dev"!

# 5. 验证工作空间已删除
terraform workspace list
#   default
#   staging
#   prod

# 6. 验证状态文件已删除
ls -la terraform.tfstate.d/
# total 18
# drwxr-xr-x  2 user user 4096 Jan 15 10:35 .
# drwxr-xr-x  5 user user 4096 Jan 15 10:35 ..
# -rw-r--r--  1 user user 1234 Jan 15 10:30 default.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:32 staging.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:33 prod.tfstate
```

---

## 4.4 远程后端和工作空间

### 4.4.1 配置GCS后端

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "env:/${terraform.workspace}"
    credentials = "path/to/service-account.json"
  }
}
```

### 4.4.2 工作空间和远程状态

```bash
# 1. 初始化远程后端
terraform init

# 输出：
# Initializing the backend...
# Successfully configured the backend "gcs"! Terraform will automatically
# use this backend unless you change configuration or run `terraform init` again.

# 2. 创建工作空间
terraform workspace new dev
# Created and switched to workspace "dev"!

# 3. 应用配置
terraform apply -auto-approve

# 4. 验证远程状态文件
gsutil ls gs://my-terraform-state/
# gs://my-terraform-state/env:/default/
# gs://my-terraform-state/env:/dev/

# 5. 查看dev工作空间的状态文件
gsutil cat gs://my-terraform-state/env:/dev/terraform.tfstate

# 6. 创建staging工作空间
terraform workspace new staging

# 7. 应用配置
terraform apply -auto-approve

# 8. 验证远程状态文件
gsutil ls gs://my-terraform-state/
# gs://my-terraform-state/env:/default/
# gs://my-terraform-state/env:/dev/
# gs://my-terraform-state/env:/staging/

# 9. 查看staging工作空间的状态文件
gsutil cat gs://my-terraform-state/env:/staging/terraform.tfstate
```

### 4.4.3 工作空间状态锁定

```bash
# 1. 在终端1中锁定dev工作空间
terraform workspace select dev
terraform apply -auto-approve

# 2. 在终端2中尝试锁定dev工作空间（应该失败）
terraform workspace select dev
terraform apply -auto-approve

# 输出：
# Error: Error acquiring the state lock
# Lock Info:
#   ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
#   Path:      gs://my-terraform-state/env:/dev/.terraform.lock
#   Operation: OperationTypeApply
#   Who:       user@example.com
#   Version:   1.5.0
#   Created:   2024-01-15 10:30:00.000 UTC

# 3. 在终端2中切换到staging工作空间（应该成功）
terraform workspace select staging
terraform apply -auto-approve

# 输出：
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

## 4.5 环境管理最佳实践

### 4.5.1 使用环境变量

```bash
# 设置环境变量
export TF_VAR_project_id="dev-project-id"
export TF_VAR_region="us-central1"
export TF_VAR_instance_count=1

# 使用环境变量
terraform apply

# 配置文件
variable "project_id" {
  type = string
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "instance_count" {
  type = number
  default = 1
}
```

### 4.5.2 使用变量文件

```bash
# 创建环境特定的变量文件
cat > terraform-dev.tfvars << 'EOF'
project_id      = "dev-project-id"
instance_count = 1
instance_type  = "e2-small"
environment    = "dev"
EOF

cat > terraform-staging.tfvars << 'EOF'
project_id      = "staging-project-id"
instance_count = 2
instance_type  = "e2-medium"
environment    = "staging"
EOF

cat > terraform-prod.tfvars << 'EOF'
project_id      = "prod-project-id"
instance_count = 3
instance_type  = "e2-highcpu-4"
environment    = "prod"
EOF

# 使用变量文件
terraform apply -var-file="terraform-dev.tfvars"
terraform apply -var-file="terraform-staging.tfvars"
terraform apply -var-file="terraform-prod.tfvars"
```

### 4.5.3 使用条件逻辑

```hcl
# main.tf
variable "environment" {
  description = "环境名称"
  type        = string
  default     = "dev"
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "实例类型"
  type        = string
  default     = "e2-small"
}

# 根据环境设置不同的配置
locals {
  config = {
    dev = {
      instance_count = 1
      instance_type  = "e2-small"
      disk_size     = 50
    }
    staging = {
      instance_count = 2
      instance_type  = "e2-medium"
      disk_size     = 100
    }
    prod = {
      instance_count = 3
      instance_type  = "e2-highcpu-4"
      disk_size     = 200
    }
  }

  current_config = lookup(local.config, var.environment, local.config.dev)
}

resource "google_compute_instance" "web_server" {
  count        = local.current_config.instance_count
  name         = "${var.environment}-web-server-${count.index}"
  machine_type = local.current_config.instance_type
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    size = local.current_config.disk_size
  }

  network_interface {
    network = "default"
  }
}

output "instance_names" {
  value = google_compute_instance.web_server[*].name
}
```

### 4.5.4 使用工作空间和变量文件结合

```bash
# 项目结构
terraform-project/
├── main.tf
├── variables.tf
├── terraform-dev.tfvars
├── terraform-staging.tfvars
└── terraform-prod.tfvars

# main.tf
variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "environment" {
  description = "环境名称"
  type        = string
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

resource "google_compute_instance" "web_server" {
  count        = var.instance_count
  name         = "${var.environment}-web-server-${count.index}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}

# 使用方法
terraform workspace new dev
terraform apply -var-file="terraform-dev.tfvars"

terraform workspace new staging
terraform apply -var-file="terraform-staging.tfvars"

terraform workspace new prod
terraform apply -var-file="terraform-prod.tfvars"
```

---

## 4.6 环境管理实战案例

### 4.6.1 案例：三环境部署

**项目结构：**

```bash
multi-env-project/
├── main.tf
├── variables.tf
├── terraform-dev.tfvars
├── terraform-staging.tfvars
├── terraform-prod.tfvars
└── modules/
    ├── vpc/
    ├── compute/
    └── storage/
```

**main.tf：**

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "env:/${terraform.workspace}"
    credentials = "path/to/service-account.json"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source = "./modules/vpc"

  project_id   = var.project_id
  network_name = "${var.environment}-vpc"
}

module "compute" {
  source = "./modules/compute"

  project_id  = var.project_id
  vpc_id      = module.vpc.network_id
  environment = var.environment

  instance_count = var.instance_count
}
```

**variables.tf：**

```hcl
variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "环境名称"
  type        = string
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}
```

**terraform-dev.tfvars：**

```hcl
project_id      = "dev-project-id"
environment    = "dev"
instance_count = 1
```

**terraform-staging.tfvars：**

```hcl
project_id      = "staging-project-id"
environment    = "staging"
instance_count = 2
```

**terraform-prod.tfvars：**

```hcl
project_id      = "prod-project-id"
environment    = "prod"
instance_count = 3
```

**部署流程：**

```bash
# 1. 初始化
terraform init

# 2. 创建工作空间
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 3. 部署dev环境
terraform workspace select dev
terraform apply -var-file="terraform-dev.tfvars" -auto-approve

# 4. 验证dev环境
gcloud compute instances list --project=dev-project-id
# NAME: dev-web-server-0

# 5. 部署staging环境
terraform workspace select staging
terraform apply -var-file="terraform-staging.tfvars" -auto-approve

# 6. 验证staging环境
gcloud compute instances list --project=staging-project-id
# NAME: staging-web-server-0
# NAME: staging-web-server-1

# 7. 部署prod环境
terraform workspace select prod
terraform apply -var-file="terraform-prod.tfvars" -auto-approve

# 8. 验证prod环境
gcloud compute instances list --project=prod-project-id
# NAME: prod-web-server-0
# NAME: prod-web-server-1
# NAME: prod-web-server-2

# 9. 查看所有工作空间状态
terraform workspace list
#   default
# * dev
#   staging
#   prod

# 10. 查看远程状态文件
gsutil ls gs://my-terraform-state/
# gs://my-terraform-state/env:/default/
# gs://my-terraform-state/env:/dev/
# gs://my-terraform-state/env:/staging/
# gs://my-terraform-state/env:/prod/
```

### 4.6.2 案例：环境升级

```bash
# 场景：将dev环境升级到staging环境

# 1. 备份dev工作空间状态
terraform workspace select dev
terraform state pull > dev-state-backup.json

# 2. 导出dev环境配置
terraform output -json > dev-outputs.json

# 3. 切换到staging工作空间
terraform workspace select staging

# 4. 导入dev环境资源到staging
# 注意：需要手动导入每个资源
terraform import \
  google_compute_network.vpc \
  projects/dev-project-id/global/networks/dev-vpc

# 5. 更新staging环境配置
# 编辑terraform-staging.tfvars，使用dev环境的配置

# 6. 应用staging环境配置
terraform apply -var-file="terraform-staging.tfvars" -auto-approve

# 7. 验证staging环境
gcloud compute instances list --project=staging-project-id
```

---

## 4.7 常见问题排查

### 4.7.1 问题：工作空间状态不一致

**症状：**
```bash
terraform workspace select dev
terraform plan
# Error: State lock does not exist
```

**解决方案：**

```bash
# 1. 检查工作空间是否存在
terraform workspace list

# 2. 如果不存在，创建工作空间
terraform workspace new dev

# 3. 如果存在但状态文件丢失，重新初始化
terraform init

# 4. 如果远程状态文件丢失，从备份恢复
gsutil cp \
  gs://my-terraform-state/env:/dev/terraform.tfstate.backup \
  gs://my-terraform-state/env:/dev/terraform.tfstate
```

### 4.7.2 问题：工作空间切换失败

**症状：**
```bash
terraform workspace select prod
# Error: Workspace "prod" already exists
```

**解决方案：**

```bash
# 1. 列出所有工作空间
terraform workspace list

# 2. 如果工作空间已存在，直接切换
terraform workspace select prod

# 3. 如果需要删除工作空间，先销毁资源
terraform workspace select prod
terraform destroy -auto-approve

# 4. 删除工作空间
terraform workspace delete prod

# 5. 重新创建工作空间
terraform workspace new prod
```

### 4.7.3 问题：远程后端工作空间问题

**症状：**
```bash
terraform workspace new dev
# Error: Failed to create workspace: Access Denied
```

**解决方案：**

```bash
# 1. 检查GCS权限
gcloud storage buckets get-iam-policy gs://my-terraform-state

# 2. 确保服务账号有写权限
gcloud storage buckets add-iam-policy-binding \
  gs://my-terraform-state \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# 3. 重新初始化
terraform init

# 4. 创建工作空间
terraform workspace new dev
```

---

## 本章小结

- 工作空间提供状态文件隔离
- 工作空间适合小型项目和环境差异小的场景
- 目录隔离适合大型项目和环境差异大的场景
- 混合隔离提供最大的灵活性
- 使用变量文件管理环境特定配置
- 远程后端支持工作空间自动隔离
- 工作空间状态锁定防止并发冲突

---

**下一章：Terraform与GCP集成**
