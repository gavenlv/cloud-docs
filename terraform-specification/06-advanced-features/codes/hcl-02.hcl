# variables.tf
variable "tags" {
  description = "资源标签"
  type = map(string)
  default = {
    environment = "production"
    managed_by   = "terraform"
    project      = "web-app"
    team         = "platform"
    cost_center  = "engineering"
  }
}

# main.tf
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  dynamic "labels" {
    for_each = var.tags
    content {
      key   = labels.key
      value = labels.value
    }
  }
}

# 更简洁的方式
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  labels       = var.tags
}