# Terraform最佳实践

## 7.1 代码组织最佳实践

### 7.1.1 项目结构

```
推荐的项目结构：

┌─────────────────────────────────────────────────────────────────┐
│  标准项目结构                                          │
└─────────────────────────────────────────────────────────────────┘

terraform-project/
├── README.md
├── LICENSE
├── .gitignore
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── versions.tf
├── backend.tf
├── modules/
│   ├── vpc/
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/
│       ├── README.md
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
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
├── examples/
│   ├── basic/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── advanced/
│       ├── main.tf
│       └── terraform.tfvars
├── scripts/
│   ├── init.sh
│   ├── plan.sh
│   └── apply.sh
└── tests/
    ├── unit/
    └── integration/

说明：
├── README.md：项目文档
├── LICENSE：许可证
├── .gitignore：Git忽略文件
├── main.tf：主要配置文件
├── variables.tf：变量定义
├── outputs.tf：输出定义
├── terraform.tfvars：变量值
├── versions.tf：版本约束
├── backend.tf：后端配置
├── modules/：模块目录
├── environments/：环境配置
├── examples/：示例配置
├── scripts/：脚本文件
└── tests/：测试文件
```

### 7.1.2 文件命名规范

```bash
# 文件命名规范

# 主要配置文件
main.tf              # 主要资源定义
variables.tf         # 变量定义
outputs.tf          # 输出定义
versions.tf         # 版本约束
backend.tf          # 后端配置
provider.tf         # Provider配置

# 环境特定文件
terraform-dev.tfvars      # 开发环境变量
terraform-staging.tfvars  # 预发布环境变量
terraform-prod.tfvars     # 生产环境变量

# 模块文件
modules/vpc/main.tf       # VPC模块
modules/compute/main.tf   # 计算模块
modules/storage/main.tf   # 存储模块

# 命名原则：
├── 使用小写字母
├── 使用下划线分隔
├── 使用描述性名称
├── 避免使用空格
└── 避免使用特殊字符
```

### 7.1.3 代码格式化

```bash
# 格式化Terraform代码
terraform fmt

# 检查格式是否正确
terraform fmt -check

# 递归格式化所有子目录
terraform fmt -recursive

# 在CI/CD中使用
terraform fmt -check
if [ $? -ne 0 ]; then
  echo "Terraform code is not formatted"
  exit 1
fi
```

---

## 7.2 安全最佳实践

### 7.2.1 敏感数据管理

```
敏感数据管理策略：

┌─────────────────────────────────────────────────────────────────┐
│  1. 避免在代码中硬编码敏感信息                             │
└─────────────────────────────────────────────────────────────────┘

错误示例：
resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.db.name
  password = "MySecretPassword123!"  # 错误：硬编码密码
}

正确示例：
variable "db_password" {
  description = "数据库密码"
  type        = string
  sensitive   = true
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.db.name
  password = var.db_password
}

┌─────────────────────────────────────────────────────────────────┐
│  2. 使用环境变量存储敏感信息                             │
└─────────────────────────────────────────────────────────────────┘

# 设置环境变量
export TF_VAR_db_password="MySecretPassword123!"

# 在Terraform中使用
variable "db_password" {
  description = "数据库密码"
  type        = string
  sensitive   = true
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.db.name
  password = var.db_password
}

┌─────────────────────────────────────────────────────────────────┐
│  3. 使用Terraform Cloud变量存储敏感信息                     │
└─────────────────────────────────────────────────────────────────┘

# 在Terraform Cloud控制台中设置敏感变量
# 1. 进入工作空间
# 2. 点击"Variables"
# 3. 添加变量
# 4. 勾选"Sensitive"
# 5. 保存

# 在Terraform中使用
variable "db_password" {
  description = "数据库密码"
  type        = string
  sensitive   = true
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.db.name
  password = var.db_password
}

┌─────────────────────────────────────────────────────────────────┐
│  4. 使用KMS加密敏感信息                                 │
└─────────────────────────────────────────────────────────────────┘

# 加密数据
gcloud kms encrypt \
  --location=us-central1 \
  --keyring=my-keyring \
  --key=my-key \
  --plaintext-file=secret.txt \
  --ciphertext-file=secret.txt.encrypted

# 在Terraform中解密
data "google_kms_secret" "db_password" {
  ciphertext = file("secret.txt.encrypted")
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.db.name
  password = data.google_kms_secret.db_password.plaintext
}
```

