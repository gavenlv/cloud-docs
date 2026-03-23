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
  project = "my-project-id"
  region  = "us-central1"
}

module "vpc" {
  source = "./modules/vpc"

  project_id   = "my-project-id"
  network_name = "production-vpc"
}

module "web_server" {
  source = "./modules/compute"

  project_id = "my-project-id"
  zone       = "us-central1-a"
  name       = "web-server-1"
  machine_type = "e2-medium"
  image      = "debian-cloud/debian-11"
  network    = module.vpc.network_id

  boot_disk_size = 100
  boot_disk_type = "pd-ssd"

  service_account = "terraform@my-project-id.iam.gserviceaccount.com"

  labels = {
    environment = "production"
    role        = "web"
  }
}

module "db_server" {
  source = "./modules/compute"

  project_id = "my-project-id"
  zone       = "us-central1-a"
  name       = "db-server-1"
  machine_type = "e2-highmem-4"
  image      = "debian-cloud/debian-11"
  network    = module.vpc.network_id

  boot_disk_size = 500
  boot_disk_type = "pd-ssd"

  service_account = "terraform@my-project-id.iam.gserviceaccount.com"

  labels = {
    environment = "production"
    role        = "database"
  }
}