# 刷新状态文件（从云平台同步最新状态）
terraform refresh

# 输出：
# google_compute_network.vpc_network: Refreshing state... [id=projects/my-project/global/networks/my-vpc]
# google_compute_subnetwork.subnet_a: Refreshing state... [id=projects/my-project/regions/us-central1/subnetworks/my-subnet]
#
# Refresh complete! The state is up-to-date.

# 只刷新特定资源
terraform refresh -target=google_compute_network.vpc_network