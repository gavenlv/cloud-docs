# Terraform状态管理深度解析

## 2.1 状态文件格式详解

### 2.1.1 状态文件版本演进

```
Terraform状态文件版本历史：

Version 1 (Terraform 0.12之前)
├── 简单的JSON格式
├── 缺少资源实例概念
└── 不支持count/for_each

Version 2 (Terraform 0.12)
├── 引入资源实例概念
├── 支持count和for_each
└── 改进依赖追踪

Version 3 (Terraform 0.13)
├── 改进provider配置
├── 支持provider源
└── 更好的模块支持

Version 4 (Terraform 1.0+)
├── 完整的JSON Schema
├── 改进敏感数据处理
├── 支持provider版本锁定
└── 更好的向后兼容性
```

### 2.1.2 状态文件完整结构

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 42,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {
    "vpc_id": {
      "type": "string",
      "value": "projects/my-project/global/networks/my-vpc"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "google_compute_network",
      "name": "main_vpc",
      "provider": "provider[\"registry.terraform.io/hashicorp/google\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "name": "my-vpc",
            "id": "projects/my-project/global/networks/my-vpc",
            "self_link": "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/my-vpc",
            "auto_create_subnetworks": false,
            "routing_config": [],
            "mtu": 1460
          },
          "sensitive_attributes": [],
          "private": "eyJz...加密的敏感数据...="
        }
      ]
    },
    {
      "mode": "data",
      "type": "google_compute_image",
      "name": "debian_image",
      "provider": "provider[\"registry.terraform.io/hashicorp/google\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "name": "debian-11-bullseye-v20231010",
            "source_image": "projects/debian-cloud/global/images/family/debian-11"
          }
        }
      ]
    }
  ]
}
```

**字段详解：**

- `version`: 状态文件格式版本（当前为4）
- `terraform_version`: 创建此状态的Terraform版本
- `serial`: 状态文件版本号，每次变更递增
- `lineage`: 状态文件唯一标识符（UUID）
- `outputs`: 输出值
- `resources`: 资源列表
  - `mode`: `managed`（资源）或 `data`（数据源）
  - `type`: 资源类型
  - `name`: 资源名称
  - `provider`: provider引用
  - `instances`: 资源实例数组（支持count/for_each）
    - `schema_version`: 资源schema版本
    - `attributes`: 资源属性
    - `sensitive_attributes`: 敏感属性索引
    - `private`: 加密的私有数据

---

## 2.2 状态锁定机制

### 2.2.1 锁定流程

```
状态锁定完整流程：

┌─────────────────────────────────────────────────────────────────┐
│  步骤1：尝试获取锁                                     │
└─────────────────────────────────────────────────────────────────┘

terraform apply
    │
    ├── 读取当前状态
    ├── 检查是否已锁定
    │
    ├── 未锁定？
    │   ├── 创建锁文件
    │   ├── 写入锁信息（用户、时间、PID）
    │   └── 获取锁成功 ✓
    │
    └── 已锁定？
        ├── 读取锁信息
        ├── 检查锁是否过期
        │   ├── 已过期？
        │   │   ├── 强制覆盖锁
        │   │   └── 获取锁成功 ✓
        │   │
        │   └── 未过期？
        │       ├── 显示锁持有者信息
        │       ├── Error: Error acquiring the state lock
        │       └── 退出 ✗

┌─────────────────────────────────────────────────────────────────┐
│  步骤2：执行变更                                       │
└─────────────────────────────────────────────────────────────────┘

    │
    ├── 执行terraform plan
    ├── 执行terraform apply
    ├── 创建/更新/删除资源
    └── 更新状态文件

┌─────────────────────────────────────────────────────────────────┐
│  步骤3：释放锁                                       │
└─────────────────────────────────────────────────────────────────┘

    │
    ├── 删除锁文件
    ├── 释放锁成功 ✓
    └── 其他用户可以获取锁
