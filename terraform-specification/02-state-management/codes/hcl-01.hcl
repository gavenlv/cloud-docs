terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
  }
}