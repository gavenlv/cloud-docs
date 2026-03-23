# 利用Terraform的并行执行能力

# 错误示例：顺序创建资源
resource "google_compute_instance" "web_server_1" {
  name         = "web-server-1"
  machine_type = "e2-medium"
}

resource "google_compute_instance" "web_server_2" {
  name         = "web-server-2"
  machine_type = "e2-medium"
}

resource "google_compute_instance" "web_server_3" {
  name         = "web-server-3"
  machine_type = "e2-medium"
}

# 正确示例：使用count并行创建
resource "google_compute_instance" "web_server" {
  count        = 3
  name         = "web-server-${count.index}"
  machine_type = "e2-medium"
}

# 或使用for_each
resource "google_compute_instance" "web_server" {
  for_each = toset(["web", "db", "cache"])

  name         = "${each.key}-server"
  machine_type = "e2-medium"
}