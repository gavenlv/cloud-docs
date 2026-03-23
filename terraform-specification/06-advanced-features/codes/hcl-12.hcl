# 使用变量存储敏感数据
variable "db_password" {
  description = "数据库密码"
  type        = string
  sensitive   = true
}

# 使用Terraform Cloud变量
# 在Terraform Cloud控制台中设置敏感变量

# 使用环境变量
export TF_VAR_db_password="my-secret-password"

# 使用KMS加密
data "google_kms_secret" "db_password" {
  ciphertext = "CiQA..."
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.db.name
  password = data.google_kms_secret.db_password.plaintext
}