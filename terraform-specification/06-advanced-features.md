# Terraform高级特性

## 6.1 动态配置

### 6.1.1 动态块 (Dynamic Blocks)

```
动态块原理：

┌─────────────────────────────────────────────────────────────────┐
│  问题：重复配置                                         │
└─────────────────────────────────────────────────────────────────┘

传统方式（重复代码）：
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  network_interface {
    network = "default"
  }

  network_interface {
    network = "private-network"
  }

  network_interface {
    network = "dmz-network"
  }

  network_interface {
    network = "backup-network"
  }

  # 如果需要添加更多网络接口，需要重复写很多代码
}

问题：
├── 代码重复
├── 难以维护
├── 容易出错
└── 不灵活

┌─────────────────────────────────────────────────────────────────┐
│  解决方案：动态块 (Dynamic Blocks)                      │
└─────────────────────────────────────────────────────────────────┘

使用动态块：
variable "networks" {
  description = "网络接口列表"
  type = list(object({
    name    = string
    network = string
  }))
  default = [
    { name = "default", network = "default" },
    { name = "private", network = "private-network" },
    { name = "dmz", network = "dmz-network" },
    { name = "backup", network = "backup-network" }
  ]
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  dynamic "network_interface" {
    for_each = var.networks
    content {
      network = network_interface.value.network
    }
  }
}

优势：
├── 代码简洁
├── 易于维护
├── 灵活配置
└── 支持变量驱动
```

### 6.1.2 动态块实战

**场景：配置多个防火墙规则**

```hcl
# variables.tf
variable "firewall_rules" {
  description = "防火墙规则列表"
  type = list(object({
    name          = string
    description   = string
    source_ranges = list(string)
    ports         = list(string)
    protocol      = string
  }))
  default = [
    {
      name          = "allow-ssh"
      description   = "Allow SSH access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["22"]
      protocol      = "tcp"
    },
    {
      name          = "allow-http"
      description   = "Allow HTTP access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["80", "443"]
      protocol      = "tcp"
    },
    {
      name          = "allow-internal"
      description   = "Allow internal traffic"
      source_ranges = ["10.0.0.0/8"]
      ports         = ["0-65535"]
      protocol      = "tcp"
    }
  ]
}

# main.tf
resource "google_compute_firewall" "firewall_rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name    = each.value.name
  network = "default"

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }

  source_ranges = each.value.source_ranges

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

output "firewall_rules" {
  value = {
    for name, rule in google_compute_firewall.firewall_rules : name => rule.name
  }
}
```

**场景：配置多个标签**

```hcl
# variables.tf
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

# main.tf
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  dynamic "labels" {
    for_each = var.tags
    content {
      key   = labels.key
      value = labels.value
    }
  }
}

# 更简洁的方式
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  labels       = var.tags
}
```

---

## 6.2 条件逻辑

### 6.2.1 条件表达式

```
条件表达式类型：

┌─────────────────────────────────────────────────────────────────┐
│  1. 三元运算符 (Ternary Operator)                         │
└─────────────────────────────────────────────────────────────────┘

语法：
condition ? true_value : false_value

示例：
variable "environment" {
  description = "环境名称"
  type        = string
  default     = "dev"
}

resource "google_compute_instance" "web_server" {
  name         = "${var.environment}-web-server"
  machine_type = var.environment == "prod" ? "e2-highcpu-4" : "e2-medium"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    size = var.environment == "prod" ? 200 : 50
  }
}

解释：
├── 如果environment是"prod"，使用e2-highcpu-4
├── 否则使用e2-medium
└── 磁盘大小同理

┌─────────────────────────────────────────────────────────────────┐
│  2. 条件资源 (Conditional Resources)                       │
└─────────────────────────────────────────────────────────────────┘

语法：
count = condition ? 1 : 0

示例：
variable "create_load_balancer" {
  description = "是否创建负载均衡器"
  type        = bool
  default     = false
}

resource "google_compute_region_backend_service" "web_backend" {
  count = var.create_load_balancer ? 1 : 0

  name                  = "web-backend"
  region                = "us-central1"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
}

解释：
├── 如果create_load_balancer为true，创建1个资源
├── 如果create_load_balancer为false，创建0个资源
└── 资源数量为0时，Terraform不会创建资源

┌─────────────────────────────────────────────────────────────────┐
│  3. 条件属性 (Conditional Attributes)                       │
└─────────────────────────────────────────────────────────────────┘

语法：
dynamic "attribute" {
  for_each = condition ? [1] : []
  content {
    # attribute配置
  }
}

示例：
variable "enable_public_ip" {
  description = "是否启用公网IP"
  type        = bool
  default     = false
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  network_interface {
    network = "default"

    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }
}

解释：
├── 如果enable_public_ip为true，创建access_config块
├── 如果enable_public_ip为false，不创建access_config块
└── access_config块用于配置公网IP
```

