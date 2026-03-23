terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "env:/${terraform.workspace}"
    credentials = "path/to/service-account.json"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source = "./modules/vpc"

  project_id   = var.project_id
  network_name = "${var.environment}-vpc"
}

module "compute" {
  source = "./modules/compute"

  project_id  = var.project_id
  vpc_id      = module.vpc.network_id
  environment = var.environment

  instance_count = var.instance_count
}