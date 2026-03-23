# 初始化（使用本地后端）
terraform init

# 创建状态存储桶
terraform apply -target=google_storage_bucket.state_bucket

# 验证存储桶创建
gsutil ls gs://my-terraform-state