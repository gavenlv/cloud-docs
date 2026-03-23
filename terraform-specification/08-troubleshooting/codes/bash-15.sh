# 方案1：定义变量
# 在variables.tf中定义
variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

# 方案2：提供变量值
# 方法1：命令行
terraform apply -var="project_id=my-project-id"

# 方法2：变量文件
terraform apply -var-file="terraform.tfvars"

# 方法3：环境变量
export TF_VAR_project_id="my-project-id"
terraform apply

# 方法4：自动加载
# 创建terraform.tfvars文件
project_id = "my-project-id"
region = "us-central1"

# 方案3：设置默认值
variable "project_id" {
  description = "GCP项目ID"
  type        = string
  default     = "my-project-id"
}

# 方案4：使用交互式输入
terraform apply
# Terraform会提示输入变量值