# backend.tf
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "${terraform.workspace}"
    credentials = "path/to/service-account.json"
  }
}