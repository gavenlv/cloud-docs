# 1. 登录Terraform Cloud
terraform login

# 2. 初始化
terraform init

# 3. 推送到GitHub
git add .
git commit -m "Add Terraform Cloud configuration"
git push origin main

# 4. Terraform Cloud自动运行计划
# 查看Terraform Cloud控制台

# 5. 批准计划
# 在Terraform Cloud控制台中点击"Apply"

# 6. 查看运行结果
# 在Terraform Cloud控制台中查看运行日志