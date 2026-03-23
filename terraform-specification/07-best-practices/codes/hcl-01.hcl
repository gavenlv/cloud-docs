# 使用最小权限原则

# 创建专用服务账号
resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Service Account"
}

# 分配最小必要权限
resource "google_project_iam_member" "terraform_compute_admin" {
  project = "my-project-id"
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# 而不是使用editor角色（权限过大）
# resource "google_project_iam_member" "terraform_editor" {
#   project = "my-project-id"
#   role    = "roles/editor"
#   member  = "serviceAccount:${google_service_account.terraform.email}"
# }

# 使用条件IAM限制访问
resource "google_project_iam_member" "terraform_compute_admin" {
  project = "my-project-id"
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.terraform.email}"

  condition {
    title       = "Only allow from specific IP"
    expression  = "request.ip in ['1.2.3.4/32']"
    description = "Only allow access from specific IP address"
  }
}