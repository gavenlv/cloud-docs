# 1. 列出所有工作空间
terraform workspace list
#   default
# * dev
#   staging
#   prod

# 2. 切换到要删除的工作空间
terraform workspace select dev

# 3. 删除工作空间中的所有资源
terraform destroy -auto-approve

# 4. 删除工作空间
terraform workspace delete dev

# 输出：
# Deleted workspace "dev"!

# 5. 验证工作空间已删除
terraform workspace list
#   default
#   staging
#   prod

# 6. 验证状态文件已删除
ls -la terraform.tfstate.d/
# total 18
# drwxr-xr-x  2 user user 4096 Jan 15 10:35 .
# drwxr-xr-x  5 user user 4096 Jan 15 10:35 ..
# -rw-r--r--  1 user user 1234 Jan 15 10:30 default.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:32 staging.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:33 prod.tfstate