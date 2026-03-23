resource "google_compute_instance" "vm" {
  name         = "test-vm"
  machine_type = "e2-medium"
  network_interface {
    network = "default"  # 硬编码网络名称
  }
}

resource "google_compute_network" "vpc" {
  name = "new-network"
}