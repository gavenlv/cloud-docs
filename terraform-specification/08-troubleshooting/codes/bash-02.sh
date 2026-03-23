# 1. 使用远程后端
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"
  }
}

# 2. 设置锁定超时
# GCS后端默认锁定超时为5分钟
# 可以通过环境变量调整
export TF_LOCK_TIMEOUT=10m

# 3. 使用工作空间隔离
terraform workspace select dev
# 每个工作空间有独立的状态锁定

# 4. 避免并发操作
# 在CI/CD中使用互斥锁
# 或使用Terraform Cloud的自动队列