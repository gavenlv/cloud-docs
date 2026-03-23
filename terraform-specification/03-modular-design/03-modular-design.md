# Terraform模块化设计

## 3.1 模块化原理

### 3.1.1 为什么需要模块化？

```
模块化解决的问题：

┌─────────────────────────────────────────────────────────────────┐
│  问题：代码重复                                           │
└─────────────────────────────────────────────────────────────────┘

项目A：创建VPC网络
├── main.tf（100行代码）
├── variables.tf（20行代码）
└── outputs.tf（10行代码）

项目B：创建VPC网络
├── main.tf（100行代码）← 重复！
├── variables.tf（20行代码）← 重复！
└── outputs.tf（10行代码）← 重复！

项目C：创建VPC网络
├── main.tf（100行代码）← 重复！
├── variables.tf（20行代码）← 重复！
└── outputs.tf（10行代码）← 重复！

问题：
├── 代码重复，维护成本高
├── 修改需要同步到所有项目
├── 容易出现不一致
└── 难以标准化

┌─────────────────────────────────────────────────────────────────┐
│  解决方案：模块化                                         │
└─────────────────────────────────────────────────────────────────┘

modules/
└── vpc/
    ├── main.tf（100行代码）
    ├── variables.tf（20行代码）
    └── outputs.tf（10行代码）

项目A：使用VPC模块
├── main.tf（10行代码）
└── terraform.tfvars（5行代码）

项目B：使用VPC模块
├── main.tf（10行代码）
└── terraform.tfvars（5行代码）

项目C：使用VPC模块
├── main.tf（10行代码）
└── terraform.tfvars（5行代码）

优势：
├── 代码复用，减少重复
├── 集中维护，一处修改处处生效
├── 标准化，确保一致性
└── 易于测试和验证
```

### 3.1.2 模块类型

```
Terraform模块类型：

┌─────────────────────────────────────────────────────────────────┐
│  1. 本地模块 (Local Modules)                           │
└─────────────────────────────────────────────────────────────────┘

结构：
project/
├── main.tf
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf

引用：
module "vpc" {
  source = "./modules/vpc"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

优势：
├── 简单直接，无需额外配置
├── 适合项目内部复用
├── 版本控制简单
└── 易于调试

┌─────────────────────────────────────────────────────────────────┐
│  2. 远程模块 (Remote Modules)                           │
└─────────────────────────────────────────────────────────────────┘

结构：
Git仓库：github.com/company/terraform-modules
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── storage/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

引用：
module "vpc" {
  source = "github.com/company/terraform-modules//vpc"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

优势：
├── 跨项目共享
├── 集中版本管理
├── 团队协作方便
└── 可以使用Git标签

┌─────────────────────────────────────────────────────────────────┐
│  3. Registry模块 (Terraform Registry)                  │
└─────────────────────────────────────────────────────────────────┘

结构：
registry.terraform.io/
├── hashicorp/vpc
├── hashicorp/consul
├── hashicorp/kubernetes
└── google-cloud-modules/vpc

引用：
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.0"

  project_id   = "my-project"
  network_name = "my-network"
}

优势：
├── 官方维护，质量保证
├── 社区验证，使用广泛
├── 版本管理规范
└── 文档完善
```

---

## 3.2 模块设计原则

### 3.2.1 单一职责原则

```
模块职责划分：

┌─────────────────────────────────────────────────────────────────┐
│  反例：大而全的模块                                   │
└─────────────────────────────────────────────────────────────────┘

module "everything" {
  source = "./modules/everything"

  # 包含VPC、子网、防火墙、路由、NAT、VM、负载均衡...
  # 职责不清，难以复用
}

问题：
├── 模块过于复杂
├── 难以理解和维护
├── 复用性差
└── 测试困难

┌─────────────────────────────────────────────────────────────────┐
│  正例：单一职责的模块                                   │
└─────────────────────────────────────────────────────────────────┘

modules/
├── vpc/              # 只负责VPC网络
├── subnet/            # 只负责子网
├── firewall/          # 只负责防火墙规则
├── compute/           # 只负责计算资源
├── load_balancer/     # 只负责负载均衡
└── storage/          # 只负责存储资源

优势：
├── 职责清晰，易于理解
├── 独立开发和测试
├── 灵活组合使用
└── 易于维护和扩展
```

### 3.2.2 可配置性原则

