#!/bin/bash
# Terraform代码验证脚本

echo "=========================================="
echo "Terraform代码验证"
echo "=========================================="

# 检查Terraform是否安装
if ! command -v terraform &> /dev/null; then
    echo "错误：Terraform未安装"
    echo "请访问 https://www.terraform.io/downloads 下载安装"
    exit 1
fi

echo "Terraform版本："
terraform version
echo ""

# 创建测试目录
TEST_DIR="terraform-test"
mkdir -p $TEST_DIR
cd $TEST_DIR

# 测试1：基础配置
echo "=========================================="
echo "测试1：基础配置"
echo "=========================================="

cat > test1.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "test-project-id"
  region  = "us-central1"
}

resource "google_compute_network" "vpc" {
  name = "test-network"
}
EOF

echo "初始化..."
terraform init > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform init 成功"
else
    echo "✗ terraform init 失败"
fi

echo "验证配置..."
terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform validate 成功"
else
    echo "✗ terraform validate 失败"
fi

# 测试2：变量和输出
echo ""
echo "=========================================="
echo "测试2：变量和输出"
echo "=========================================="

cat > test2.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "test-project-id"
  region  = "us-central1"
}

variable "network_name" {
  description = "VPC网络名称"
  type        = string
  default     = "test-network"
}

resource "google_compute_network" "vpc" {
  name = var.network_name
}

output "network_id" {
  description = "VPC网络ID"
  value       = google_compute_network.vpc.id
}
EOF

echo "验证配置..."
terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform validate 成功"
else
    echo "✗ terraform validate 失败"
fi

# 测试3：循环
echo ""
echo "=========================================="
echo "测试3：循环"
echo "=========================================="

cat > test3.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "test-project-id"
  region  = "us-central1"
}

variable "zones" {
  description = "可用区列表"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

resource "google_compute_network" "vpc" {
  count = length(var.zones)
  name  = "test-network-${count.index}"
}
EOF

echo "验证配置..."
terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform validate 成功"
else
    echo "✗ terraform validate 失败"
fi

# 测试4：动态块
echo ""
echo "=========================================="
echo "测试4：动态块"
echo "=========================================="

cat > test4.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "test-project-id"
  region  = "us-central1"
}

variable "networks" {
  description = "网络接口列表"
  type = list(object({
    name    = string
    network = string
  }))
  default = [
    { name = "default", network = "default" },
    { name = "private", network = "private-network" }
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
EOF

echo "验证配置..."
terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform validate 成功"
else
    echo "✗ terraform validate 失败"
fi

# 测试5：条件逻辑
echo ""
echo "=========================================="
echo "测试5：条件逻辑"
echo "=========================================="

cat > test5.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "test-project-id"
  region  = "us-central1"
}

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
  }

  network_interface {
    network = "default"
  }
}
EOF

echo "验证配置..."
terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform validate 成功"
else
    echo "✗ terraform validate 失败"
fi

# 测试6：数据源
echo ""
echo "=========================================="
echo "测试6：数据源"
echo "=========================================="

cat > test6.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "test-project-id"
  region  = "us-central1"
}

data "google_compute_image" "debian_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

data "google_compute_zones" "available_zones" {
  region = "us-central1"
}

output "latest_image" {
  value = data.google_compute_image.debian_image.self_link
}

output "available_zones" {
  value = data.google_compute_zones.available_zones.names
}
EOF

echo "验证配置..."
terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform validate 成功"
else
    echo "✗ terraform validate 失败"
fi

# 测试7：模块
echo ""
echo "=========================================="
echo "测试7：模块"
echo "=========================================="

mkdir -p modules/vpc

cat > modules/vpc/main.tf << 'EOF'
variable "network_name" {
  description = "VPC网络名称"
  type        = string
}

resource "google_compute_network" "vpc" {
  name = var.network_name
}

output "network_id" {
  value = google_compute_network.vpc.id
}
EOF

cat > test7.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "test-project-id"
  region  = "us-central1"
}

module "vpc" {
  source       = "./modules/vpc"
  network_name = "test-network"
}
EOF

echo "验证配置..."
terraform validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ terraform validate 成功"
else
    echo "✗ terraform validate 失败"
fi

# 清理测试目录
cd ..
rm -rf $TEST_DIR

echo ""
echo "=========================================="
echo "验证完成"
echo "=========================================="
echo ""
echo "注意：以上测试只验证了Terraform配置的语法正确性"
echo "实际运行需要有效的GCP凭证和项目ID"
echo ""
echo "要运行完整的测试，请："
echo "1. 安装Google Cloud SDK"
echo "2. 配置GCP凭证：gcloud auth application-default login"
echo "3. 设置项目ID：export TF_VAR_project_id=your-project-id"
echo "4. 运行：terraform init && terraform plan"
