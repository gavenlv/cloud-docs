# 列出状态中的资源
terraform state list

# 显示资源详细信息
terraform state show google_compute_instance.web_server

# 从状态中移除资源
terraform state rm google_compute_instance.web_server

# 移动资源
terraform state mv google_compute_instance.web_server google_compute_instance.web_server_new

# 拉取状态
terraform state pull > state.json

# 推送状态
terraform state push state.json