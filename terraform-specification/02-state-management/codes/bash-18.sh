# 1. 检查锁是否过期
# 如果锁持有者已经完成操作，可以强制解锁

# 2. 强制解锁
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890

# 3. 验证
terraform plan
# 应该可以正常执行