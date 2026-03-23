output "network_id" {
  description = "VPC网络ID"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "VPC网络名称"
  value       = google_compute_network.vpc.name
}

output "self_link" {
  description = "VPC网络自链接"
  value       = google_compute_network.vpc.self_link
}

output "gateway_ipv4" {
  description = "VPC网关IPv4地址"
  value       = google_compute_network.vpc.gateway_ipv4
}