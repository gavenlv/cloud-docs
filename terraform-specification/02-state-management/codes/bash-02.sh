# GCS使用对象锁机制
# 锁文件：gs://my-terraform-state/prod/.terraform.lock

# 查看锁状态
gsutil ls gs://my-terraform-state/prod/.terraform.lock

# 强制解锁
terraform force-unlock <LOCK_ID>