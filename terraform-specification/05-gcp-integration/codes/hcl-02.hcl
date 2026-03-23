# 场景：跨区域部署
provider "google" {
  alias   = "us-central"
  project = "my-project-id"
  region  = "us-central1"
}

provider "google" {
  alias   = "europe-west"
  project = "my-project-id"
  region  = "europe-west1"
}

# 使用Provider别名
resource "google_compute_instance" "us_instance" {
  provider = google.us-central
  name     = "us-server"
  zone     = "us-central1-a"
  # ...
}

resource "google_compute_instance" "europe_instance" {
  provider = google.europe-west
  name     = "europe-server"
  zone     = "europe-west1-b"
  # ...
}