# variables.tf
variable "environment" {
  description = "环境名称"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod"
  }
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "机器类型"
  type        = string
  default     = "e2-medium"
}

# main.tf
locals {
  config = {
    dev = {
      instance_count = 1
      machine_type  = "e2-small"
      disk_size     = 50
      enable_monitoring = false
      enable_backup = false
    }
    staging = {
      instance_count = 2
      machine_type  = "e2-medium"
      disk_size     = 100
      enable_monitoring = true
      enable_backup = false
    }
    prod = {
      instance_count = 3
      machine_type  = "e2-highcpu-4"
      disk_size     = 200
      enable_monitoring = true
      enable_backup = true
    }
  }

  current_config = lookup(local.config, var.environment, local.config.dev)
}

resource "google_compute_instance" "web_server" {
  count        = local.current_config.instance_count
  name         = "${var.environment}-web-server-${count.index}"
  machine_type = local.current_config.machine_type
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

  labels = {
    environment = var.environment
    managed_by   = "terraform"
  }
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  count = local.current_config.enable_monitoring ? 1 : 0

  display_name = "${var.environment}-cpu-alert"
  condition {
    display_name = "CPU Usage Alert"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "backup_policy" {
  count = local.current_config.enable_backup ? local.current_config.instance_count : 0

  name = "daily-backup-policy"
  disk = google_compute_instance.web_server[count.index].boot_disk[0].source
}

output "instance_names" {
  value = google_compute_instance.web_server[*].name
}