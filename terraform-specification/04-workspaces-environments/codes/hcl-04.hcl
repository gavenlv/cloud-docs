variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "环境名称"
  type        = string
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}