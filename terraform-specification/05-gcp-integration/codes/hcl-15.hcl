# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"
  }
}

provider "google" {
  project = "my-project-id"
  region  = "us-central1"
}

# VPC网络
resource "google_compute_network" "vpc" {
  name                    = "production-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# 子网
resource "google_compute_subnetwork" "subnet_public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet_private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# 防火墙规则
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# 实例模板
resource "google_compute_instance_template" "web_template" {
  name        = "web-server-template"
  machine_type = "e2-medium"
  region      = "us-central1"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot        = true
    disk_size_gb = 50
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_public.id
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl start nginx
    EOT
  }
}

# 实例组
resource "google_compute_instance_group_manager" "web_group" {
  name        = "web-server-group"
  base_instance_name = "web-server"
  zone        = "us-central1-a"
  target_size = 3

  version {
    name = "v1"
    instance_template = google_compute_instance_template.web_template.id
  }

  named_port {
    name = "http"
    port = 80
  }
}

# 健康检查
resource "google_compute_region_health_check" "health_check" {
  name               = "web-health-check"
  region             = "us-central1"

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# 后端服务
resource "google_compute_region_backend_service" "web_backend" {
  name                  = "web-backend"
  region                = "us-central1"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_region_health_check.health_check.id]

  backend {
    group = google_compute_instance_group_manager.web_group.id
  }
}

# URL映射
resource "google_compute_region_url_map" "web_url_map" {
  name            = "web-url-map"
  region          = "us-central1"
  default_service = google_compute_region_backend_service.web_backend.id
}

# HTTP代理
resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "web-proxy"
  region  = "us-central1"
  url_map = google_compute_region_url_map.web_url_map.id
}

# 转发规则
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = ["80-80"]
  ip_protocol = "TCP"
}

# Cloud SQL
resource "google_sql_database_instance" "db" {
  name             = "production-db"
  database_version = "POSTGRES_14"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      private_network {
        network_id = google_compute_network.vpc.id
      }
    }

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = true
}

# 数据库
resource "google_sql_database" "app_db" {
  name     = "app"
  instance = google_sql_database_instance.db.name
}

# 输出
output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.web_forwarding_rule.ip_address
}

output "db_connection_name" {
  value = google_sql_database_instance.db.connection_name
}