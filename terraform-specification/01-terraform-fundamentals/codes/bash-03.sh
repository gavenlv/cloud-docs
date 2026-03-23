# 1. 初始化工作目录
terraform init

# 输出：
# Initializing the backend...
# Initializing provider plugins...
# - Finding hashicorp/google versions matching "~> 4.0"...
# - Installing hashicorp/google v4.78.0...
# - Installed hashicorp/google v4.78.0 (signed by HashiCorp)

# 2. 格式化代码
terraform fmt

# 3. 验证配置
terraform validate

# 输出：
# Success! The configuration is valid.

# 4. 查看执行计划
terraform plan

# 输出：
# Terraform will perform the following actions:
#
#   # google_compute_network.vpc_network will be created
#   + resource "google_compute_network" "vpc_network" {
#       + name                    = "terraform-network"
#       + auto_create_subnetworks = false
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.

# 5. 应用配置
terraform apply

# 输入yes确认后：
# google_compute_network.vpc_network: Creating...
# google_compute_network.vpc_network: Creation complete after 2s

# 6. 查看状态
terraform show

# 7. 查看输出
terraform output network_name
# terraform-network

terraform output network_id
# projects/your-project-id/global/networks/terraform-network

# 8. 销毁资源
terraform destroy