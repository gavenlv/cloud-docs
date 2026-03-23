# variables.tf
variable "firewall_rules" {
  description = "防火墙规则配置"
  type = list(object({
    name          = string
    description   = string
    source_ranges = list(string)
    ports         = list(string)
    protocol      = string
    target_tags   = list(string)
  }))
  default = [
    {
      name          = "allow-ssh"
      description   = "Allow SSH access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["22"]
      protocol      = "tcp"
      target_tags   = ["ssh-server"]
    },
    {
      name          = "allow-http"
      description   = "Allow HTTP access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["80", "443"]
      protocol      = "tcp"
      target_tags   = ["http-server"]
    },
    {
      name          = "allow-https"
      description   = "Allow HTTPS access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["443"]
      protocol      = "tcp"
      target_tags   = ["https-server"]
    }
  ]
}

# main.tf
resource "google_compute_firewall" "firewall_rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name    = each.value.name
  network = "default"

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }

  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

output "firewall_rule_names" {
  value = [
    for rule in google_compute_firewall.firewall_rules : rule.name
  ]
}