### 7.2.2 访问控制

```hcl
# 使用最小权限原则

# 创建专用服务账号
resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Service Account"
}

# 分配最小必要权限
resource "google_project_iam_member" "terraform_compute_admin" {
  project = "my-project-id"
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# 而不是使用editor角色（权限过大）
# resource "google_project_iam_member" "terraform_editor" {
#   project = "my-project-id"
#   role    = "roles/editor"
#   member  = "serviceAccount:${google_service_account.terraform.email}"
# }

# 使用条件IAM限制访问
resource "google_project_iam_member" "terraform_compute_admin" {
  project = "my-project-id"
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"

  condition {
    title       = "Only allow from specific IP"
    expression  = "request.ip in ['1.2.3.4/32']"
    description = "Only allow access from specific IP address"
  }
}
```

### 7.2.3 网络安全

```hcl
# 限制防火墙规则范围

# 错误示例：过于宽泛
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # 错误：允许所有IP访问
}

# 正确示例：限制访问范围
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.0.0/8"]  # 正确：只允许内网访问
  target_tags   = ["ssh-server"]
}

# 使用目标标签限制资源
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  tags = ["ssh-server", "http-server"]

  network_interface {
    network = "default"
  }
}
```

---

## 7.3 性能优化最佳实践

### 7.3.1 并行执行

```hcl
# 利用Terraform的并行执行能力

# 错误示例：顺序创建资源
resource "google_compute_instance" "web_server_1" {
  name         = "web-server-1"
  machine_type = "e2-medium"
}

resource "google_compute_instance" "web_server_2" {
  name         = "web-server-2"
  machine_type = "e2-medium"
}

resource "google_compute_instance" "web_server_3" {
  name         = "web-server-3"
  machine_type = "e2-medium"
}

# 正确示例：使用count并行创建
resource "google_compute_instance" "web_server" {
  count        = 3
  name         = "web-server-${count.index}"
  machine_type = "e2-medium"
}

# 或使用for_each
resource "google_compute_instance" "web_server" {
  for_each = toset(["web", "db", "cache"])

  name         = "${each.key}-server"
  machine_type = "e2-medium"
}
```

### 7.3.2 状态文件优化

```hcl
# 使用远程后端提高性能

# 错误示例：使用本地后端
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# 正确示例：使用GCS后端
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"
  }
}

# 优化GCS后端性能
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"

    # 启用状态锁定
    # GCS后端默认支持状态锁定

    # 使用多区域存储桶提高可用性
    # bucket = "my-terraform-state"  # 多区域存储桶
  }
}
```

### 7.3.3 资源依赖优化

```hcl
# 避免不必要的依赖

# 错误示例：使用depends_on创建不必要的依赖
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.subnet,
    google_compute_firewall.firewall
  ]
}

# 正确示例：使用隐式依赖
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  tags = ["http-server"]
}

resource "google_compute_firewall" "firewall" {
  name    = "allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http-server"]
}
```

---

## 7.4 团队协作最佳实践

### 7.4.1 版本控制

```bash
# .gitignore配置

# Terraform文件
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfvars
!terraform.tfvars.example
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# 敏感文件
*.key
*.pem
*.p12
*.pfx
service-account.json
credentials.json

# 操作系统文件
.DS_Store
Thumbs.db
```

### 7.4.2 代码审查

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Format
      run: terraform fmt -check

    - name: Terraform Init
      run: terraform init

    - name: Terraform Validate
      run: terraform validate

    - name: Terraform Plan
      run: terraform plan -out=tfplan

    - name: Terraform Security Scan
      uses: aquasecurity/tfsec-action@v1.0.0
      with:
        additional_args: "--soft-fail"
```

### 7.4.3 文档规范

```markdown
# README.md模板

# Terraform模块：VPC网络

## 描述

创建GCP VPC网络，支持自定义配置。

## 使用方法

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_id   = "my-project-id"
  network_name = "my-vpc"
  routing_mode = "REGIONAL"
}
```

## 输入变量

| 名称 | 描述 | 类型 | 默认值 | 必需 |
|------|--------|------|----------|------|
| project_id | GCP项目ID | string | - | 是 |
| network_name | VPC网络名称 | string | default-network | 否 |
| routing_mode | 路由模式 | string | REGIONAL | 否 |

## 输出值

| 名称 | 描述 |
|------|--------|
| network_id | VPC网络ID |
| network_name | VPC网络名称 |

## 示例

### 基础使用

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_id = "my-project-id"
  network_name = "production-vpc"
}
```

