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