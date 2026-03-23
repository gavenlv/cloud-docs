# 导出实例配置
gcloud compute instances export my-instance --zone=us-central1-a --destination=instance.yaml

# 从配置导入实例
gcloud compute instances import my-instance --zone=us-central1-a --source=instance.yaml

# 导出集群配置
gcloud container clusters describe my-cluster --zone=us-central1-a --format=yaml > cluster.yaml