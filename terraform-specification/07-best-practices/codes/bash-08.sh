# 基础命令
terraform init              # 初始化
terraform validate          # 验证配置
terraform fmt               # 格式化代码
terraform plan              # 查看执行计划
terraform apply             # 应用配置
terraform destroy           # 销毁资源

# 状态管理
terraform state list        # 列出状态中的资源
terraform state show        # 显示资源详细信息
terraform state pull        # 拉取状态文件
terraform state push        # 推送状态文件
terraform state rm          # 从状态中移除资源
terraform state mv          # 移动资源

# 工作空间
terraform workspace list    # 列出工作空间
terraform workspace show    # 显示当前工作空间
terraform workspace new     # 创建新工作空间
terraform workspace select  # 切换工作空间
terraform workspace delete  # 删除工作空间

# 导入
terraform import           # 导入现有资源

# 输出
terraform output            # 显示输出值
terraform output -json      # 以JSON格式显示输出值

# 调试
TF_LOG=DEBUG terraform apply  # 启用调试日志
terraform graph            # 生成依赖关系图
terraform force-unlock     # 强制解锁状态

# 其他
terraform providers        # 显示Provider信息
terraform version          # 显示Terraform版本
terraform login            # 登录Terraform Cloud