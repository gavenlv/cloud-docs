module "vpc" {
  source = "./modules/vpc"

  project_id = "my-project-id"
  network_name = "production-vpc"
  routing_mode = "GLOBAL"
  mtu = 1460
  delete_default_routes_on_create = true
  description = "Production VPC network"
  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}