```

### 2.2.2 锁信息结构

```json
{
  "ID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "Operation": "OperationTypeApply",
  "Info": {
    "Path": "/path/to/terraform.tfstate",
    "Who": "user@example.com",
    "Version": "1.5.0",
    "Created": "2024-01-15T10:30:00Z",
    "Updated": "2024-01-15T10:30:00Z"
  }
}
```

### 2.2.3 不同后端的锁定实现

**Local后端：**
```bash
# 锁文件位置
.terraform/terraform.tfstate.lock.info

# 强制解锁（危险！）
terraform force-unlock <LOCK_ID>

# 输出：
# Do you really want to force-unlock?
# Terraform will remove the lock on the remote state.
# This will allow others to potentially write to the state.
# Only 'yes' will be accepted to confirm.

# Enter a value: yes
# Successfully unlocked the state!
```

**GCS后端：**
```hcl
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
  }
}
```

```bash
# GCS使用对象锁机制
# 锁文件：gs://my-terraform-state/prod/.terraform.lock

# 查看锁状态
gsutil ls gs://my-terraform-state/prod/.terraform.lock

# 强制解锁
terraform force-unlock <LOCK_ID>
```

**S3后端：**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

```bash
# S3使用DynamoDB表进行锁定
# 表结构：
# {
#   "LockID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
#   "Info": "base64编码的锁信息"
# }

# 强制解锁
terraform force-unlock <LOCK_ID>
```

---

## 2.3 状态迁移

### 2.3.1 迁移场景

```
状态迁移常见场景：

场景1：本地到远程
┌─────────────────────────────────────────────────────────────────┐
│  本地状态                                             │
│  ├── terraform.tfstate（本地文件）                        │
│  └── .terraform/terraform.tfstate.lock.info               │
│                                                          │
│  迁移到GCS                                              │
│  ├── gs://terraform-state/prod/terraform.tfstate           │
│  └── gs://terraform-state/prod/.terraform.lock          │
└─────────────────────────────────────────────────────────────────┘

场景2：远程到远程
┌─────────────────────────────────────────────────────────────────┐
│  S3后端                                              │
│  ├── s3://terraform-state/terraform.tfstate              │
│  └── dynamodb://terraform-locks                         │
│                                                          │
│  迁移到GCS                                              │
│  ├── gs://terraform-state/terraform.tfstate               │
│  └── gs://terraform-state/.terraform.lock              │
└─────────────────────────────────────────────────────────────────┘

场景3：状态合并
┌─────────────────────────────────────────────────────────────────┐
│  状态A（VPC网络）                                     │
│  ├── terraform.tfstate                                    │
│  └── 包含：google_compute_network                     │
│                                                          │
│  状态B（计算资源）                                       │
│  ├── terraform.tfstate                                    │
│  └── 包含：google_compute_instance                    │
│                                                          │
│  合并后                                                │
│  ├── terraform.tfstate                                    │
│  └── 包含：网络 + 计算资源                            │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3.2 迁移实战：本地到GCS

**步骤1：配置GCS后端**

```hcl
# main.tf
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
  }

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

resource "google_storage_bucket" "state_bucket" {
  name          = "my-terraform-state"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}
```

**步骤2：创建状态存储桶**

```bash
# 初始化（使用本地后端）
terraform init

# 创建状态存储桶
terraform apply -target=google_storage_bucket.state_bucket

# 验证存储桶创建
gsutil ls gs://my-terraform-state
```

**步骤3：迁移状态**

