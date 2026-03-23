# variables.tf
variable "subnets" {
  description = "子网配置"
  type = map(object({
    ip_cidr_range = string
    region       = string
    description  = string
  }))
  default = {
    public = {
      ip_cidr_range = "10.0.1.0/24"
      region       = "us-central1"
      description  = "Public subnet"
    }
    private = {
      ip_cidr_range = "10.0.2.0/24"
      region       = "us-central1"
      description  = "Private subnet"
    }
    dmz = {
      ip_cidr_range = "10.0.3.0/24"
      region       = "us-central1"
      description  = "DMZ subnet"
    }
  }
}

# main.tf
resource "google_compute_network" "vpc" {
  name                    = "production-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = "${each.key}-subnet"
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  description   = each.value.description

  labels = {
    type = each.key
  }
}

output "subnet_ids" {
  value = {
    for name, subnet in google_compute_subnetwork.subnets : name => subnet.id
  }
}

output "subnet_cidrs" {
  value = {
    for name, subnet in google_compute_subnetwork.subnets : name => subnet.ip_cidr_range
  }
}