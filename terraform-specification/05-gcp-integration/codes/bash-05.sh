# 1. 初始化
terraform init

# 2. 验证配置
terraform validate

# 3. 查看执行计划
terraform plan

# 4. 应用配置
terraform apply -auto-approve

# 5. 验证资源
gcloud compute forwarding-rules list
gcloud compute instance-groups list
gcloud sql instances list

# 6. 测试应用
curl http://$(terraform output load_balancer_ip)
# 应该返回Nginx欢迎页面