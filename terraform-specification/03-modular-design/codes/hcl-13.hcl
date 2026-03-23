output "vpc_id" {
  description = "VPC网络ID"
  value       = module.vpc.network_id
}

output "web_server_ip" {
  description = "Web服务器IP地址"
  value       = module.web_server.external_ip
}

output "db_server_ip" {
  description = "数据库服务器IP地址"
  value       = module.db_server.internal_ip
}