resource "google_compute_subnetwork" "subnet_public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = false
  secondary_ip_range {
    range_name    = "secondary-range"
    ip_cidr_range = "10.0.1.128/26"
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling      = 0.5
    metadata          = "INCLUDE_ALL_METADATA"
  }

  labels = {
    environment = "production"
    type        = "public"
  }
}

resource "google_compute_subnetwork" "subnet_private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true

  labels = {
    environment = "production"
    type        = "private"
  }
}