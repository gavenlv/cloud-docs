# 1. 在终端1中锁定dev工作空间
terraform workspace select dev
terraform apply -auto-approve

# 2. 在终端2中尝试锁定dev工作空间（应该失败）
terraform workspace select dev
terraform apply -auto-approve

# 输出：
# Error: Error acquiring the state lock
# Lock Info:
#   ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
#   Path:      gs://my-terraform-state/env:/dev/.terraform.lock
#   Operation: OperationTypeApply
#   Who:       user@example.com
#   Version:   1.5.0
#   Created:   2024-01-15 10:30:00.000 UTC

# 3. 在终端2中切换到staging工作空间（应该成功）
terraform workspace select staging
terraform apply -auto-approve

# 输出：
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.