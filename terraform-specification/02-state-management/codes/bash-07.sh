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