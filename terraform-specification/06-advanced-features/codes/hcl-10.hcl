# main.tf
terraform {
  cloud {
    organization = "my-organization"
    workspaces {
      name = "production"
    }
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

resource "google_compute_network" "vpc" {
  name = "production-vpc"
}