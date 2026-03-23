resource "google_compute_network" "vpc" {
  name = "new-network"
}

resource "google_compute_instance" "vm" {
  name         = "test-vm"
  machine_type = "e2-medium"
  network_interface {
    network = google_compute_network.vpc.id  # 使用引用
  }
}