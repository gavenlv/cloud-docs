# 方案1：检查权限
# 1. 检查服务账号权限
gcloud iam service-accounts get-iam-policy \
  terraform@my-project-id.iam.gserviceaccount.com

# 2. 检查项目权限
gcloud projects get-iam-policy my-project-id

# 3. 测试权限
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --project=my-project-id

# 方案2：检查配额
# 1. 查看配额
gcloud compute project-info describe \
  --project=my-project-id

# 2. 查看特定配额
gcloud compute regions describe us-central1 \
  --project=my-project-id \
  --format="table(quotas.metric,quotas.limit,quotas.usage)"

# 3. 申请配额增加
# 访问GCP控制台申请配额增加

# 方案3：检查配置
# 1. 验证配置
terraform validate

# 2. 查看执行计划
terraform plan -out=tfplan

# 3. 查看详细错误
TF_LOG=DEBUG terraform apply

# 方案4：分步部署
# 1. 先创建依赖资源
terraform apply -target=google_compute_network.vpc

# 2. 再创建其他资源
terraform apply -target=google_compute_instance.web_server

# 3. 最后应用所有资源
terraform apply