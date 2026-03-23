# 1. 检查备份
ls -la terraform.tfstate*

# 2. 恢复备份
cp terraform.tfstate.backup terraform.tfstate

# 3. 验证状态
terraform state list

# 4. 如果没有备份，尝试刷新
terraform refresh