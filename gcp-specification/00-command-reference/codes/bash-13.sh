# 更新集群
gcloud container clusters update my-cluster `
    --zone=us-central1-a `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=10

# 启用addon
gcloud container clusters update my-cluster --zone=us-central1-a --enable-network-policy

# 升级集群版本
gcloud container clusters upgrade my-cluster --zone=us-central1-a --master

# 删除集群
gcloud container clusters delete my-cluster --zone=us-central1-a

# 快速删除（跳过确认）
gcloud container clusters delete my-cluster --zone=us-central1-a --quiet