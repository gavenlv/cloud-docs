# 1. 切换到dev工作空间
terraform workspace select dev

# 2. 查看执行计划
terraform plan

# 输出：
# Terraform will perform the following actions:
#
#   # google_compute_network.vpc will be created
#   + resource "google_compute_network" "vpc" {
#       + name = "dev-network"
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.

# 3. 应用配置
terraform apply -auto-approve

# 4. 验证资源
gcloud compute networks list
# NAME: dev-network

# 5. 切换到staging工作空间
terraform workspace select staging

# 6. 查看执行计划
terraform plan

# 输出：
# Terraform will perform the following actions:
#
#   # google_compute_network.vpc will be created
#   + resource "google_compute_network" "vpc" {
#       + name = "staging-network"
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.

# 7. 应用配置
terraform apply -auto-approve

# 8. 验证资源
gcloud compute networks list
# NAME: dev-network
# NAME: staging-network

# 9. 切换到prod工作空间
terraform workspace select prod

# 10. 查看执行计划
terraform plan

# 输出：
# Terraform will perform the following actions:
#
#   # google_compute_network.vpc will be created
#   + resource "google_compute_network" "vpc" {
#       + name = "prod-network"
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.

# 11. 应用配置
terraform apply -auto-approve

# 12. 验证所有资源
gcloud compute networks list
# NAME: dev-network
# NAME: staging-network
# NAME: prod-network