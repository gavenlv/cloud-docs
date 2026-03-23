# 方案1：增加超时时间
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  timeouts {
    create = "30m"  # 默认10分钟
    update = "30m"
    delete = "30m"
  }
}

# 方案2：分步创建
# 1. 先创建基础资源
terraform apply -target=google_compute_network.vpc

# 2. 再创建其他资源
terraform apply -target=google_compute_instance.web_server

# 3. 最后应用所有资源
terraform apply

# 方案3：检查资源状态
# 1. 手动检查资源状态
gcloud compute instances describe web-server \
  --zone=us-central1-a \
  --project=my-project-id

# 2. 查看资源日志
gcloud compute instances get-serial-port-output web-server \
  --zone=us-central1-a \
  --project=my-project-id \
  --port=1

# 方案4：删除卡住的资源
# 1. 手动删除资源
gcloud compute instances delete web-server \
  --zone=us-central1-a \
  --project=my-project-id

# 2. 从状态中移除
terraform state rm google_compute_instance.web_server

# 3. 重新创建
terraform apply