terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

resource "google_compute_instance" "instance" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = var.tags
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.image
    }
    auto_delete = true
    type       = var.boot_disk_type
    size       = var.boot_disk_size
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = var.metadata

  dynamic "service_account" {
    for_each = var.service_account != null ? [1] : []
    content {
      email  = var.service_account
      scopes = var.scopes
    }
  }

  shielded_instance_config {
    enable_secure_boot          = var.enable_shielded_vm
    enable_vtpm               = var.enable_shielded_vm
    enable_integrity_monitoring = var.enable_shielded_vm
  }

  confidential_instance_config {
    enable_confidential_compute = var.confidential_compute
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }
}