```bash
# 方法1：使用terraform init -migrate-state
terraform init \
  -migrate-state \
  -backend-config="bucket=my-terraform-state" \
  -backend-config="prefix=prod"

# 输出：
# Initializing the backend...
# Do you want to copy existing state to the new backend?
#   Pre-existing state was found at "terraform.tfstate" while migrating
#   to "gcs". No existing state was found at "gcs".
#   Do you want to copy the state from "terraform.tfstate" to the new backend?
#   Enter a value: yes
#
# Successfully configured the backend "gcs"! Terraform will automatically
# use this backend unless you change configuration or run `terraform init` again.

# 方法2：手动迁移
# 1. 备份本地状态
cp terraform.tfstate terraform.tfstate.backup

# 2. 上传状态到GCS
gsutil cp terraform.tfstate gs://my-terraform-state/prod/terraform.tfstate

# 3. 删除本地状态
rm terraform.tfstate

# 4. 初始化远程后端
terraform init

# 5. 验证状态
terraform state list
```

**步骤4：验证迁移**

```bash
# 查看远程状态
terraform show

# 查看状态文件位置
terraform output -json | jq '.outputs'

# 测试状态锁定
terraform apply -auto-approve
# 应该成功获取GCS锁

# 在另一个终端测试
terraform apply -auto-approve
# 应该报错：Error acquiring the state lock
```

### 2.3.3 状态合并实战

**场景：合并两个独立的状态文件**

```bash
# 状态A：网络资源
cd terraform-network
terraform state list
# google_compute_network.vpc_network
# google_compute_subnetwork.subnet_a
# google_compute_subnetwork.subnet_b

# 状态B：计算资源
cd terraform-compute
terraform state list
# google_compute_instance.web_server
# google_compute_instance.db_server

# 合并步骤：
# 1. 创建新的工作目录
mkdir terraform-merged
cd terraform-merged

# 2. 创建合并后的配置
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

# 网络资源
resource "google_compute_network" "vpc_network" {
  name                    = "merged-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_a" {
  name          = "merged-subnet-a"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# 计算资源
resource "google_compute_instance" "web_server" {
  name         = "merged-web-server"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_a.id
  }
}
EOF

# 3. 导入网络资源
terraform import \
  google_compute_network.vpc_network \
  projects/my-project-id/global/networks/merged-network

terraform import \
  google_compute_subnetwork.subnet_a \
  projects/my-project-id/regions/us-central1/subnetworks/merged-subnet-a

# 4. 导入计算资源
terraform import \
  google_compute_instance.web_server \
  projects/my-project-id/zones/us-central1-a/instances/merged-web-server

# 5. 验证状态
terraform state list
# 应该包含所有导入的资源

# 6. 查看执行计划
terraform plan
# 应该显示：No changes. Infrastructure is up-to-date.
```

---

## 2.4 状态文件安全

### 2.4.1 敏感数据加密

```
敏感数据处理流程：

┌─────────────────────────────────────────────────────────────────┐
│  配置文件中的敏感数据                                    │
└─────────────────────────────────────────────────────────────────┘

resource "google_sql_database_instance" "master" {
  name             = "master-db"
  database_version = "POSTGRES_14"

  settings {
    tier = "db-f1-micro"

    database_flags {
      name  = "password_encryption"
      value = "true"
    }

    ip_configuration {
      authorized_networks {
        value = "192.168.1.0/24"
      }
    }
  }

  # 敏感数据：数据库密码
  root_password = var.db_password  # 从变量读取
}

┌─────────────────────────────────────────────────────────────────┐
│  状态文件中的敏感数据                                    │
└─────────────────────────────────────────────────────────────────┘

{
  "resources": [
    {
      "type": "google_sql_database_instance",
      "name": "master",
      "instances": [
        {
          "attributes": {
            "name": "master-db",
            "root_password": "my-secret-password"  # ← 明文存储！
          },
          "sensitive_attributes": [3]  # ← 标记为敏感
        }
      ]
    }
  ]
}

┌─────────────────────────────────────────────────────────────────┐
│  加密后的状态文件                                        │
└─────────────────────────────────────────────────────────────────┘

{
  "resources": [
    {
      "type": "google_sql_database_instance",
      "name": "master",
      "instances": [
        {
          "attributes": {
            "name": "master-db",
            "root_password": ""  # ← 移除敏感数据
          },
          "sensitive_attributes": [3],
          "private": "eyJz...加密的密码...="  # ← 加密存储
        }
      ]
    }
  ]
}
```

