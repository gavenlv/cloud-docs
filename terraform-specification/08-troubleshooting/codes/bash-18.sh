# 1. 使用环境变量
# 设置凭证环境变量
export GOOGLE_CREDENTIALS=$(cat ~/service-account.json)

# 2. 使用Workload Identity
# 避免使用长期凭证
# 使用临时令牌

# 3. 版本约束
# 指定Provider版本
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# 4. 验证配置
# 在部署前验证
terraform validate
terraform plan