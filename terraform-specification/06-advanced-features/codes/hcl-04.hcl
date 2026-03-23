# variables.tf
variable "features" {
  description = "功能开关"
  type = object({
    enable_load_balancer = bool
    enable_monitoring    = bool
    enable_backup        = bool
    enable_logging       = bool
  })
  default = {
    enable_load_balancer = false
    enable_monitoring    = false
    enable_backup        = false
    enable_logging       = false
  }
}

# main.tf
resource "google_compute_region_backend_service" "web_backend" {
  count = var.features.enable_load_balancer ? 1 : 0

  name                  = "web-backend"
  region                = "us-central1"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  count = var.features.enable_monitoring ? 1 : 0

  display_name = "cpu-alert"
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
  count = var.features.enable_backup ? length(google_compute_instance.web_server) : 0

  name = "daily-backup-policy"
  disk = google_compute_instance.web_server[count.index].boot_disk[0].source
}

resource "google_logging_project_sink" "logging_sink" {
  count = var.features.enable_logging ? 1 : 0

  name        = "terraform-logging-sink"
  destination = "logging.googleapis.com/projects/my-project-id/sinks/terraform-sink"
  filter      = "resource.type=\"gce_instance\""
}