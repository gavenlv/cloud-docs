terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC网络
module "vpc" {
  source = "./modules/vpc"

  project_id   = var.project_id
  network_name = var.network_name
  routing_mode = var.routing_mode
}

# 子网
module "subnet_public" {
  source = "./modules/subnet"

  project_id    = var.project_id
  region       = var.region
  network_name = var.network_name
  subnet_name  = "public-subnet"
  ip_cidr_range = var.public_subnet_cidr
}

module "subnet_private" {
  source = "./modules/subnet"

  project_id    = var.project_id
  region       = var.region
  network_name = var.network_name
  subnet_name  = "private-subnet"
  ip_cidr_range = var.private_subnet_cidr
}

# 防火墙规则
module "firewall_ssh" {
  source = "./modules/firewall"

  project_id   = var.project_id
  network_id  = module.vpc.network_id
  rule_name   = "allow-ssh"
  allow_ports = ["22"]
  source_ranges = var.ssh_source_ranges
}

module "firewall_http" {
  source = "./modules/firewall"

  project_id   = var.project_id
  network_id  = module.vpc.network_id
  rule_name   = "allow-http"
  allow_ports = ["80", "443"]
  source_ranges = ["0.0.0.0/0"]
}

# 计算实例
module "web_server" {
  source = "./modules/compute"

  project_id = var.project_id
  zone       = "${var.region}-a"
  name       = "web-server"
  network    = module.vpc.network_id
  subnetwork = module.subnet_public.subnet_id

  boot_disk_size = 50
  boot_disk_type = "pd-ssd"
}

module "db_server" {
  source = "./modules/compute"

  project_id = var.project_id
  zone       = "${var.region}-a"
  name       = "db-server"
  network    = module.vpc.network_id
  subnetwork = module.subnet_private.subnet_id

  boot_disk_size = 200
  boot_disk_type = "pd-ssd"
}