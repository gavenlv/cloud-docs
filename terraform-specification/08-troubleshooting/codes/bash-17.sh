# 方案1：检查凭证
# 1. 检查环境变量
echo $GOOGLE_CREDENTIALS
echo $GOOGLE_APPLICATION_CREDENTIALS

# 2. 检查凭证文件
cat ~/service-account.json

# 3. 测试凭证
gcloud auth application-default print-access-token

# 方案2：重新初始化
terraform init -reconfigure

# 方案3：检查版本
# 1. 检查Terraform版本
terraform version

# 2. 检查Provider版本
terraform providers

# 3. 更新Provider
terraform init -upgrade

# 方案4：检查配置
# 1. 验证配置
terraform validate

# 2. 查看执行计划
terraform plan

# 3. 查看详细错误
TF_LOG=DEBUG terraform plan