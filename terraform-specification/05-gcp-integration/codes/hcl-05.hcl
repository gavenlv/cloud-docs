resource "google_compute_instance_template" "web_template" {
  name        = "web-server-template"
  machine_type = "e2-medium"
  region      = "us-central1"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot        = true
    disk_size_gb = 50
    disk_type    = "pd-balanced"
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl start nginx
    EOT
  }

  labels = {
    environment = "production"
    role        = "web"
  }
}