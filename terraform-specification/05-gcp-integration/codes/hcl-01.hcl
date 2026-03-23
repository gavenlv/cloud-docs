# 指定Provider版本
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# 版本约束说明：
# ~> 4.0  : 允许4.x版本，但不包括5.0
# >= 4.0  : 允许4.0及以上版本
# = 4.0   : 只允许4.0版本
# 4.0     : 等同于= 4.0

# 使用最新版本（不推荐生产环境）
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "latest"
    }
  }
}