# variables.tf
variable "db_password" {
  type      = string
  sensitive = true  # 标记为敏感
}

# outputs.tf
output "db_connection_string" {
  sensitive = true  # 输出标记为敏感
  value     = "postgresql://user:${var.db_password}@host:5432/db"
}