### 2.4.2 配置敏感数据保护

**方法1：使用变量和敏感输出**

```hcl
# variables.tf
variable "db_password" {
  type      = string
  sensitive = true  # 标记为敏感
}

# outputs.tf
output "db_connection_string" {
  sensitive = true  # 输出标记为敏感
  value     = "postgresql://user:${var.db_password}@host:5432/db"
}
```

```bash
# 使用环境变量传递敏感数据
export TF_VAR_db_password="my-secret-password"
terraform apply

# 或使用变量文件（不提交到版本控制）
cat > terraform.tfvars << 'EOF'
db_password = "my-secret-password"
EOF

# 添加到.gitignore
echo "terraform.tfvars" >> .gitignore
echo "*.auto.tfvars" >> .gitignore
```

**方法2：使用Vault集成**

```hcl
# 使用Vault provider
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

provider "vault" {
  address = "https://vault.example.com:8200"
  token   = var.vault_token
}

data "vault_generic_secret" "db_password" {
  path = "secret/data/db"
}

resource "google_sql_database_instance" "master" {
  name             = "master-db"
  database_version = "POSTGRES_14"

  root_password = data.vault_generic_secret.db_password.data["password"]
}
```

**方法3：使用GCP Secret Manager**

```hcl
data "google_secret_manager_secret_version" "db_password" {
  secret = "db-password"
}

resource "google_sql_database_instance" "master" {
  name             = "master-db"
  database_version = "POSTGRES_14"

  root_password = data.google_secret_manager_secret_version.db_password.secret_data
}
```

### 2.4.3 状态文件加密

**使用S3加密：**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # 启用S3加密
    kms_key_id    = "arn:aws:kms:us-east-1:123456789012:key/abcd1234"
  }
}
```

**使用GCS加密：**

```hcl
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
    encryption_key = "projects/my-project/locations/us/keyRings/my-keyring/cryptoKeys/my-key"
  }
}
```

---

## 2.5 状态文件维护

### 2.5.1 状态文件清理

```bash
# 查看状态中的所有资源
terraform state list

# 移除已删除的资源
terraform state rm google_compute_instance.old_server

# 移除多个资源
terraform state rm \
  google_compute_instance.server1 \
  google_compute_instance.server2 \
  google_compute_instance.server3

# 移除整个模块
terraform state rm module.vpc_module

# 查看特定资源状态
terraform state show google_compute_network.vpc_network
```

### 2.5.2 状态文件刷新

```bash
# 刷新状态文件（从云平台同步最新状态）
terraform refresh

# 输出：
# google_compute_network.vpc_network: Refreshing state... [id=projects/my-project/global/networks/my-vpc]
# google_compute_subnetwork.subnet_a: Refreshing state... [id=projects/my-project/regions/us-central1/subnetworks/my-subnet]
#
# Refresh complete! The state is up-to-date.

# 只刷新特定资源
terraform refresh -target=google_compute_network.vpc_network
```

### 2.5.3 状态文件备份

```bash
# 手动备份
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# 自动备份（使用terraform init）
terraform init -backend-config="backup=true"

# GCS自动备份
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
  }
}

# GCS会自动创建备份：
# gs://my-terraform-state/prod/terraform.tfstate
# gs://my-terraform-state/prod/terraform.tfstate.backup
```

---

## 2.6 实战：完整的状态管理流程

### 2.6.1 场景：团队协作中的状态管理

**项目结构：**

```bash
terraform-project/
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
│   ├── vpc/
│   ├── compute/
│   └── storage/
└── backend.tf
```

**backend.tf配置：**

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "${terraform.workspace}"
    credentials = "path/to/service-account.json"
  }
}
```

**环境配置：**

