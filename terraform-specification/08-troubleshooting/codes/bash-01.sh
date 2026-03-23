# 方案1：等待锁定自动释放
# 锁定通常在操作完成后自动释放
# 如果操作异常终止，可能需要手动释放

# 方案2：强制解锁（谨慎使用）
terraform force-unlock <LOCK_ID>

# 示例：
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890

# 方案3：检查锁定状态
# GCS后端
gsutil stat gs://my-terraform-state/.terraform.lock

# S3后端
aws s3api get-object \
  --bucket my-terraform-state \
  --key .terraform.lock \
  /tmp/lock.json

# 方案4：删除锁定文件（最后手段）
# 本地后端
rm -f .terraform.lock.hcl

# GCS后端
gsutil rm gs://my-terraform-state/.terraform.lock

# S3后端
aws s3 rm s3://my-terraform-state/.terraform.lock