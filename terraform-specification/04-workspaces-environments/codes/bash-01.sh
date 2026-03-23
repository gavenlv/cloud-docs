# 工作空间隔离的命名规范

# dev环境
resource "google_compute_instance" "web_server" {
  name = "${terraform.workspace}-web-server"
  # dev-web-server
}

# staging环境
resource "google_compute_instance" "web_server" {
  name = "${terraform.workspace}-web-server"
  # staging-web-server
}

# prod环境
resource "google_compute_instance" "web_server" {
  name = "${terraform.workspace}-web-server"
  # prod-web-server
}