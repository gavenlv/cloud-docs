module "vpc" {
  source = "github.com/company/terraform-modules//vpc?ref=feature/new-routing"

  project_id = "my-project-id"
  network_name = "my-vpc"
}