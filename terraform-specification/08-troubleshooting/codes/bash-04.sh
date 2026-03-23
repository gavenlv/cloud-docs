# 1. 定期备份状态
# 添加到CI/CD流程
terraform state pull > state-backup-$(date +%Y%m%d).tfstate

# 2. 使用版本控制
# 将状态文件纳入版本控制（不推荐生产环境）
# 或使用专门的版本化存储

# 3. 启用状态版本化
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"

    # GCS自动版本化
    # 每次更新都会创建新版本
  }
}

# 4. 监控状态变更
# 使用Terraform Cloud的状态监控
# 或自定义监控脚本