```
模块配置设计：

┌─────────────────────────────────────────────────────────────────┐
│  反例：硬编码配置                                       │
└─────────────────────────────────────────────────────────────────┘

# modules/vpc/main.tf
resource "google_compute_network" "vpc" {
  name = "production-network"  # 硬编码
  auto_create_subnetworks = false
}

问题：
├── 无法复用到其他环境
├── 修改需要改代码
└── 不灵活

┌─────────────────────────────────────────────────────────────────┐
│  正例：可配置的模块                                     │
└─────────────────────────────────────────────────────────────────┘

# modules/vpc/variables.tf
variable "name" {
  description = "VPC网络名称"
  type        = string
  default     = "default-network"
}

variable "auto_create_subnetworks" {
  description = "是否自动创建子网"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "路由模式"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL"
  }
}

# modules/vpc/main.tf
resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode           = var.routing_mode
}

# modules/vpc/outputs.tf
output "network_id" {
  description = "VPC网络ID"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "VPC网络名称"
  value       = google_compute_network.vpc.name
}

使用：
module "vpc" {
  source = "./modules/vpc"

  name        = "production-network"
  routing_mode = "REGIONAL"
}
```

### 3.2.3 最小化输出原则

```
模块输出设计：

┌─────────────────────────────────────────────────────────────────┐
│  反例：输出所有属性                                       │
└─────────────────────────────────────────────────────────────────┘

# modules/vpc/outputs.tf
output "vpc" {
  value = google_compute_network.vpc
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "vpc_self_link" {
  value = google_compute_network.vpc.self_link
}

output "vpc_gateway_ipv4" {
  value = google_compute_network.vpc.gateway_ipv4
}

output "vpc_routing_config" {
  value = google_compute_network.vpc.routing_config
}

问题：
├── 输出过多，信息过载
├── 调用者不需要所有属性
├── 增加维护成本
└── 容易产生依赖

┌─────────────────────────────────────────────────────────────────┐
│  正例：只输出必要属性                                   │
└─────────────────────────────────────────────────────────────────┘

# modules/vpc/outputs.tf
output "network_id" {
  description = "VPC网络ID，用于引用"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "VPC网络名称"
  value       = google_compute_network.vpc.name
}

output "self_link" {
  description = "VPC网络自链接，用于API调用"
  value       = google_compute_network.vpc.self_link
}

优势：
├── 输出精简，清晰明了
├── 只暴露必要信息
├── 减少依赖耦合
└── 易于维护
```

---

## 3.3 模块实战：VPC网络模块

### 3.3.1 模块结构

```bash
# 创建模块目录
mkdir -p modules/vpc
cd modules/vpc

# 创建模块文件
touch main.tf variables.tf outputs.tf README.md
```

### 3.3.2 模块实现

**variables.tf：**

```hcl
variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "network_name" {
  description = "VPC网络名称"
  type        = string
  default     = "default-network"
}

variable "auto_create_subnetworks" {
  description = "是否自动创建子网"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "路由模式：REGIONAL或GLOBAL"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be either REGIONAL or GLOBAL."
  }
}

variable "mtu" {
  description = "最大传输单元"
  type        = number
  default     = 1460

  validation {
    condition     = var.mtu >= 1300 && var.mtu <= 1460
    error_message = "mtu must be between 1300 and 1460."
  }
}

variable "delete_default_routes_on_create" {
  description = "创建时是否删除默认路由"
  type        = bool
  default     = false
}

variable "description" {
  description = "VPC网络描述"
  type        = string
  default     = "Managed by Terraform"
}

variable "labels" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}
```

**main.tf：**

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                            = var.network_name
  auto_create_subnetworks       = var.auto_create_subnetworks
  routing_mode                   = var.routing_mode
  mtu                             = var.mtu
  delete_default_routes_on_create = var.delete_default_routes_on_create
  description                     = var.description
  project                         = var.project_id
  labels                          = var.labels
}
```

**outputs.tf：**

```hcl
output "network_id" {
  description = "VPC网络ID"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "VPC网络名称"
  value       = google_compute_network.vpc.name
}

output "self_link" {
  description = "VPC网络自链接"
  value       = google_compute_network.vpc.self_link
}

output "gateway_ipv4" {
  description = "VPC网关IPv4地址"
  value       = google_compute_network.vpc.gateway_ipv4
}
```

**README.md：**

```markdown
# VPC网络模块

## 描述

创建GCP VPC网络，支持自定义配置。

## 使用方法

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_id = "my-project-id"
  network_name = "my-vpc"
  routing_mode = "REGIONAL"
}
```

## 输入变量

| 名称 | 描述 | 类型 | 默认值 | 必需 |
|------|--------|------|----------|------|
| project_id | GCP项目ID | string | - | 是 |
| network_name | VPC网络名称 | string | default-network | 否 |
| auto_create_subnetworks | 是否自动创建子网 | bool | false | 否 |
| routing_mode | 路由模式 | string | REGIONAL | 否 |
| mtu | 最大传输单元 | number | 1460 | 否 |
| delete_default_routes_on_create | 创建时删除默认路由 | bool | false | 否 |
| description | VPC网络描述 | string | Managed by Terraform | 否 |
| labels | 资源标签 | map(string) | {} | 否 |

## 输出值

| 名称 | 描述 |
|------|--------|
| network_id | VPC网络ID |
| network_name | VPC网络名称 |
| self_link | VPC网络自链接 |
| gateway_ipv4 | VPC网关IPv4地址 |

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
  delete_default_routes_on_create = true
  description = "Production VPC network"
  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}
```
```

### 3.3.3 模块测试

```bash
# 创建测试目录
mkdir -p examples/basic
cd examples/basic

