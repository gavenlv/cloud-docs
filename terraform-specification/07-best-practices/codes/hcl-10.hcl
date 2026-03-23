# 使用预留实例降低成本

# 错误示例：使用按需实例
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  scheduling {
    preemptible       = false
    automatic_restart = true
  }
}

# 正确示例：使用预留实例
resource "google_compute_reservation" "web_reservation" {
  name = "web-reservation"
  zone = "us-central1-a"

  specific_sku {
    count = 3
    name  = "e2-medium"
  }

  commitment {
    plan = "MONTHLY"
  }
}

resource "google_compute_instance" "web_server" {
  count        = 3
  name         = "web-server-${count.index}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  scheduling {
    preemptible       = false
    automatic_restart = true
  }

  reservation_affinity {
    type = "SPECIFIC_RESERVATION"
    key  = "compute.googleapis.com/reservation-name"
    values = [
      google_compute_reservation.web_reservation.name
    ]
  }
}

# 使用抢占式实例降低成本
resource "google_compute_instance" "batch_worker" {
  count        = 5
  name         = "batch-worker-${count.index}"
  machine_type = "e2-medium"

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}