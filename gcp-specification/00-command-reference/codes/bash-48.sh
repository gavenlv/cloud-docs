# 试运行（不实际执行）
gcloud compute instances create my-instance --zone=us-central1-a --dry-run

# 异步操作（不等待完成）
gcloud sql instances delete my-instance --async

# 查看操作状态
gcloud operations list --limit=10

# 查看特定操作
gcloud operations describe OPERATION_ID --zone=us-central1-a