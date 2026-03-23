# 更新实例配置
gcloud sql instances patch my-instance `
    --tier=db-n1-standard-4 `
    --storage-size=50GB

# 启用高可用
gcloud sql instances patch my-instance --availability-type=regional

# 开启备份
gcloud sql instances patch my-instance --backup-start-time=02:00

# 开启SSL
gcloud sql instances patch my-instance --require-ssl

# 删除实例
gcloud sql instances delete my-instance

# 强制删除
gcloud sql instances delete my-instance --async