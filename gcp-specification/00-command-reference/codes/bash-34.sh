# 创建用户
gcloud sql users create user_name --instance=my-instance --password=PASSWORD

# 创建随机密码用户
gcloud sql users create user_name --instance=my-instance --random-password-length=16

# 列出用户
gcloud sql users list --instance=my-instance

# 更新用户密码
gcloud sql users set-password user_name --instance=my-instance --password=NEW_PASSWORD

# 删除用户
gcloud sql users delete user_name --instance=my-instance