# Terraform与GCP集成

## 5.1 GCP Provider配置

### 5.1.1 Provider基础配置

```
GCP Provider配置层次：

┌─────────────────────────────────────────────────────────────────┐
│  Provider配置方式                                         │
└─────────────────────────────────────────────────────────────────┘

方式1：硬编码配置（不推荐）
provider "google" {
  project = "my-project-id"
  region  = "us-central1"
  zone    = "us-central1-a"
}

问题：
├── 配置硬编码，不灵活
├── 无法多环境部署
├── 敏感信息暴露
└── 不符合安全最佳实践

方式2：使用变量（推荐）
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP可用区"
  type        = string
  default     = "us-central1-a"
}

优势：
├── 配置灵活，易于修改
├── 支持多环境部署
├── 敏感信息隔离
└── 符合安全最佳实践

方式3：使用环境变量（推荐）
provider "google" {
  project = var.project_id
  region  = var.region
}

# 使用环境变量
export TF_VAR_project_id="my-project-id"
export TF_VAR_region="us-central1"

优势：
├── 配置与代码分离
├── 支持CI/CD集成
├── 敏感信息不进入代码库
└── 符合12-Factor App原则
```

### 5.1.2 Provider版本管理

```hcl
# 指定Provider版本
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# 版本约束说明：
# ~> 4.0  : 允许4.x版本，但不包括5.0
# >= 4.0  : 允许4.0及以上版本
# = 4.0   : 只允许4.0版本
# 4.0     : 等同于= 4.0

# 使用最新版本（不推荐生产环境）
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "latest"
    }
  }
}
```

### 5.1.3 多Provider配置

```hcl
# 场景：跨区域部署
provider "google" {
  alias   = "us-central"
  project = "my-project-id"
  region  = "us-central1"
}

provider "google" {
  alias   = "europe-west"
  project = "my-project-id"
  region  = "europe-west1"
}

# 使用Provider别名
resource "google_compute_instance" "us_instance" {
  provider = google.us-central
  name     = "us-server"
  zone     = "us-central1-a"
  # ...
}

resource "google_compute_instance" "europe_instance" {
  provider = google.europe-west
  name     = "europe-server"
  zone     = "europe-west1-b"
  # ...
}
```

---

## 5.2 GCP认证方式

### 5.2.1 认证方式对比

```
GCP认证方式对比：

┌─────────────────────────────────────────────────────────────────┐
│  1. Application Default Credentials (ADC)               │
└─────────────────────────────────────────────────────────────────┘

原理：
├── Terraform自动查找凭证
├── 优先级：
│   1. 环境变量 GOOGLE_CREDENTIALS
│   2. 环境变量 GOOGLE_APPLICATION_CREDENTIALS
│   3. gcloud auth application-default login
│   4. 服务账号文件
│   5. 元数据服务（GCE实例）
└── 适合：本地开发和测试

配置：
# 方法1：使用gcloud CLI
gcloud auth application-default login

# 方法2：设置环境变量
export GOOGLE_CREDENTIALS=$(cat ~/service-account-key.json)

# 方法3：使用ADC
gcloud auth application-default login

优势：
├── 简单易用
├── 无需额外配置
├── 支持多种凭证源
└── 适合开发环境

劣势：
├── 不适合CI/CD
├── 凭证管理不集中
└── 安全性较低

┌─────────────────────────────────────────────────────────────────┐
│  2. 服务账号密钥 (Service Account Key)                │
└─────────────────────────────────────────────────────────────────┘

原理：
├── 使用JSON格式的服务账号密钥
├── 直接在Provider中指定
├── 密钥包含：project_id、private_key、client_email
└── 适合：CI/CD和自动化

配置：
provider "google" {
  credentials = file("service-account-key.json")
  project     = "my-project-id"
}

# 或使用环境变量
export GOOGLE_CREDENTIALS=$(cat service-account-key.json)
provider "google" {
  project = "my-project-id"
}

优势：
├── 适合CI/CD
├── 凭证管理集中
├── 支持细粒度权限
└── 安全性较高

劣势：
├── 密钥管理复杂
├── 密钥轮换困难
├── 密钥泄露风险
└── 需要安全存储

┌─────────────────────────────────────────────────────────────────┐
│  3. Workload Identity Federation                       │
└─────────────────────────────────────────────────────────────────┘

原理：
├── 使用OIDC协议
├── 无需长期凭证
├── 临时访问令牌
├── 支持GitHub Actions、GitLab CI等
└── 适合：云原生CI/CD

配置：
# GitHub Actions示例
provider "google" {
  project = "my-project-id"
}

# GitHub Actions配置
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    project_id: my-project-id
    workload_identity_provider: projects/my-project-id/locations/global/workloadIdentityPools/github-actions/providers/github-actions
    service_account: terraform@my-project-id.iam.gserviceaccount.com

优势：
├── 无需长期凭证
├── 安全性最高
├── 支持云原生CI/CD
├── 自动令牌轮换
└── 符合安全最佳实践

劣势：
├── 配置复杂
├── 需要额外设置
└── 学习成本高
```

