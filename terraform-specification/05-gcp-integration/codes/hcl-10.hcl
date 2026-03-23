resource "google_storage_bucket" "state_bucket" {
  name          = "my-terraform-state"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  logging {
    log_bucket = google_storage_bucket.log_bucket.id
  }

  labels = {
    environment = "production"
    managed_by   = "terraform"
  }
}

resource "google_storage_bucket" "log_bucket" {
  name          = "my-terraform-logs"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}