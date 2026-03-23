# 1. 定义所有变量
# 在variables.tf中定义所有变量
variable "project_id" {
  description = "GCP项目ID"
  type        = string
  default     = "my-project-id"
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

# 2. 提供示例变量文件
# 创建terraform.tfvars.example
project_id = "my-project-id"
region = "us-central1"

# 3. 使用环境变量
# 在CI/CD中使用
export TF_VAR_project_id="my-project-id"
export TF_VAR_region="us-central1"

# 4. 验证变量
# 检查变量定义
terraform validate

# 查看变量
terraform output -json | jq '.values'