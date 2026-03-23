# 查看项目日志
gcloud logging read "resource.type=gce_instance" --limit=10

# 按时间过滤
gcloud logging read "timestamp>=2024-01-01T00:00:00Z" --limit=10

# 按严重程度过滤
gcloud logging read "severity>=ERROR" --limit=10

# 查看特定资源日志
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_id=INSTANCE_ID" --limit=10

# 实时跟踪日志
gcloud logging read "resource.type=gce_instance" --follow --limit=10