### 6.2.2 条件逻辑实战

**场景：根据环境配置不同资源**

```hcl
# variables.tf
variable "environment" {
  description = "环境名称"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod"
  }
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "机器类型"
  type        = string
  default     = "e2-medium"
}

# main.tf
locals {
  config = {
    dev = {
      instance_count = 1
      machine_type  = "e2-small"
      disk_size     = 50
      enable_monitoring = false
      enable_backup = false
    }
    staging = {
      instance_count = 2
      machine_type  = "e2-medium"
      disk_size     = 100
      enable_monitoring = true
      enable_backup = false
    }
    prod = {
      instance_count = 3
      machine_type  = "e2-highcpu-4"
      disk_size     = 200
      enable_monitoring = true
      enable_backup = true
    }
  }

  current_config = lookup(local.config, var.environment, local.config.dev)
}

resource "google_compute_instance" "web_server" {
  count        = local.current_config.instance_count
  name         = "${var.environment}-web-server-${count.index}"
  machine_type = local.current_config.machine_type
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

  labels = {
    environment = var.environment
    managed_by   = "terraform"
  }
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  count = local.current_config.enable_monitoring ? 1 : 0

  display_name = "${var.environment}-cpu-alert"
  condition {
    display_name = "CPU Usage Alert"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "backup_policy" {
  count = local.current_config.enable_backup ? local.current_config.instance_count : 0

  name = "daily-backup-policy"
  disk = google_compute_instance.web_server[count.index].boot_disk[0].source
}

output "instance_names" {
  value = google_compute_instance.web_server[*].name
}
```

**场景：条件创建资源**

```hcl
# variables.tf
variable "features" {
  description = "功能开关"
  type = object({
    enable_load_balancer = bool
    enable_monitoring    = bool
    enable_backup        = bool
    enable_logging       = bool
  })
  default = {
    enable_load_balancer = false
    enable_monitoring    = false
    enable_backup        = false
    enable_logging       = false
  }
}

# main.tf
resource "google_compute_region_backend_service" "web_backend" {
  count = var.features.enable_load_balancer ? 1 : 0

  name                  = "web-backend"
  region                = "us-central1"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  count = var.features.enable_monitoring ? 1 : 0

  display_name = "cpu-alert"
  condition {
    display_name = "CPU Usage Alert"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "backup_policy" {
  count = var.features.enable_backup ? length(google_compute_instance.web_server) : 0

  name = "daily-backup-policy"
  disk = google_compute_instance.web_server[count.index].boot_disk[0].source
}

resource "google_logging_project_sink" "logging_sink" {
  count = var.features.enable_logging ? 1 : 0

  name        = "terraform-logging-sink"
  destination = "logging.googleapis.com/projects/my-project-id/sinks/terraform-sink"
  filter      = "resource.type=\"gce_instance\""
}
```

---

## 6.3 循环和迭代

### 6.3.1 循环类型

