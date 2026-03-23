# 方案1：刷新状态
terraform refresh

# 方案2：重新初始化
terraform init -reconfigure

# 方案3：从备份恢复
# 1. 备份当前状态
terraform state pull > current-state-backup.tfstate

# 2. 恢复备份
terraform state push backup-state.tfstate

# 3. 验证状态
terraform state list

# 方案4：重新导入资源
# 1. 删除不一致的资源状态
terraform state rm google_compute_instance.web_server

# 2. 重新导入资源
terraform import google_compute_instance.web_server \
  projects/my-project-id/zones/us-central1-a/instances/web-server

# 方案5：重建状态（最后手段）
# 1. 备份配置
cp main.tf main.tf.backup

# 2. 删除状态文件
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

# 3. 重新初始化
terraform init

# 4. 导入现有资源
terraform import <RESOURCE_ADDRESS> <IMPORT_ID>