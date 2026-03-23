# 方案1：减少并发
# 1. 使用串行创建
resource "google_compute_instance" "web_server" {
  count = 3
  name  = "web-server-${count.index}"

  # Terraform默认串行创建
  # 可以使用parallelism控制并发
}

# 2. 使用Terraform并发控制
terraform apply -parallelism=1

# 方案2：分批创建
# 1. 分批创建资源
terraform apply -target=google_compute_instance.web_server[0]
terraform apply -target=google_compute_instance.web_server[1]
terraform apply -target=google_compute_instance.web_server[2]

# 2. 使用sleep延迟
resource "google_compute_instance" "web_server" {
  count = 3
  name  = "web-server-${count.index}"

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# 方案3：申请配额增加
# 1. 查看配额
gcloud compute project-info describe \
  --project=my-project-id

# 2. 申请配额增加
# 访问GCP控制台申请配额增加

# 方案4：使用指数退避
# 在CI/CD中使用指数退避
#!/bin/bash
for i in {1..3}; do
  terraform apply -auto-approve && break
  sleep $((2 ** i))
done