```
Terraform循环类型：

┌─────────────────────────────────────────────────────────────────┐
│  1. count (数字循环)                                    │
└─────────────────────────────────────────────────────────────────┘

语法：
resource "resource_type" "name" {
  count = 3
  # 资源配置
}

示例：
resource "google_compute_instance" "web_server" {
  count = 3

  name         = "web-server-${count.index}"
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

输出：
├── web-server-0
├── web-server-1
└── web-server-2

优势：
├── 简单直接
├── 适合创建多个相同资源
└── 支持索引访问

劣势：
├── 资源名称固定
├── 删除中间资源会导致问题
└── 不适合动态列表

┌─────────────────────────────────────────────────────────────────┐
│  2. for_each (映射循环)                                 │
└─────────────────────────────────────────────────────────────────┘

语法：
resource "resource_type" "name" {
  for_each = {
    key1 = value1
    key2 = value2
    key3 = value3
  }
  # 资源配置
}

示例：
variable "servers" {
  description = "服务器列表"
  type = map(object({
    machine_type = string
    zone        = string
  }))
  default = {
    web = {
      machine_type = "e2-medium"
      zone        = "us-central1-a"
    }
    db = {
      machine_type = "e2-highmem-4"
      zone        = "us-central1-b"
    }
    cache = {
      machine_type = "e2-highcpu-2"
      zone        = "us-central1-c"
    }
  }
}

resource "google_compute_instance" "servers" {
  for_each = var.servers

  name         = "${each.key}-server"
  machine_type = each.value.machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}

输出：
├── web-server
├── db-server
└── cache-server

优势：
├── 资源名称灵活
├── 删除中间资源不影响其他资源
├── 适合动态列表
└── 支持键值对访问

劣势：
├── 需要映射类型
├── 稍微复杂一些
└── 需要唯一键

┌─────────────────────────────────────────────────────────────────┐
│  3. for (表达式循环)                                       │
└─────────────────────────────────────────────────────────────────┘

语法：
[for item in list : expression]

示例：
variable "zones" {
  description = "可用区列表"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

locals {
  # 创建实例名称列表
  instance_names = [for zone in var.zones : "web-server-${zone}"]

  # 过滤列表
  available_zones = [for zone in var.zones : zone if can(regex("us-central1", zone))]

  # 创建映射
  zone_mapping = { for zone in var.zones : zone => "${zone}-subnet" }
}

output "instance_names" {
  value = local.instance_names
}

输出：
["web-server-us-central1-a", "web-server-us-central1-b", "web-server-us-central1-c"]

优势：
├── 灵活强大
├── 支持过滤和转换
├── 可以创建复杂的数据结构
└── 适合数据处理

劣势：
├── 只能在表达式中使用
├── 不能用于资源创建
└── 语法相对复杂
```

### 6.3.2 循环实战

**场景：创建多个子网**

```hcl
# variables.tf
variable "subnets" {
  description = "子网配置"
  type = map(object({
    ip_cidr_range = string
    region       = string
    description  = string
  }))
  default = {
    public = {
      ip_cidr_range = "10.0.1.0/24"
      region       = "us-central1"
      description  = "Public subnet"
    }
    private = {
      ip_cidr_range = "10.0.2.0/24"
      region       = "us-central1"
      description  = "Private subnet"
    }
    dmz = {
      ip_cidr_range = "10.0.3.0/24"
      region       = "us-central1"
      description  = "DMZ subnet"
    }
  }
}

# main.tf
resource "google_compute_network" "vpc" {
  name                    = "production-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = "${each.key}-subnet"
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  description   = each.value.description

  labels = {
    type = each.key
  }
}

output "subnet_ids" {
  value = {
    for name, subnet in google_compute_subnetwork.subnets : name => subnet.id
  }
}

output "subnet_cidrs" {
  value = {
    for name, subnet in google_compute_subnetwork.subnets : name => subnet.ip_cidr_range
  }
}
```

**场景：创建多个防火墙规则**

```hcl
# variables.tf
variable "firewall_rules" {
  description = "防火墙规则配置"
  type = list(object({
    name          = string
    description   = string
    source_ranges = list(string)
    ports         = list(string)
    protocol      = string
    target_tags   = list(string)
  }))
  default = [
    {
      name          = "allow-ssh"
      description   = "Allow SSH access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["22"]
      protocol      = "tcp"
      target_tags   = ["ssh-server"]
    },
    {
      name          = "allow-http"
      description   = "Allow HTTP access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["80", "443"]
      protocol      = "tcp"
      target_tags   = ["http-server"]
    },
    {
      name          = "allow-https"
      description   = "Allow HTTPS access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["443"]
      protocol      = "tcp"
      target_tags   = ["https-server"]
    }
  ]
}

# main.tf
resource "google_compute_firewall" "firewall_rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name    = each.value.name
  network = "default"

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }

  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

output "firewall_rule_names" {
  value = [
    for rule in google_compute_firewall.firewall_rules : rule.name
  ]
}
```

