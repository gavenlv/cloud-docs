# main.tf
variable "environment" {
  description = "环境名称"
  type        = string
  default     = "dev"
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "实例类型"
  type        = string
  default     = "e2-small"
}

# 根据环境设置不同的配置
locals {
  config = {
    dev = {
      instance_count = 1
      instance_type  = "e2-small"
      disk_size     = 50
    }
    staging = {
      instance_count = 2
      instance_type  = "e2-medium"
      disk_size     = 100
    }
    prod = {
      instance_count = 3
      instance_type  = "e2-highcpu-4"
      disk_size     = 200
    }
  }

  current_config = lookup(local.config, var.environment, local.config.dev)
}

resource "google_compute_instance" "web_server" {
  count        = local.current_config.instance_count
  name         = "${var.environment}-web-server-${count.index}"
  machine_type = local.current_config.instance_type
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
}

output "instance_names" {
  value = google_compute_instance.web_server[*].name
}