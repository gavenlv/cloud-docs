terraform init                    # 初始化
terraform plan                    # 预览变更
terraform apply                   # 应用变更
terraform apply -auto-approve     # 自动批准
terraform destroy                 # 销毁资源

terraform state list              # 列出资源
terraform state show aws_vpc.main # 显示资源详情
terraform state mv aws_vpc.main aws_vpc.primary  # 移动资源
terraform state rm aws_vpc.main   # 从状态中移除

terraform import aws_vpc.main vpc-12345678  # 导入资源
terraform taint aws_instance.example        # 标记重建
terraform untaint aws_instance.example      # 取消标记

terraform workspace list          # 列出工作空间
terraform workspace new dev       # 创建工作空间
terraform workspace select dev    # 切换工作空间