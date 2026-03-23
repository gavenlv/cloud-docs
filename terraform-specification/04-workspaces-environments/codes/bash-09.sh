# 设置环境变量
export TF_VAR_project_id="dev-project-id"
export TF_VAR_region="us-central1"
export TF_VAR_instance_count=1

# 使用环境变量
terraform apply

# 配置文件
variable "project_id" {
  type = string
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "instance_count" {
  type = number
  default = 1
}