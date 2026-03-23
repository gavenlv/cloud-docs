# 1. 启用状态版本化
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"

    # GCS自动版本化
    # 可以恢复到任意版本
  }
}

# 2. 定期备份
# 添加到cron任务
0 0 * * * terraform state pull > /backup/terraform-state-$(date +\%Y\%m\%d).tfstate

# 3. 使用Terraform Cloud
# Terraform Cloud提供自动备份
# 可以恢复到任意历史版本

# 4. 监控状态文件
# 设置告警
# 当状态文件丢失时立即通知