---

## 6.4 数据源和输出

### 6.4.1 数据源 (Data Sources)

```
数据源原理：

┌─────────────────────────────────────────────────────────────────┐
│  数据源作用                                             │
└─────────────────────────────────────────────────────────────────┘

数据源用于：
├── 查询现有资源
├── 获取动态信息
├── 引用外部资源
├── 构建依赖关系
└── 避免重复配置

┌─────────────────────────────────────────────────────────────────┐
│  常用数据源类型                                          │
└─────────────────────────────────────────────────────────────────┘

1. 基础设施数据源：
   - google_compute_network
   - google_compute_subnetwork
   - google_compute_instance
   - google_compute_image
   - google_compute_zones

2. 存储数据源：
   - google_storage_bucket
   - google_storage_bucket_object

3. 数据库数据源：
   - google_sql_database_instance
   - google_bigquery_dataset

4. 网络数据源：
   - google_dns_managed_zone
   - google_compute_router

5. IAM数据源：
   - google_project
   - google_iam_policy
```

### 6.4.2 数据源实战

**场景：查询现有资源**

```hcl
# 查询现有VPC网络
data "google_compute_network" "existing_vpc" {
  name = "existing-network"
}

# 查询现有子网
data "google_compute_subnetwork" "existing_subnet" {
  name   = "existing-subnet"
  region = "us-central1"
}

# 查询最新镜像
data "google_compute_image" "debian_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

# 查询可用区
data "google_compute_zones" "available_zones" {
  region = "us-central1"
}

# 使用数据源创建资源
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

output "latest_image" {
  value = data.google_compute_image.debian_image.self_link
}
```

**场景：查询项目信息**

```hcl
# 查询项目信息
data "google_project" "project" {
  project_id = "my-project-id"
}

# 查询项目IAM策略
data "google_iam_policy" "project_policy" {
  binding {
    role = "roles/editor"
    members = [
      "user:admin@example.com",
      "serviceAccount:terraform@my-project-id.iam.gserviceaccount.com"
    ]
  }
}

# 使用项目信息
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  project      = data.google_project.project.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  labels = {
    project_number = data.google_project.project.number
  }
}

output "project_number" {
  value = data.google_project.project.number
}

output "project_id" {
  value = data.google_project.project.project_id
}
```

### 6.4.3 输出 (Outputs)

```hcl
# 简单输出
output "vpc_id" {
  description = "VPC网络ID"
  value       = google_compute_network.vpc.id
}

# 复杂输出
output "instance_info" {
  description = "实例详细信息"
  value = {
    for instance in google_compute_instance.web_server : instance.name => {
      id         = instance.id
      name       = instance.name
      machine_type = instance.machine_type
      zone       = instance.zone
      internal_ip = instance.network_interface[0].network_ip
      external_ip = try(instance.network_interface[0].access_config[0].nat_ip, null)
    }
  }
}

# 敏感输出
output "db_password" {
  description = "数据库密码"
  value       = random_password.db_password.result
  sensitive   = true
}

# 条件输出
output "load_balancer_ip" {
  description = "负载均衡器IP地址"
  value       = try(google_compute_global_forwarding_rule.web_forwarding_rule[0].ip_address, null)
}

# 输出依赖
output "instance_names" {
  description = "实例名称列表"
  value = [
    for instance in google_compute_instance.web_server : instance.name
  ]
  depends_on = [
    google_compute_instance.web_server
  ]
}
```

---

## 6.5 Terraform Cloud/Enterprise

### 6.5.1 Terraform Cloud

