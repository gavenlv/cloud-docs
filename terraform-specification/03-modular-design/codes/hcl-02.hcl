terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                            = var.network_name
  auto_create_subnetworks       = var.auto_create_subnetworks
  routing_mode                   = var.routing_mode
  mtu                             = var.mtu
  delete_default_routes_on_create = var.delete_default_routes_on_create
  description                     = var.description
  project                         = var.project_id
  labels                          = var.labels
}