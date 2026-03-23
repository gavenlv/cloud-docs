# 1. 初始化项目
mkdir terraform-workspace-demo
cd terraform-workspace-demo

# 2. 创建配置文件
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

resource "google_compute_network" "vpc" {
  name = "${terraform.workspace}-network"
  auto_create_subnetworks = false
}

output "network_name" {
  value = google_compute_network.vpc.name
}
EOF

# 3. 初始化
terraform init

# 4. 查看当前工作空间
terraform workspace show
# default

# 5. 创建新工作空间
terraform workspace new dev
# Created and switched to workspace "dev"!

terraform workspace new staging
# Created and switched to workspace "staging"!

terraform workspace new prod
# Created and switched to workspace "prod"!

# 6. 列出所有工作空间
terraform workspace list
#   default
# * dev
#   staging
#   prod

# 7. 切换工作空间
terraform workspace select dev
# Switched to workspace "dev"

terraform workspace show
# dev