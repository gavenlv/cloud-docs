# 初始化工作空间
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 切换工作空间
terraform workspace list
# * default
#   dev
#   staging
#   prod

terraform workspace select prod

# 查看当前工作空间
terraform workspace show
# prod

# 在不同工作空间中应用
cd environments/prod
terraform workspace select prod
terraform apply

cd environments/dev
terraform workspace select dev
terraform apply

# 每个工作空间有独立的状态文件：
# gs://my-terraform-state/prod/terraform.tfstate
# gs://my-terraform-state/dev/terraform.tfstate
# gs://my-terraform-state/staging/terraform.tfstate