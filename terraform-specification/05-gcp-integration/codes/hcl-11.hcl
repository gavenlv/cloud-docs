resource "google_sql_database_instance" "master" {
  name             = "master-db"
  database_version = "POSTGRES_14"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    database_flags {
      name  = "max_connections"
      value = "100"
    }

    ip_configuration {
      authorized_networks {
        name = "allow-vpc"
        value = google_compute_subnetwork.subnet_private.ip_cidr_range
      }

      private_network {
        network_id = google_compute_network.vpc_network.id
      }
    }

    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      transaction_log_retention_days = 7
      point_in_time_recovery_enabled = true
    }

    maintenance_window {
      day  = 7
      hour = 3
    }
  }

  deletion_protection = true

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}

resource "google_sql_database" "app_db" {
  name     = "app"
  instance = google_sql_database_instance.master.name
  charset  = "UTF8"
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.master.name
  password = var.db_password
}