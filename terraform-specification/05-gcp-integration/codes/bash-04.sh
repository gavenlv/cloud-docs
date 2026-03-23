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