```hcl
# environments/prod/main.tf
terraform {
  required_version = ">= 1.0"
}

module "vpc" {
  source = "../../modules/vpc"

  name        = "prod-vpc"
  cidr        = "10.0.0.0/16"
  environment = "prod"
}

module "compute" {
  source = "../../modules/compute"

  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.subnet_ids[0]
  environment  = "prod"
  instance_count = 3
}
```

**工作空间管理：**

```bash
# 初始化工作空间
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 切换工作空间
terraform workspace list
# * default
#   dev
#   staging
#   prod

terraform workspace select prod

# 查看当前工作空间
terraform workspace show
# prod

# 在不同工作空间中应用
cd environments/prod
terraform workspace select prod
terraform apply

cd environments/dev
terraform workspace select dev
terraform apply

# 每个工作空间有独立的状态文件：
# gs://my-terraform-state/prod/terraform.tfstate
# gs://my-terraform-state/dev/terraform.tfstate
# gs://my-terraform-state/staging/terraform.tfstate
```

### 2.6.2 验证状态管理

```bash
# 1. 验证状态文件位置
terraform output -json | jq '.backend'

# 2. 验证状态文件内容
terraform show -json | jq '.resources | length'

# 3. 验证资源依赖关系
terraform graph | dot -Tpng > graph.png

# 4. 验证状态锁定
# 在终端1
terraform apply -auto-approve

# 在终端2（应该失败）
terraform apply -auto-approve
# Error acquiring the state lock

# 5. 验证状态刷新
terraform refresh
terraform plan
# 应该显示：No changes. Infrastructure is up-to-date.

# 6. 验证状态备份
gsutil ls gs://my-terraform-state/prod/
# terraform.tfstate
# terraform.tfstate.backup
```

---

## 2.7 常见问题排查

### 2.7.1 问题：状态文件损坏

**症状：**
```bash
terraform plan
# Error: Failed to read state: state data could not be decoded
```

**解决方案：**

```bash
# 1. 检查备份
ls -la terraform.tfstate*

# 2. 恢复备份
cp terraform.tfstate.backup terraform.tfstate

# 3. 验证状态
terraform state list

# 4. 如果没有备份，尝试刷新
terraform refresh
```

### 2.7.2 问题：状态锁定无法释放

**症状：**
```bash
terraform apply
# Error: Error acquiring the state lock
# Lock Info:
#   ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
#   Path:      gs://my-terraform-state/prod/.terraform.lock
#   Operation: OperationTypeApply
#   Who:       user@example.com
#   Version:   1.5.0
#   Created:   2024-01-15 10:30:00.000 UTC
#   Info:      1234567890@hostname
```

**解决方案：**

```bash
# 1. 检查锁是否过期
# 如果锁持有者已经完成操作，可以强制解锁

# 2. 强制解锁
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890

# 3. 验证
terraform plan
# 应该可以正常执行
```

### 2.7.3 问题：状态文件过大

**症状：**
```bash
terraform plan
# Warning: state file is large (50MB)
# This may cause performance issues
```

**解决方案：**

```bash
# 1. 分析状态文件大小
terraform show -json | jq 'length'

# 2. 查找大资源
terraform state list | while read resource; do
  size=$(terraform state show "$resource" | wc -c)
  echo "$resource: $size bytes"
done | sort -k2 -n

# 3. 考虑拆分状态
# 将大型资源拆分到独立的状态文件

# 4. 使用state replace-provider
terraform state replace-provider \
  -auto-approve \
  hashicorp/google \
  hashicorp/google
```

---

## 本章小结

- 状态文件格式经历了多次演进，当前为Version 4
- 状态锁定防止并发冲突，支持多种后端
- 状态迁移需要谨慎，建议先备份
- 敏感数据应该加密存储或使用外部密钥管理
- 定期维护状态文件，清理无用资源
- 使用工作空间隔离不同环境的状态

---

**下一章：Terraform模块化设计**
