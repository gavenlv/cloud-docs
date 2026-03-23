# 避免不必要的依赖

# 错误示例：使用depends_on创建不必要的依赖
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.subnet,
    google_compute_firewall.firewall
  ]
}

# 正确示例：使用隐式依赖
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  tags = ["http-server"]
}

resource "google_compute_firewall" "firewall" {
  name    = "allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http-server"]
}