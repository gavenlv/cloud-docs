module "vpc" {
  source = "./modules/vpc"

  project_id = "my-project-id"
  network_name = "my-vpc"
  routing_mode = "REGIONAL"
}