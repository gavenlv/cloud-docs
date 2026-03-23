variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "zone" {
  description = "可用区"
  type        = string
  default     = "us-central1-a"
}

variable "name" {
  description = "实例名称"
  type        = string
}

variable "machine_type" {
  description = "机器类型"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "启动镜像"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "network" {
  description = "网络ID或自链接"
  type        = string
}

variable "subnetwork" {
  description = "子网ID或自链接"
  type        = string
  default     = null
}

variable "tags" {
  description = "实例标签"
  type        = list(string)
  default     = []
}

variable "metadata" {
  description = "实例元数据"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

variable "boot_disk_type" {
  description = "启动磁盘类型"
  type        = string
  default     = "pd-balanced"
}

variable "boot_disk_size" {
  description = "启动磁盘大小（GB）"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_disk_size >= 10 && var.boot_disk_size <= 65536
    error_message = "boot_disk_size must be between 10 and 65536 GB."
  }
}

variable "service_account" {
  description = "服务账号邮箱"
  type        = string
  default     = null
}

variable "scopes" {
  description = "API访问范围"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "enable_shielded_vm" {
  description = "启用安全虚拟机"
  type        = bool
  default     = false
}

variable "confidential_compute" {
  description = "启用机密计算"
  type        = bool
  default     = false
}