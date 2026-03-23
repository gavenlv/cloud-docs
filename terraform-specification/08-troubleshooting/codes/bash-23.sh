# 启用调试日志
export TF_LOG=DEBUG

# 指定日志文件
export TF_LOG_PATH=terraform.log

# 运行Terraform
terraform apply

# 查看日志
cat terraform.log

# 日志级别：
# TRACE：最详细的日志
# DEBUG：调试信息
# INFO：一般信息
# WARN：警告信息
# ERROR：错误信息