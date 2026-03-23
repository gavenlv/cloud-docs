# 问题1：状态锁定

# 查看状态锁定信息
terraform force-unlock <LOCK_ID>

# 问题2：状态不一致

# 刷新状态
terraform refresh

# 导入现有资源
terraform import <RESOURCE_ADDRESS> <IMPORT_ID>

# 问题3：依赖循环

# 查看依赖关系
terraform graph | dot -Tpng > dependency-graph.png

# 问题4：资源创建失败

# 查看详细日志
TF_LOG=DEBUG terraform apply

# 问题5：变量未定义

# 检查变量定义
terraform validate

# 查看变量使用
terraform plan -var-file="terraform.tfvars"