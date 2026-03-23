# 列出实例
gcloud sql instances list

# 查看实例详情
gcloud sql instances describe my-instance

# 获取连接名
gcloud sql instances describe my-instance --format="value(connectionName)"

# 获取IP
gcloud sql instances describe my-instance --format="value(ipAddresses[0].ipAddress)"

# 查看实例状态
gcloud sql instances describe my-instance --format="value(state)"