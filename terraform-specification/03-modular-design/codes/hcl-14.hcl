module "vpc" {
  source = "github.com/company/terraform-modules//vpc?ref=v1.0.0"

  project_id = "my-project-id"
  network_name = "my-vpc"
}