variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "network_name" {
  description = "VPC网络名称"
  type        = string
  default     = "default-network"
}

variable "auto_create_subnetworks" {
  description = "是否自动创建子网"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "路由模式：REGIONAL或GLOBAL"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be either REGIONAL or GLOBAL."
  }
}

variable "mtu" {
  description = "最大传输单元"
  type        = number
  default     = 1460

  validation {
    condition     = var.mtu >= 1300 && var.mtu <= 1460
    error_message = "mtu must be between 1300 and 1460."
  }
}

variable "delete_default_routes_on_create" {
  description = "创建时是否删除默认路由"
  type        = bool
  default     = false
}

variable "description" {
  description = "VPC网络描述"
  type        = string
  default     = "Managed by Terraform"
}

variable "labels" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}