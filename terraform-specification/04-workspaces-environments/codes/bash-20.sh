# 1. 检查GCS权限
gcloud storage buckets get-iam-policy gs://my-terraform-state

# 2. 确保服务账号有写权限
gcloud storage buckets add-iam-policy-binding \
  gs://my-terraform-state \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# 3. 重新初始化
terraform init

# 4. 创建工作空间
terraform workspace new dev