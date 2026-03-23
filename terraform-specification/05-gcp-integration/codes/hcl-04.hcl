# main.tf
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    auto_delete = true
    type       = "pd-balanced"
    size       = 50
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  tags = ["web-server", "http-server"]

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }

  metadata = {
    ssh-keys = "user:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }
}

output "instance_id" {
  value = google_compute_instance.web_server.id
}

output "external_ip" {
  value = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}