variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "VPC网络名称"
  type        = string
  default     = "production-network"
}

variable "routing_mode" {
  description = "路由模式"
  type        = string
  default     = "REGIONAL"
}

variable "public_subnet_cidr" {
  description = "公共子网CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "私有子网CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_source_ranges" {
  description = "SSH访问源IP范围"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}