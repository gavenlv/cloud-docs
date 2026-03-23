# 简单输出
output "vpc_id" {
  description = "VPC网络ID"
  value       = google_compute_network.vpc.id
}

# 复杂输出
output "instance_info" {
  description = "实例详细信息"
  value = {
    for instance in google_compute_instance.web_server : instance.name => {
      id         = instance.id
      name       = instance.name
      machine_type = instance.machine_type
      zone       = instance.zone
      internal_ip = instance.network_interface[0].network_ip
      external_ip = try(instance.network_interface[0].access_config[0].nat_ip, null)
    }
  }
}

# 敏感输出
output "db_password" {
  description = "数据库密码"
  value       = random_password.db_password.result
  sensitive   = true
}

# 条件输出
output "load_balancer_ip" {
  description = "负载均衡器IP地址"
  value       = try(google_compute_global_forwarding_rule.web_forwarding_rule[0].ip_address, null)
}

# 输出依赖
output "instance_names" {
  description = "实例名称列表"
  value = [
    for instance in google_compute_instance.web_server : instance.name
  ]
  depends_on = [
    google_compute_instance.web_server
  ]
}