# 创建测试配置
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

module "vpc" {
  source = "../../"

  project_id = "my-project-id"
  network_name = "test-vpc"
  routing_mode = "REGIONAL"
}
EOF

# 初始化
terraform init

# 验证配置
terraform validate

# 查看执行计划
terraform plan

# 应用配置
terraform apply -auto-approve

# 验证输出
terraform output network_id
terraform output network_name

# 销毁资源
terraform destroy -auto-approve
```

---

## 3.4 模块实战：计算实例模块

### 3.4.1 模块结构

```bash
# 创建模块目录
mkdir -p modules/compute
cd modules/compute

# 创建模块文件
touch main.tf variables.tf outputs.tf README.md
```

### 3.4.2 模块实现

**variables.tf：**

```hcl
variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "zone" {
  description = "可用区"
  type        = string
  default     = "us-central1-a"
}

variable "name" {
  description = "实例名称"
  type        = string
}

variable "machine_type" {
  description = "机器类型"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "启动镜像"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "network" {
  description = "网络ID或自链接"
  type        = string
}

variable "subnetwork" {
  description = "子网ID或自链接"
  type        = string
  default     = null
}

variable "tags" {
  description = "实例标签"
  type        = list(string)
  default     = []
}

variable "metadata" {
  description = "实例元数据"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

variable "boot_disk_type" {
  description = "启动磁盘类型"
  type        = string
  default     = "pd-balanced"
}

variable "boot_disk_size" {
  description = "启动磁盘大小（GB）"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_disk_size >= 10 && var.boot_disk_size <= 65536
    error_message = "boot_disk_size must be between 10 and 65536 GB."
  }
}

variable "service_account" {
  description = "服务账号邮箱"
  type        = string
  default     = null
}

variable "scopes" {
  description = "API访问范围"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "enable_shielded_vm" {
  description = "启用安全虚拟机"
  type        = bool
  default     = false
}

variable "confidential_compute" {
  description = "启用机密计算"
  type        = bool
  default     = false
}
```

**main.tf：**

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

resource "google_compute_instance" "instance" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = var.tags
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.image
    }
    auto_delete = true
    type       = var.boot_disk_type
    size       = var.boot_disk_size
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = var.metadata

  dynamic "service_account" {
    for_each = var.service_account != null ? [1] : []
    content {
      email  = var.service_account
      scopes = var.scopes
    }
  }

  shielded_instance_config {
    enable_secure_boot          = var.enable_shielded_vm
    enable_vtpm               = var.enable_shielded_vm
    enable_integrity_monitoring = var.enable_shielded_vm
  }

  confidential_instance_config {
    enable_confidential_compute = var.confidential_compute
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }
}
```

**outputs.tf：**

```hcl
output "instance_id" {
  description = "实例ID"
  value       = google_compute_instance.instance.id
}

output "instance_name" {
  description = "实例名称"
  value       = google_compute_instance.instance.name
}

output "self_link" {
  description = "实例自链接"
  value       = google_compute_instance.instance.self_link
}

output "internal_ip" {
  description = "内网IP地址"
  value       = google_compute_instance.instance.network_interface[0].network_ip
}

output "external_ip" {
  description = "外网IP地址"
  value       = try(
    google_compute_instance.instance.network_interface[0].access_config[0].nat_ip,
    null
  )
}
```

### 3.4.3 模块使用示例

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
  project = "my-project-id"
  region  = "us-central1"
}

module "vpc" {
  source = "./modules/vpc"

  project_id   = "my-project-id"
  network_name = "production-vpc"
}

module "web_server" {
  source = "./modules/compute"

  project_id = "my-project-id"
  zone       = "us-central1-a"
  name       = "web-server-1"
  machine_type = "e2-medium"
  image      = "debian-cloud/debian-11"
  network    = module.vpc.network_id

  boot_disk_size = 100
  boot_disk_type = "pd-ssd"

  service_account = "terraform@my-project-id.iam.gserviceaccount.com"

  labels = {
    environment = "production"
    role        = "web"
  }
}

module "db_server" {
  source = "./modules/compute"

  project_id = "my-project-id"
  zone       = "us-central1-a"
  name       = "db-server-1"
  machine_type = "e2-highmem-4"
  image      = "debian-cloud/debian-11"
  network    = module.vpc.network_id

  boot_disk_size = 500
  boot_disk_type = "pd-ssd"

  service_account = "terraform@my-project-id.iam.gserviceaccount.com"

  labels = {
    environment = "production"
    role        = "database"
  }
}
```

---

## 3.5 模块组合实战

### 3.5.1 项目结构

```bash
terraform-project/
├── main.tf
├── variables.tf
├── terraform.tfvars
└── modules/
    ├── vpc/
    ├── subnet/
    ├── firewall/
    ├── compute/
    └── load_balancer/
```

### 3.5.2 组合模块

**main.tf：**

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC网络
module "vpc" {
  source = "./modules/vpc"

  project_id   = var.project_id
  network_name = var.network_name
  routing_mode = var.routing_mode
}

# 子网
module "subnet_public" {
  source = "./modules/subnet"

  project_id    = var.project_id
  region       = var.region
  network_name = var.network_name
  subnet_name  = "public-subnet"
  ip_cidr_range = var.public_subnet_cidr
}

module "subnet_private" {
  source = "./modules/subnet"

  project_id    = var.project_id
  region       = var.region
  network_name = var.network_name
  subnet_name  = "private-subnet"
  ip_cidr_range = var.private_subnet_cidr
}

# 防火墙规则
module "firewall_ssh" {
  source = "./modules/firewall"

  project_id   = var.project_id
  network_id  = module.vpc.network_id
  rule_name   = "allow-ssh"
  allow_ports = ["22"]
  source_ranges = var.ssh_source_ranges
}

module "firewall_http" {
  source = "./modules/firewall"

  project_id   = var.project_id
  network_id  = module.vpc.network_id
  rule_name   = "allow-http"
  allow_ports = ["80", "443"]
  source_ranges = ["0.0.0.0/0"]
}

# 计算实例
module "web_server" {
  source = "./modules/compute"

  project_id = var.project_id
  zone       = "${var.region}-a"
  name       = "web-server"
  network    = module.vpc.network_id
  subnetwork = module.subnet_public.subnet_id

  boot_disk_size = 50
  boot_disk_type = "pd-ssd"
}

module "db_server" {
  source = "./modules/compute"

  project_id = var.project_id
  zone       = "${var.region}-a"
  name       = "db-server"
  network    = module.vpc.network_id
  subnetwork = module.subnet_private.subnet_id

  boot_disk_size = 200
  boot_disk_type = "pd-ssd"
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

variable "network_name" {
  description = "VPC网络名称"
  type        = string
  default     = "production-network"
}

variable "routing_mode" {
  description = "路由模式"
  type        = string
  default     = "REGIONAL"
}

variable "public_subnet_cidr" {
  description = "公共子网CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "私有子网CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_source_ranges" {
  description = "SSH访问源IP范围"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
```

**outputs.tf：**

```hcl
output "vpc_id" {
  description = "VPC网络ID"
  value       = module.vpc.network_id
}

output "web_server_ip" {
  description = "Web服务器IP地址"
  value       = module.web_server.external_ip
}

output "db_server_ip" {
  description = "数据库服务器IP地址"
  value       = module.db_server.internal_ip
}
```

### 3.5.3 执行和验证

```bash
# 初始化
terraform init

# 验证配置
terraform validate

# 查看执行计划
terraform plan

# 应用配置
terraform apply -auto-approve

# 查看输出
terraform output vpc_id
terraform output web_server_ip
terraform output db_server_ip

# 验证资源
terraform state list

# 查看依赖关系
terraform graph | dot -Tpng > dependency-graph.png

# 销毁资源
terraform destroy -auto-approve
```

---

## 3.6 模块版本管理

### 3.6.1 使用Git标签

```hcl
module "vpc" {
  source = "github.com/company/terraform-modules//vpc?ref=v1.0.0"

  project_id = "my-project-id"
  network_name = "my-vpc"
}
```

### 3.6.2 使用分支

```hcl
module "vpc" {
  source = "github.com/company/terraform-modules//vpc?ref=feature/new-routing"

  project_id = "my-project-id"
  network_name = "my-vpc"
}
```

### 3.6.3 使用Registry版本

```hcl
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.0"

  project_id   = "my-project-id"
  network_name = "my-vpc"
}
```

---

## 本章小结

- 模块化提高代码复用性和可维护性
- 模块应该遵循单一职责原则
- 模块应该高度可配置
- 模块输出应该最小化
- 模块组合可以构建复杂基础设施
- 使用版本控制管理模块版本

---

**下一章：Terraform工作空间和环境管理**
