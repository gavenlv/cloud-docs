# .gitignore配置

# Terraform文件
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfvars
!terraform.tfvars.example
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# 敏感文件
*.key
*.pem
*.p12
*.pfx
service-account.json
credentials.json

# 操作系统文件
.DS_Store
Thumbs.db