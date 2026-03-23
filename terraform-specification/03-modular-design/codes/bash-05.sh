# 初始化
terraform init

# 验证配置
terraform validate

# 查看执行计划
terraform plan

# 应用配置
terraform apply -auto-approve

# 查看输出
terraform output vpc_id
terraform output web_server_ip
terraform output db_server_ip

# 验证资源
terraform state list

# 查看依赖关系
terraform graph | dot -Tpng > dependency-graph.png

# 销毁资源
terraform destroy -auto-approve