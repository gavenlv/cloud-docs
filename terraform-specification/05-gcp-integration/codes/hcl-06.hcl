resource "google_compute_instance_group_manager" "web_group" {
  name        = "web-server-group"
  base_instance_name = "web-server"
  zone        = "us-central1-a"
  target_size = 3

  version {
    name = "v1"
    instance_template = google_compute_instance_template.web_template.id
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    most_disruptive_action = "RESTART"
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check {
      http_health_check {
        port         = 80
        request_path = "/"
      }
    }
  }
}