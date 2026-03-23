# 监控资源使用情况

resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"

  conditions {
    display_name = "CPU Usage > 80%"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id
  ]
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification"
  type         = "email"
  labels = {
    email_address = "admin@example.com"
  }
}