# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  credentials = file("terraform-key.json")
  project     = "my-project-id"
  region      = "us-central1"
}

resource "google_compute_network" "vpc" {
  name = "terraform-network"
}