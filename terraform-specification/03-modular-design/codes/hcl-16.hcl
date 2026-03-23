module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.0"

  project_id   = "my-project-id"
  network_name = "my-vpc"
}