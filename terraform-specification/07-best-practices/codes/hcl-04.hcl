# 使用远程后端提高性能

# 错误示例：使用本地后端
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# 正确示例：使用GCS后端
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"
  }
}

# 优化GCS后端性能
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"

    # 启用状态锁定
    # GCS后端默认支持状态锁定

    # 使用多区域存储桶提高可用性
    # bucket = "my-terraform-state"  # 多区域存储桶
  }
}