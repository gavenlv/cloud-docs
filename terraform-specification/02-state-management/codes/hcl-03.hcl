# main.tf
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "my-project-id"
  region  = "us-central1"
}

resource "google_storage_bucket" "state_bucket" {
  name          = "my-terraform-state"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}