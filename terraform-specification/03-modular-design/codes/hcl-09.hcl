output "instance_id" {
  description = "实例ID"
  value       = google_compute_instance.instance.id
}

output "instance_name" {
  description = "实例名称"
  value       = google_compute_instance.instance.name
}

output "self_link" {
  description = "实例自链接"
  value       = google_compute_instance.instance.self_link
}

output "internal_ip" {
  description = "内网IP地址"
  value       = google_compute_instance.instance.network_interface[0].network_ip
}

output "external_ip" {
  description = "外网IP地址"
  value       = try(
    google_compute_instance.instance.network_interface[0].access_config[0].nat_ip,
    null
  )
}