### 5.2.2 服务账号配置实战

**步骤1：创建服务账号**

```bash
# 1. 创建服务账号
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account" \
  --description="Service account for Terraform"

# 输出：
# Created service account [terraform@my-project-id.iam.gserviceaccount.com].

# 2. 分配角色
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/editor"

# 或使用更细粒度的角色
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# 3. 创建密钥
gcloud iam service-accounts keys create terraform@my-project-id.iam.gserviceaccount.com \
  --key-file-type=json \
  --key-file=terraform-key.json

# 输出：
# created key [abcd1234] of type [json] as [terraform-key.json] for
# [terraform@my-project-id.iam.gserviceaccount.com].

# 4. 保护密钥文件
chmod 600 terraform-key.json
echo "terraform-key.json" >> .gitignore
```

**步骤2：配置Terraform**

```hcl
# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  credentials = file("terraform-key.json")
  project     = "my-project-id"
  region      = "us-central1"
}

resource "google_compute_network" "vpc" {
  name = "terraform-network"
}
```

**步骤3：验证配置**

```bash
# 1. 初始化
terraform init

# 2. 验证配置
terraform validate

# 3. 查看执行计划
terraform plan

# 4. 应用配置
terraform apply -auto-approve

# 5. 验证资源创建
gcloud compute networks list
# NAME: terraform-network
```

### 5.2.3 Workload Identity配置实战

**步骤1：配置Workload Identity Pool**

```bash
# 1. 创建Workload Identity Pool
gcloud iam workload-identity-pools create github-actions \
  --location="global" \
  --display-name="GitHub Actions Pool"

# 2. 创建Workload Identity Provider
gcloud iam workload-identity-pools providers create github-actions-provider \
  --workload-identity-pool="github-actions" \
  --location="global" \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub"

# 3. 配置Provider属性映射
gcloud iam workload-identity-pools providers update-attribute-condition github-actions-provider \
  --workload-identity-pool="github-actions" \
  --location="global" \
  --attribute-condition="attribute.repository==my-org/my-repo"

# 4. 授予服务账号Impersonation权限
gcloud iam service-accounts add-iam-policy-binding terraform@my-project-id.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/my-project-id/locations/global/workloadIdentityPools/github-actions/attribute.repository/my-org/my-repo"
```

**步骤2：配置GitHub Actions**

```yaml
# .github/workflows/terraform.yml
name: Terraform Apply

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

permissions:
  contents: 'read'
  id-token: 'write'

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v2
      with:
        project_id: my-project-id
        workload_identity_provider: projects/my-project-id/locations/global/workloadIdentityPools/github-actions/providers/github-actions-provider
        service_account: terraform@my-project-id.iam.gserviceaccount.com

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0

    - name: Terraform Init
      run: terraform init

    - name: Terraform Plan
      run: terraform plan

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve
```

---

## 5.3 GCP资源管理

### 5.3.1 计算资源

**创建VM实例：**

```hcl
# main.tf
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    auto_delete = true
    type       = "pd-balanced"
    size       = 50
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  tags = ["web-server", "http-server"]

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }

  metadata = {
    ssh-keys = "user:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }
}

output "instance_id" {
  value = google_compute_instance.web_server.id
}

output "external_ip" {
  value = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}
```

**创建实例模板：**

```hcl
resource "google_compute_instance_template" "web_template" {
  name        = "web-server-template"
  machine_type = "e2-medium"
  region      = "us-central1"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot        = true
    disk_size_gb = 50
    disk_type    = "pd-balanced"
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl start nginx
    EOT
  }

  labels = {
    environment = "production"
    role        = "web"
  }
}
```

**创建实例组：**

```hcl
resource "google_compute_instance_group_manager" "web_group" {
  name        = "web-server-group"
  base_instance_name = "web-server"
  zone        = "us-central1-a"
  target_size = 3

  version {
    name = "v1"
    instance_template = google_compute_instance_template.web_template.id
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    most_disruptive_action = "RESTART"
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check {
      http_health_check {
        port         = 80
        request_path = "/"
      }
    }
  }
}
```

### 5.3.2 网络资源

**创建VPC网络：**

```hcl
resource "google_compute_network" "vpc_network" {
  name                    = "production-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"

  description = "Production VPC network managed by Terraform"

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}

output "vpc_id" {
  value = google_compute_network.vpc_network.id
}

output "vpc_name" {
  value = google_compute_network.vpc_network.name
}
```

**创建子网：**

