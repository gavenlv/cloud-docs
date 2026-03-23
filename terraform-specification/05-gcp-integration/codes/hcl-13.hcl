# 使用数据源查询现有资源
data "google_compute_network" "existing_vpc" {
  name = "existing-network"
}

data "google_compute_subnetwork" "existing_subnet" {
  name   = "existing-subnet"
  region = "us-central1"
}

data "google_compute_image" "debian_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

data "google_compute_zones" "available_zones" {
  region = "us-central1"
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = data.google_compute_zones.available_zones.names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.existing_subnet.id
  }
}

output "available_zones" {
  value = data.google_compute_zones.available_zones.names
}