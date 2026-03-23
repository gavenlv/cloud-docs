# 组合过滤条件
gcloud compute instances list --filter="zone:us-central1-a AND status:RUNNING AND machineType:e2-medium"

# 正则匹配
gcloud compute instances list --filter="name~my-instance-.*"

# 按标签筛选
gcloud compute instances list --filter="labels.env=prod"

# 时间范围筛选
gcloud logging read "timestamp>=2024-01-01T00:00:00Z AND timestamp<2024-01-02T00:00:00Z" --limit=10