# 1. 使用串行创建
# 控制并发数量
terraform apply -parallelism=1

# 2. 监控配额使用
# 设置配额告警
gcloud alpha monitoring policies create \
  --policy-from-file=quota-policy.yaml

# 3. 使用批量操作
# 使用Terraform的批量操作
# 减少API调用次数

# 4. 优化资源创建
# 使用实例模板
# 使用实例组
# 减少API调用