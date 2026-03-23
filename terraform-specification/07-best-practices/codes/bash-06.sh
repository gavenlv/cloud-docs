# 备份状态文件
terraform state pull > backup.tfstate

# 恢复状态文件
terraform state push backup.tfstate

# 列出状态中的资源
terraform state list

# 从状态中移除资源
terraform state rm <RESOURCE_ADDRESS>

# 移动资源
terraform state mv <SOURCE_ADDRESS> <DESTINATION_ADDRESS>