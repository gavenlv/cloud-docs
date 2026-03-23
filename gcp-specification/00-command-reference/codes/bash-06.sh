# 启动实例
gcloud compute instances start my-instance --zone=us-central1-a

# 停止实例
gcloud compute instances stop my-instance --zone=us-central1-a

# 重启实例（先停再开）
gcloud compute instances stop my-instance --zone=us-central1-a
gcloud compute instances start my-instance --zone=us-central1-a

# 删除实例
gcloud compute instances delete my-instance --zone=us-central1-a

# 强制删除（不等待确认）
gcloud compute instances delete my-instance --zone=us-central1-a --quiet

# 批量删除
gcloud compute instances delete instance-1 instance-2 --zone=us-central1-a --quiet