```
Terraform Cloud特性：

┌─────────────────────────────────────────────────────────────────┐
│  核心功能                                          │
└─────────────────────────────────────────────────────────────────┘

1. 远程状态管理：
   ├── 安全的状态存储
   ├── 自动状态锁定
   ├── 状态版本历史
   └── 状态备份和恢复

2. CI/CD集成：
   ├── 自动运行计划和应用
   ├── GitHub/GitLab集成
   ├── Pull Request审批
   └── 策略即代码（Sentinel）

3. 团队协作：
   ├── 团队和权限管理
   ├── 工作空间隔离
   ├── 变量管理
   └── 敏感数据加密

4. 监控和日志：
   ├── 运行历史
   ├── 实时日志
   ├── 通知和告警
   └── 成本追踪

5. 私有模块注册表：
   ├── 模块版本管理
   ├── 模块共享
   ├── 模块测试
   └── 模块文档
```

### 6.5.2 Terraform Cloud配置

```hcl
# main.tf
terraform {
  cloud {
    organization = "my-organization"
    workspaces {
      name = "production"
    }
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

resource "google_compute_network" "vpc" {
  name = "production-vpc"
}
```

### 6.5.3 Terraform Cloud工作流

```bash
# 1. 登录Terraform Cloud
terraform login

# 2. 初始化
terraform init

# 3. 推送到GitHub
git add .
git commit -m "Add Terraform Cloud configuration"
git push origin main

# 4. Terraform Cloud自动运行计划
# 查看Terraform Cloud控制台

# 5. 批准计划
# 在Terraform Cloud控制台中点击"Apply"

# 6. 查看运行结果
# 在Terraform Cloud控制台中查看运行日志
```

---

## 6.6 Terraform测试

### 6.6.1 单元测试

```hcl
# 使用terraform-compliance进行测试

# 测试文件：test/policy.feature
Feature: VPC Network Policy

  Scenario: VPC should have auto_create_subnetworks disabled
    Given I have vpc resource defined
    Then it must contain auto_create_subnetworks
    And its value must be false

  Scenario: VPC should have routing_mode set to REGIONAL
    Given I have vpc resource defined
    Then it must contain routing_mode
    And its value must be REGIONAL

  Scenario: VPC should have labels
    Given I have vpc resource defined
    Then it must contain labels
    And labels must contain environment
    And labels must contain managed_by
```

### 6.6.2 集成测试

```bash
# 使用terratest进行集成测试

# test/vpc_test.go
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestVPC(t *testing.T) {
  t.Parallel()

  terraformOptions := &terraform.Options{
    TerraformDir: "../examples/vpc",

    Vars: map[string]interface{}{
      "project_id": "test-project-id",
      "network_name": "test-network",
    },
  }

  defer terraform.Destroy(t, terraformOptions)

  terraform.InitAndApply(t, terraformOptions)

  networkID := terraform.Output(t, terraformOptions, "network_id")
  assert.NotEmpty(t, networkID)

  networkName := terraform.Output(t, terraformOptions, "network_name")
  assert.Equal(t, "test-network", networkName)
}
```

---

## 6.7 Terraform安全

### 6.7.1 敏感数据管理

```hcl
# 使用变量存储敏感数据
variable "db_password" {
  description = "数据库密码"
  type        = string
  sensitive   = true
}

# 使用Terraform Cloud变量
# 在Terraform Cloud控制台中设置敏感变量

# 使用环境变量
export TF_VAR_db_password="my-secret-password"

# 使用KMS加密
data "google_kms_secret" "db_password" {
  ciphertext = "CiQA..."
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.db.name
  password = data.google_kms_secret.db_password.plaintext
}
```

### 6.7.2 策略即代码

```hcl
# 使用Sentinel进行策略检查

# policy/sentinel.hcl
import "tfplan"

main = rule {
  all tfplan.resource_changes as _, changes {
    validate_instance_type(changes)
  }
}

validate_instance_type = func(changes) {
  changes.change.after.type is "google_compute_instance" and
  changes.change.after.machine_type in ["e2-medium", "e2-highcpu-4"]
}
```

---

## 本章小结

- 动态块减少代码重复
- 条件逻辑实现灵活配置
- 循环和迭代简化批量操作
- 数据源查询现有资源
- 输出暴露资源信息
- Terraform Cloud提供托管服务
- 测试确保代码质量
- 安全管理保护敏感数据

---

**下一章：Terraform最佳实践**
