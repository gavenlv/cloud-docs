# 锁文件位置
.terraform/terraform.tfstate.lock.info

# 强制解锁（危险！）
terraform force-unlock <LOCK_ID>

# 输出：
# Do you really want to force-unlock?
# Terraform will remove the lock on the remote state.
# This will allow others to potentially write to the state.
# Only 'yes' will be accepted to confirm.

# Enter a value: yes
# Successfully unlocked the state!