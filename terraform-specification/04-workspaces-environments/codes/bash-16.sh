# 1. 检查工作空间是否存在
terraform workspace list

# 2. 如果不存在，创建工作空间
terraform workspace new dev

# 3. 如果存在但状态文件丢失，重新初始化
terraform init

# 4. 如果远程状态文件丢失，从备份恢复
gsutil cp \
  gs://my-terraform-state/env:/dev/terraform.tfstate.backup \
  gs://my-terraform-state/env:/dev/terraform.tfstate