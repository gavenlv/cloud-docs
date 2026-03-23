# SSH连接（Linux）
gcloud compute ssh my-instance --zone=us-central1-a

# 指定用户SSH
gcloud compute ssh user@my-instance --zone=us-central1-a

# 使用特定密钥连接
gcloud compute ssh my-instance --zone=us-central1-a --ssh-key-file=~/.ssh/my_key

# Windows RDP获取密码
gcloud compute instances get-password my-instance --zone=us-central1-a

# 获取串口输出（调试）
gcloud compute instances get-serial-port-output my-instance --zone=us-central1-a

# 重置Windows密码
gcloud compute instances reset-windows-password my-instance --zone=us-central1-a