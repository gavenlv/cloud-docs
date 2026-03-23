# 文件命名规范

# 主要配置文件
main.tf              # 主要资源定义
variables.tf         # 变量定义
outputs.tf          # 输出定义
versions.tf         # 版本约束
backend.tf          # 后端配置
provider.tf         # Provider配置

# 环境特定文件
terraform-dev.tfvars      # 开发环境变量
terraform-staging.tfvars  # 预发布环境变量
terraform-prod.tfvars     # 生产环境变量

# 模块文件
modules/vpc/main.tf       # VPC模块
modules/compute/main.tf   # 计算模块
modules/storage/main.tf   # 存储模块

# 命名原则：
├── 使用小写字母
├── 使用下划线分隔
├── 使用描述性名称
├── 避免使用空格
└── 避免使用特殊字符