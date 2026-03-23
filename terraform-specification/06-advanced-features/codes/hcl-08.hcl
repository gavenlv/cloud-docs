# 查询项目信息
data "google_project" "project" {
  project_id = "my-project-id"
}

# 查询项目IAM策略
data "google_iam_policy" "project_policy" {
  binding {
    role = "roles/editor"
    members = [
      "user:admin@example.com",
      "serviceAccount:terraform@my-project-id.iam.gserviceaccount.com"
    ]
  }
}

# 使用项目信息
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  project      = data.google_project.project.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  labels = {
    project_number = data.google_project.project.number
  }
}

output "project_number" {
  value = data.google_project.project.number
}

output "project_id" {
  value = data.google_project.project.project_id
}