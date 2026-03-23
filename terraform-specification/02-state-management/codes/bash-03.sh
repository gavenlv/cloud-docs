# S3使用DynamoDB表进行锁定
# 表结构：
# {
#   "LockID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
#   "Info": "base64编码的锁信息"
# }

# 强制解锁
terraform force-unlock <LOCK_ID>