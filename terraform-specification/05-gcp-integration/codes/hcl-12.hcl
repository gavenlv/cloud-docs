resource "google_compute_region_health_check" "health_check" {
  name               = "web-health-check"
  region             = "us-central1"

  http_health_check {
    port         = 80
    request_path = "/"
    proxy_header = "NONE"
  }
}

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

resource "google_compute_region_url_map" "web_url_map" {
  name            = "web-url-map"
  region          = "us-central1"
  default_service = google_compute_region_backend_service.web_backend.id
}

resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "web-proxy"
  region  = "us-central1"
  url_map = google_compute_region_url_map.web_url_map.id
}

resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = ["80-80"]
  ip_protocol = "TCP"
}