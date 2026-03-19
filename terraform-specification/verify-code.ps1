# Terraform代码验证脚本 (PowerShell)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Terraform代码验证" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查Terraform是否安装
$terraformExists = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $terraformExists) {
    Write-Host "错误：Terraform未安装" -ForegroundColor Red
    Write-Host "请访问 https://www.terraform.io/downloads 下载安装"
    exit 1
}

Write-Host "Terraform版本：" -ForegroundColor Yellow
terraform version
Write-Host ""

# 创建测试目录
$TEST_DIR = "terraform-test"
New-Item -ItemType Directory -Force -Path $TEST_DIR | Out-Null
Set-Location $TEST_DIR

# 测试1：基础配置
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "测试1：基础配置" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

@"
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
"@ | Out-File -FilePath "test1.tf" -Encoding UTF8

Write-Host "初始化..."
$initResult = terraform init 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform init 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform init 失败" -ForegroundColor Red
}

Write-Host "验证配置..."
$validateResult = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform validate 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform validate 失败" -ForegroundColor Red
}

# 测试2：变量和输出
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "测试2：变量和输出" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

@"
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
"@ | Out-File -FilePath "test2.tf" -Encoding UTF8

Write-Host "验证配置..."
$validateResult = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform validate 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform validate 失败" -ForegroundColor Red
}

# 测试3：循环
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "测试3：循环" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

@"
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
  name  = "test-network-`${count.index}"
}
"@ | Out-File -FilePath "test3.tf" -Encoding UTF8

Write-Host "验证配置..."
$validateResult = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform validate 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform validate 失败" -ForegroundColor Red
}

# 测试4：动态块
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "测试4：动态块" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

@"
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
"@ | Out-File -FilePath "test4.tf" -Encoding UTF8

Write-Host "验证配置..."
$validateResult = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform validate 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform validate 失败" -ForegroundColor Red
}

# 测试5：条件逻辑
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "测试5：条件逻辑" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

@"
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
  name         = "`${var.environment}-web-server"
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
"@ | Out-File -FilePath "test5.tf" -Encoding UTF8

Write-Host "验证配置..."
$validateResult = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform validate 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform validate 失败" -ForegroundColor Red
}

# 测试6：数据源
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "测试6：数据源" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

@"
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
"@ | Out-File -FilePath "test6.tf" -Encoding UTF8

Write-Host "验证配置..."
$validateResult = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform validate 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform validate 失败" -ForegroundColor Red
}

# 测试7：模块
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "测试7：模块" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "modules\vpc" | Out-Null

@"
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
"@ | Out-File -FilePath "modules\vpc\main.tf" -Encoding UTF8

@"
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
"@ | Out-File -FilePath "test7.tf" -Encoding UTF8

Write-Host "验证配置..."
$validateResult = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ terraform validate 成功" -ForegroundColor Green
} else {
    Write-Host "✗ terraform validate 失败" -ForegroundColor Red
}

# 清理测试目录
Set-Location ..
Remove-Item -Recurse -Force $TEST_DIR

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "验证完成" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "注意：以上测试只验证了Terraform配置的语法正确性" -ForegroundColor Yellow
Write-Host "实际运行需要有效的GCP凭证和项目ID" -ForegroundColor Yellow
Write-Host ""
Write-Host "要运行完整的测试，请：" -ForegroundColor Yellow
Write-Host "1. 安装Google Cloud SDK" -ForegroundColor White
Write-Host "2. 配置GCP凭证：gcloud auth application-default login" -ForegroundColor White
Write-Host "3. 设置项目ID：`$env:TF_VAR_project_id='your-project-id'" -ForegroundColor White
Write-Host "4. 运行：terraform init && terraform plan" -ForegroundColor White