### 高级配置

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_id = "my-project-id"
  network_name = "production-vpc"
  routing_mode = "GLOBAL"
  mtu = 1460
}
```

## 要求

| 名称 | 版本 |
|------|------|
| Terraform | >= 1.0 |
| Provider | ~> 4.0 |

## 作者

Your Name <your.email@example.com>

## 许可证

MIT
```

---

## 7.5 故障排查最佳实践

### 7.5.1 常见问题排查

```bash
# 问题1：状态锁定

# 查看状态锁定信息
terraform force-unlock <LOCK_ID>

# 问题2：状态不一致

# 刷新状态
terraform refresh

# 导入现有资源
terraform import <RESOURCE_ADDRESS> <IMPORT_ID>

# 问题3：依赖循环

# 查看依赖关系
terraform graph | dot -Tpng > dependency-graph.png

# 问题4：资源创建失败

# 查看详细日志
TF_LOG=DEBUG terraform apply

# 问题5：变量未定义

# 检查变量定义
terraform validate

# 查看变量使用
terraform plan -var-file="terraform.tfvars"
```

### 7.5.2 日志记录

```bash
# 启用调试日志
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# 运行Terraform
terraform apply

# 查看日志
cat terraform.log

# 日志级别：
# TRACE：最详细的日志
# DEBUG：调试信息
# INFO：一般信息
# WARN：警告信息
# ERROR：错误信息
```

### 7.5.3 状态恢复

```bash
# 备份状态文件
terraform state pull > backup.tfstate

# 恢复状态文件
terraform state push backup.tfstate

# 列出状态中的资源
terraform state list

# 从状态中移除资源
terraform state rm <RESOURCE_ADDRESS>

# 移动资源
terraform state mv <SOURCE_ADDRESS> <DESTINATION_ADDRESS>
```

---

## 7.6 成本管理最佳实践

### 7.6.1 资源标签

```hcl
# 使用标签追踪成本

# 定义标签变量
variable "tags" {
  description = "资源标签"
  type = map(string)
  default = {
    environment = "production"
    managed_by   = "terraform"
    project      = "web-app"
    team         = "platform"
    cost_center  = "engineering"
  }
}

# 在所有资源上应用标签
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  labels       = var.tags
}

resource "google_compute_network" "vpc" {
  name   = "production-vpc"
  labels = var.tags
}

resource "google_storage_bucket" "state_bucket" {
  name   = "my-terraform-state"
  labels = var.tags
}
```

### 7.6.2 资源优化

```hcl
# 使用预留实例降低成本

# 错误示例：使用按需实例
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  scheduling {
    preemptible       = false
    automatic_restart = true
  }
}

# 正确示例：使用预留实例
resource "google_compute_reservation" "web_reservation" {
  name = "web-reservation"
  zone = "us-central1-a"

  specific_sku {
    count = 3
    name  = "e2-medium"
  }

  commitment {
    plan = "MONTHLY"
  }
}

resource "google_compute_instance" "web_server" {
  count        = 3
  name         = "web-server-${count.index}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  scheduling {
    preemptible       = false
    automatic_restart = true
  }

  reservation_affinity {
    type = "SPECIFIC_RESERVATION"
    key  = "compute.googleapis.com/reservation-name"
    values = [
      google_compute_reservation.web_reservation.name
    ]
  }
}

# 使用抢占式实例降低成本
resource "google_compute_instance" "batch_worker" {
  count        = 5
  name         = "batch-worker-${count.index}"
  machine_type = "e2-medium"

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}
```

### 7.6.3 存储优化

```hcl
# 使用生命周期策略优化存储成本

resource "google_storage_bucket" "data_bucket" {
  name          = "my-data-bucket"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}
```

---

## 7.7 监控和告警

### 7.7.1 资源监控

```hcl
# 监控资源使用情况

resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"

  conditions {
    display_name = "CPU Usage > 80%"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id
  ]
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification"
  type         = "email"
  labels = {
    email_address = "admin@example.com"
  }
}
```

### 7.7.2 成本监控

