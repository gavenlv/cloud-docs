# backend.tf
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "env:/${terraform.workspace}"
    credentials = "path/to/service-account.json"
  }
}