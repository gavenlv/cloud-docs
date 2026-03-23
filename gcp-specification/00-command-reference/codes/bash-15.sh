# 列出所有服务
gcloud run services list --region=us-central1

# 查看服务详情
gcloud run services describe my-service --region=us-central1

# 获取服务URL
gcloud run services describe my-service --region=us-central1 --format="value(status.url)"

# 获取服务副本数
gcloud run services describe my-service --region=us-central1 --format="value(status.conditions[0].message)"

# 查看修订版本列表
gcloud run revisions list --region=us-central1 --service=my-service

# 查看特定修订版本
gcloud run revisions describe my-service-00001-abc --region=us-central1