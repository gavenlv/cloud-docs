# 1. 初始化
terraform init

# 2. 创建工作空间
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 3. 部署dev环境
terraform workspace select dev
terraform apply -var-file="terraform-dev.tfvars" -auto-approve

# 4. 验证dev环境
gcloud compute instances list --project=dev-project-id
# NAME: dev-web-server-0

# 5. 部署staging环境
terraform workspace select staging
terraform apply -var-file="terraform-staging.tfvars" -auto-approve

# 6. 验证staging环境
gcloud compute instances list --project=staging-project-id
# NAME: staging-web-server-0
# NAME: staging-web-server-1

# 7. 部署prod环境
terraform workspace select prod
terraform apply -var-file="terraform-prod.tfvars" -auto-approve

# 8. 验证prod环境
gcloud compute instances list --project=prod-project-id
# NAME: prod-web-server-0
# NAME: prod-web-server-1
# NAME: prod-web-server-2

# 9. 查看所有工作空间状态
terraform workspace list
#   default
# * dev
#   staging
#   prod

# 10. 查看远程状态文件
gsutil ls gs://my-terraform-state/
# gs://my-terraform-state/env:/default/
# gs://my-terraform-state/env:/dev/
# gs://my-terraform-state/env:/staging/
# gs://my-terraform-state/env:/prod/