# 场景：将dev环境升级到staging环境

# 1. 备份dev工作空间状态
terraform workspace select dev
terraform state pull > dev-state-backup.json

# 2. 导出dev环境配置
terraform output -json > dev-outputs.json

# 3. 切换到staging工作空间
terraform workspace select staging

# 4. 导入dev环境资源到staging
# 注意：需要手动导入每个资源
terraform import \
  google_compute_network.vpc \
  projects/dev-project-id/global/networks/dev-vpc

# 5. 更新staging环境配置
# 编辑terraform-staging.tfvars，使用dev环境的配置

# 6. 应用staging环境配置
terraform apply -var-file="terraform-staging.tfvars" -auto-approve

# 7. 验证staging环境
gcloud compute instances list --project=staging-project-id