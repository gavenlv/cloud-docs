# 限制防火墙规则范围

# 错误示例：过于宽泛
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # 错误：允许所有IP访问
}

# 正确示例：限制访问范围
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.0.0/8"]  # 正确：只允许内网访问
  target_tags   = ["ssh-server"]
}

# 使用目标标签限制资源
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  tags = ["ssh-server", "http-server"]

  network_interface {
    network = "default"
  }
}