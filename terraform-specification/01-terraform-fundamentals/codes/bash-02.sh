mkdir -p terraform-gcp-tutorial/01-basics
cd terraform-gcp-tutorial/01-basics

# 创建main.tf文件
cat > main.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0"
}

provider "google" {
  project = "your-project-id"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = false
}

output "network_name" {
  value = google_compute_network.vpc_network.name
}

output "network_id" {
  value = google_compute_network.vpc_network.id
}
EOF