```hcl
# 监控成本

resource "google_billing_budget" "monthly_budget" {
  billing_account = "billingAccounts/123456-7890AB-ABCDEF"
  display_name   = "Monthly Budget"

  budget_filter {
    projects = ["projects/my-project-id"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "1000"
    }
  }

  threshold_rules {
    threshold_percent = 90.0
    spend_basis      = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 100.0
    spend_basis      = "CURRENT_SPEND"
  }

  all_updates_rule {
    pubsub_topic = google_pubsub_topic.budget_alerts.id
  }
}

resource "google_pubsub_topic" "budget_alerts" {
  name = "budget-alerts"
}
```

---

## 7.8 自动化最佳实践

### 7.8.1 CI/CD集成

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

permissions:
  contents: 'read'
  id-token: 'write'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Format
      run: terraform fmt -check

    - name: Terraform Init
      run: terraform init

    - name: Terraform Validate
      run: terraform validate

  plan:
    needs: validate
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v2
      with:
        project_id: ${{ env.TF_VAR_project_id }}
        workload_identity_provider: projects/my-project-id/locations/global/workloadIdentityPools/github-actions/providers/github-actions-provider
        service_account: terraform@my-project-id.iam.gserviceaccount.com

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Init
      run: terraform init

    - name: Terraform Plan
      run: terraform plan -out=tfplan

    - name: Save Plan
      uses: actions/upload-artifact@v4
      with:
        name: tfplan
        path: tfplan

  apply:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v2
      with:
        project_id: ${{ env.TF_VAR_project_id }}
        workload_identity_provider: projects/my-project-id/locations/global/workloadIdentityPools/github-actions/providers/github-actions-provider
        service_account: terraform@my-project-id.iam.gserviceaccount.com

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Init
      run: terraform init

    - name: Download Plan
      uses: actions/download-artifact@v4
      with:
        name: tfplan

    - name: Terraform Apply
      run: terraform apply tfplan
```

### 7.8.2 自动化脚本

```bash
#!/bin/bash
# scripts/apply.sh

set -e

# 设置环境变量
export TF_VAR_project_id="${TF_VAR_project_id:-my-project-id}"
export TF_VAR_region="${TF_VAR_region:-us-central1}"

# 初始化
terraform init

# 格式化代码
terraform fmt -check

# 验证配置
terraform validate

# 查看执行计划
terraform plan -out=tfplan

# 应用配置
terraform apply tfplan

# 输出结果
terraform output -json > outputs.json

echo "Terraform apply completed successfully"
```

---

## 本章小结

- 使用标准项目结构
- 避免硬编码敏感信息
- 使用最小权限原则
- 利用并行执行提高性能
- 使用远程后端管理状态
- 建立代码审查流程
- 编写完善的文档
- 掌握故障排查技巧
- 实施成本管理策略
- 集成监控和告警
- 自动化CI/CD流程

---

**附录：Terraform命令速查**

```bash
# 基础命令
terraform init              # 初始化
terraform validate          # 验证配置
terraform fmt               # 格式化代码
terraform plan              # 查看执行计划
terraform apply             # 应用配置
terraform destroy           # 销毁资源

# 状态管理
terraform state list        # 列出状态中的资源
terraform state show        # 显示资源详细信息
terraform state pull        # 拉取状态文件
terraform state push        # 推送状态文件
terraform state rm          # 从状态中移除资源
terraform state mv          # 移动资源

# 工作空间
terraform workspace list    # 列出工作空间
terraform workspace show    # 显示当前工作空间
terraform workspace new     # 创建新工作空间
terraform workspace select  # 切换工作空间
terraform workspace delete  # 删除工作空间

# 导入
terraform import           # 导入现有资源

# 输出
terraform output            # 显示输出值
terraform output -json      # 以JSON格式显示输出值

# 调试
TF_LOG=DEBUG terraform apply  # 启用调试日志
terraform graph            # 生成依赖关系图
terraform force-unlock     # 强制解锁状态

# 其他
terraform providers        # 显示Provider信息
terraform version          # 显示Terraform版本
terraform login            # 登录Terraform Cloud
```

---

**推荐资源**

- 官方文档：https://www.terraform.io/docs
- GCP Provider文档：https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Terraform最佳实践：https://www.terraform.io/docs/cloud/guides/recommended-practices
- Terraform模块注册表：https://registry.terraform.io
- Terraform社区论坛：https://discuss.hashicorp.com/c/terraform-core
