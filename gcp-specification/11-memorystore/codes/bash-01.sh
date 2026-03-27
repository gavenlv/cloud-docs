#!/bin/bash
# Memorystore Redis基本操作示例

# 创建基础层Redis实例
gcloud redis instances create my-redis `
    --size=1 `
    --region=us-central1 `
    --redis-version=redis_7_0

# 创建标准层Redis实例(带高可用)
gcloud redis instances create my-redis-standard `
    --size=2 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --network=projects/PROJECT_ID/global/networks/my-vpc

# 列出所有Redis实例
gcloud redis instances list

# 查看实例详情
gcloud redis instances describe my-redis --region=us-central1

# 获取实例IP和端口
gcloud redis instances describe my-redis --region=us-central1 `
    --format="value(host,port)"

# 修改实例大小
gcloud redis instances update my-redis `
    --region=us-central1 `
    --size=3

# 启用AUTH
gcloud redis instances update my-redis `
    --region=us-central1 `
    --enable-auth

# 启用TLS
gcloud redis instances update my-redis `
    --region=us-central1 `
    --transit-encryption-mode=SERVER_AUTHENTICATION

# 触发手动故障转移(标准层)
gcloud redis instances failover my-redis-standard --region=us-central1

# 测试连接
gcloud redis instances test-connection my-redis --region=us-central1

# 删除实例
gcloud redis instances delete my-redis --region=us-central1 --quiet
