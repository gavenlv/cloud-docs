# 项目结构
terraform-project/
├── main.tf
├── variables.tf
├── terraform-dev.tfvars
├── terraform-staging.tfvars
└── terraform-prod.tfvars

# main.tf
variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "environment" {
  description = "环境名称"
  type        = string
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

resource "google_compute_instance" "web_server" {
  count        = var.instance_count
  name         = "${var.environment}-web-server-${count.index}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}

# 使用方法
terraform workspace new dev
terraform apply -var-file="terraform-dev.tfvars"

terraform workspace new staging
terraform apply -var-file="terraform-staging.tfvars"

terraform workspace new prod
terraform apply -var-file="terraform-prod.tfvars"