```hcl
resource "google_compute_subnetwork" "subnet_public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = false
  secondary_ip_range {
    range_name    = "secondary-range"
    ip_cidr_range = "10.0.1.128/26"
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling      = 0.5
    metadata          = "INCLUDE_ALL_METADATA"
  }

  labels = {
    environment = "production"
    type        = "public"
  }
}

resource "google_compute_subnetwork" "subnet_private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true

  labels = {
    environment = "production"
    type        = "private"
  }
}
```

**创建防火墙规则：**

```hcl
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["ssh-server"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_tags = ["ssh-server", "http-server"]
  target_tags = ["ssh-server", "http-server"]
}
```

### 5.3.3 存储资源

**创建存储桶：**

```hcl
resource "google_storage_bucket" "state_bucket" {
  name          = "my-terraform-state"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  logging {
    log_bucket = google_storage_bucket.log_bucket.id
  }

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}

resource "google_storage_bucket" "log_bucket" {
  name          = "my-terraform-logs"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
```

**创建Cloud SQL实例：**

```hcl
resource "google_sql_database_instance" "master" {
  name             = "master-db"
  database_version = "POSTGRES_14"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    database_flags {
      name  = "max_connections"
      value = "100"
    }

    ip_configuration {
      authorized_networks {
        name = "allow-vpc"
        value = google_compute_subnetwork.subnet_private.ip_cidr_range
      }

      private_network {
        network_id = google_compute_network.vpc_network.id
      }
    }

    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      transaction_log_retention_days = 7
      point_in_time_recovery_enabled = true
    }

    maintenance_window {
      day  = 7
      hour = 3
    }
  }

  deletion_protection = true

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}

resource "google_sql_database" "app_db" {
  name     = "app"
  instance = google_sql_database_instance.master.name
  charset  = "UTF8"
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.master.name
  password = var.db_password
}
```

### 5.3.4 负载均衡资源

**创建负载均衡器：**

```hcl
resource "google_compute_region_health_check" "health_check" {
  name               = "web-health-check"
  region             = "us-central1"

  http_health_check {
    port         = 80
    request_path = "/"
    proxy_header = "NONE"
  }
}

resource "google_compute_region_backend_service" "web_backend" {
  name                  = "web-backend"
  region                = "us-central1"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_region_health_check.health_check.id]

  backend {
    group = google_compute_instance_group_manager.web_group.id
  }
}

resource "google_compute_region_url_map" "web_url_map" {
  name            = "web-url-map"
  region          = "us-central1"
  default_service = google_compute_region_backend_service.web_backend.id
}

resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "web-proxy"
  region  = "us-central1"
  url_map = google_compute_region_url_map.web_url_map.id
}

resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = ["80-80"]
  ip_protocol = "TCP"
}
```

---

## 5.4 GCP高级功能

### 5.4.1 使用Terraform导入现有资源

```bash
# 场景：将现有GCP资源导入到Terraform管理

# 1. 创建Terraform配置
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

resource "google_compute_network" "existing_vpc" {
  name = "existing-network"
}
EOF

# 2. 初始化
terraform init

# 3. 导入资源
terraform import \
  google_compute_network.existing_vpc \
  projects/my-project-id/global/networks/existing-network

# 输出：
# Import successful!
#
# The resources that were imported are shown above. These resources are now in
# your Terraform state and will henceforth be managed by Terraform.

# 4. 验证导入
terraform state list
# google_compute_network.existing_vpc

terraform show google_compute_network.existing_vpc

# 5. 查看执行计划
terraform plan
# 应该显示：No changes. Infrastructure is up-to-date.
```

### 5.4.2 使用Terraform数据源

```hcl
# 使用数据源查询现有资源
data "google_compute_network" "existing_vpc" {
  name = "existing-network"
}

data "google_compute_subnetwork" "existing_subnet" {
  name   = "existing-subnet"
  region = "us-central1"
}

data "google_compute_image" "debian_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

data "google_compute_zones" "available_zones" {
  region = "us-central1"
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = data.google_compute_zones.available_zones.names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.existing_subnet.id
  }
}

output "available_zones" {
  value = data.google_compute_zones.available_zones.names
}
```

### 5.4.3 使用Terraform Provisioners

```hcl
# 使用Provisioner在资源创建后执行操作
resource "google_compute_instance" "web_server" {
  name         = "web-server"
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

  # 连接信息
  connection {
    type        = "ssh"
    user        = "root"
    host        = self.network_interface[0].access_config[0].nat_ip
    private_key = file("~/.ssh/id_rsa")
  }

  # 在VM创建后执行命令
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y nginx",
      "systemctl start nginx",
      "ufw allow 80/tcp",
      "ufw allow 443/tcp",
      "ufw enable"
    ]
  }

  # 复制文件到VM
  provisioner "file" {
    source      = "nginx.conf"
    destination = "/etc/nginx/nginx.conf"
  }
}
```

