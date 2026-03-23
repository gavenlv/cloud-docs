# 列出所有集群
gcloud container clusters list

# 获取特定项目的集群
gcloud container clusters list --project=PROJECT_ID

# 按区域筛选
gcloud container clusters list --filter="location:us-central1"

# 查看集群详情
gcloud container clusters describe my-cluster --zone=us-central1-a

# 获取集群凭证（配置kubectl）
gcloud container clusters get-credentials my-cluster --zone=us-central1-a

# 查看集群端点
gcloud container clusters describe my-cluster --zone=us-central1-a --format="value(endpoint)"

# 查看集群版本
gcloud container clusters describe my-cluster --zone=us-central1-a --format="value(currentMasterVersion)"