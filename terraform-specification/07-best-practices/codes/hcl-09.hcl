# 使用标签追踪成本

# 定义标签变量
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

# 在所有资源上应用标签
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  labels       = var.tags
}

resource "google_compute_network" "vpc" {
  name   = "production-vpc"
  labels = var.tags
}

resource "google_storage_bucket" "state_bucket" {
  name   = "my-terraform-state"
  labels = var.tags
}