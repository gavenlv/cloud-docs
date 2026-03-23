# 方案1：使用格式化工具
# 自动修复格式错误
terraform fmt

# 检查格式
terraform fmt -check

# 方案2：验证配置
# 验证语法
terraform validate

# 方案3：查看详细错误
# 启用调试日志
TF_LOG=DEBUG terraform validate

# 方案4：检查版本
# 检查Terraform版本
terraform version

# 检查Provider版本
terraform providers