---

## 5.5 GCP Terraform实战案例

### 5.5.1 案例：构建三层架构

**架构图：**

```
┌─────────────────────────────────────────────────────────────────┐
│                    三层架构                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  负载均衡层 (Load Balancer)                              │
│  ┌─────────────────────────────────────────────────────┐      │
│  │  Google Cloud Load Balancer                     │      │
│  │  - 外部负载均衡                                   │      │
│  │  - 健康检查                                      │      │
│  │  - SSL终止                                        │      │
│  └─────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  应用层 (Application Layer)                               │
│  ┌─────────────────────────────────────────────────────┐      │
│  │  Compute Instance Group (3 instances)           │      │
│  │  - web-server-1 (us-central1-a)                │      │
│  │  - web-server-2 (us-central1-b)                │      │
│  │  - web-server-3 (us-central1-c)                │      │
│  │  - 自动扩缩容                                      │      │
│  │  - 健康检查                                      │      │
│  └─────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  数据层 (Data Layer)                                      │
│  ┌─────────────────────────────────────────────────────┐      │
│  │  Cloud SQL (PostgreSQL)                         │      │
│  │  - 高可用                                        │      │
│  │  - 自动备份                                      │      │
│  │  - 只读副本                                      │      │
│  └─────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

**Terraform配置：**

```hcl
# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"
  }
}

provider "google" {
  project = "my-project-id"
  region  = "us-central1"
}

# VPC网络
resource "google_compute_network" "vpc" {
  name                    = "production-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# 子网
resource "google_compute_subnetwork" "subnet_public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet_private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# 防火墙规则
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# 实例模板
resource "google_compute_instance_template" "web_template" {
  name        = "web-server-template"
  machine_type = "e2-medium"
  region      = "us-central1"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot        = true
    disk_size_gb = 50
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_public.id
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl start nginx
    EOT
  }
}

# 实例组
resource "google_compute_instance_group_manager" "web_group" {
  name        = "web-server-group"
  base_instance_name = "web-server"
  zone        = "us-central1-a"
  target_size = 3

  version {
    name = "v1"
    instance_template = google_compute_instance_template.web_template.id
  }

  named_port {
    name = "http"
    port = 80
  }
}

# 健康检查
resource "google_compute_region_health_check" "health_check" {
  name               = "web-health-check"
  region             = "us-central1"

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# 后端服务
resource "google_compute_region_backend_service" "web_backend" {
  name                  = "web-backend"
  region                = "us-central1"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_region_health_check.health_check.id]

  backend {
    group = google_compute_instance_group_manager.web_group.id
  }
}

# URL映射
resource "google_compute_region_url_map" "web_url_map" {
  name            = "web-url-map"
  region          = "us-central1"
  default_service = google_compute_region_backend_service.web_backend.id
}

# HTTP代理
resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "web-proxy"
  region  = "us-central1"
  url_map = google_compute_region_url_map.web_url_map.id
}

# 转发规则
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = ["80-80"]
  ip_protocol = "TCP"
}

# Cloud SQL
resource "google_sql_database_instance" "db" {
  name             = "production-db"
  database_version = "POSTGRES_14"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      private_network {
        network_id = google_compute_network.vpc.id
      }
    }

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = true
}

# 数据库
resource "google_sql_database" "app_db" {
  name     = "app"
  instance = google_sql_database_instance.db.name
}

# 输出
output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.web_forwarding_rule.ip_address
}

output "db_connection_name" {
  value = google_sql_database_instance.db.connection_name
}
```

**部署流程：**

```bash
# 1. 初始化
terraform init

# 2. 验证配置
terraform validate

# 3. 查看执行计划
terraform plan

# 4. 应用配置
terraform apply -auto-approve

# 5. 验证资源
gcloud compute forwarding-rules list
gcloud compute instance-groups list
gcloud sql instances list

# 6. 测试应用
curl http://$(terraform output load_balancer_ip)
# 应该返回Nginx欢迎页面
```

### 5.5.2 案例：CI/CD集成

**GitHub Actions配置：**

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

env:
  TF_VAR_project_id: my-project-id
  TF_VAR_region: us-central1

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

    - name: Terraform Apply
      run: terraform apply tfplan

    - name: Terraform Output
      run: terraform output -json > outputs.json

    - name: Save Outputs
      uses: actions/upload-artifact@v4
      with:
        name: outputs
        path: outputs.json
```

---

## 本章小结

- GCP Provider支持多种配置方式
- 推荐使用变量和环境变量
- 服务账号密钥适合CI/CD
- Workload Identity提供最高安全性
- Terraform可以管理所有GCP资源
- 支持导入现有资源
- 支持使用数据源查询资源
- 支持Provisioner执行配置任务
- 可以集成到CI/CD流水线

---

**下一章：Terraform高级特性**
