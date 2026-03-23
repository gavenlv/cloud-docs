# 1. 列出所有工作空间
terraform workspace list

# 2. 如果工作空间已存在，直接切换
terraform workspace select prod

# 3. 如果需要删除工作空间，先销毁资源
terraform workspace select prod
terraform destroy -auto-approve

# 4. 删除工作空间
terraform workspace delete prod

# 5. 重新创建工作空间
terraform workspace new prod