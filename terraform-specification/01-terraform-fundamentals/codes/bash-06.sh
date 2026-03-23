# 使用terraform import导入现有资源
terraform import google_compute_network.vpc_network projects/your-project-id/global/networks/existing-network

# 使用terraform state命令管理状态
terraform state list
terraform state show google_compute_network.vpc_network
terraform state rm google_compute_network.vpc_network  # 从状态中移除