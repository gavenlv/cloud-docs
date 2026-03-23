# 查看状态文件内容
cat terraform.tfstate

# 查看状态文件JSON格式
terraform show -json | jq .

# 查看特定资源状态
terraform show google_compute_network.vpc_network

# 输出：
# # google_compute_network.vpc_network:
# resource "google_compute_network" "vpc_network" {
#     id                           = "projects/your-project-id/global/networks/terraform-network"
#     name                         = "terraform-network"
#     auto_create_subnetworks        = false
#     routing_config                = []
#     self_link                    = "https://www.googleapis.com/compute/v1/projects/your-project-id/global/networks/terraform-network"
# }