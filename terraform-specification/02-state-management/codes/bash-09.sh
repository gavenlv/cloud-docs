# 查看状态中的所有资源
terraform state list

# 移除已删除的资源
terraform state rm google_compute_instance.old_server

# 移除多个资源
terraform state rm \
  google_compute_instance.server1 \
  google_compute_instance.server2 \
  google_compute_instance.server3

# 移除整个模块
terraform state rm module.vpc_module

# 查看特定资源状态
terraform state show google_compute_network.vpc_network