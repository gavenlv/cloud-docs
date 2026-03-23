module "vpc" {
  source = "./modules/vpc"

  project_id = "my-project-id"
  network_name = "production-vpc"
}