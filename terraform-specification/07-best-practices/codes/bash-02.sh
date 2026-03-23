# 格式化Terraform代码
terraform fmt

# 检查格式是否正确
terraform fmt -check

# 递归格式化所有子目录
terraform fmt -recursive

# 在CI/CD中使用
terraform fmt -check
if [ $? -ne 0 ]; then
  echo "Terraform code is not formatted"
  exit 1
fi