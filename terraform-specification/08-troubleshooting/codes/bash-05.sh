# 方案1：从备份恢复
# 如果有备份
terraform state push backup-state.tfstate

# 方案2：从远程后端恢复
# GCS
gsutil cp \
  gs://my-terraform-state/terraform.tfstate.backup \
  terraform.tfstate

# S3
aws s3 cp \
  s3://my-terraform-state/terraform.tfstate.backup \
  terraform.tfstate

# 方案3：重新导入所有资源
# 1. 查询现有资源
gcloud compute instances list
gcloud compute networks list

# 2. 重新导入
terraform import google_compute_network.vpc \
  projects/my-project-id/global/networks/my-vpc

terraform import google_compute_instance.web_server \
  projects/my-project-id/zones/us-central1-a/instances/web-server

# 方案4：重建状态（从配置）
# 1. 创建新状态
terraform init

# 2. 导入资源
terraform import <RESOURCE_ADDRESS> <IMPORT_ID>

# 3. 验证状态
terraform state list
terraform plan