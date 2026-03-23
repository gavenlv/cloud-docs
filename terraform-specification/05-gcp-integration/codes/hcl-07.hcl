resource "google_compute_network" "vpc_network" {
  name                    = "production-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"

  description = "Production VPC network managed by Terraform"

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}

output "vpc_id" {
  value = google_compute_network.vpc_network.id
}

output "vpc_name" {
  value = google_compute_network.vpc_network.name
}