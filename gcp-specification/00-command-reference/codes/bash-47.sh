# 查看配额使用
gcloud compute regions describe us-central1 --format="yaml(quotas)"

# 查看资源配额
gcloud compute project-info describe --project=PROJECT_ID

# 查看API启用状态
gcloud services list --enabled

# 检查服务账号权限
gcloud iam service-accounts get-iam-policy sa@PROJECT_ID.iam.gserviceaccount.com