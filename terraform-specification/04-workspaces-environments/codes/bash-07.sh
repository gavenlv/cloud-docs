# 1. 初始化远程后端
terraform init

# 输出：
# Initializing the backend...
# Successfully configured the backend "gcs"! Terraform will automatically
# use this backend unless you change configuration or run `terraform init` again.

# 2. 创建工作空间
terraform workspace new dev
# Created and switched to workspace "dev"!

# 3. 应用配置
terraform apply -auto-approve

# 4. 验证远程状态文件
gsutil ls gs://my-terraform-state/
# gs://my-terraform-state/env:/default/
# gs://my-terraform-state/env:/dev/

# 5. 查看dev工作空间的状态文件
gsutil cat gs://my-terraform-state/env:/dev/terraform.tfstate

# 6. 创建staging工作空间
terraform workspace new staging

# 7. 应用配置
terraform apply -auto-approve

# 8. 验证远程状态文件
gsutil ls gs://my-terraform-state/
# gs://my-terraform-state/env:/default/
# gs://my-terraform-state/env:/dev/
# gs://my-terraform-state/env:/staging/

# 9. 查看staging工作空间的状态文件
gsutil cat gs://my-terraform-state/env:/staging/terraform.tfstate