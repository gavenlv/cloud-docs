# variables.tf
variable "firewall_rules" {
  description = "防火墙规则列表"
  type = list(object({
    name          = string
    description   = string
    source_ranges = list(string)
    ports         = list(string)
    protocol      = string
  }))
  default = [
    {
      name          = "allow-ssh"
      description   = "Allow SSH access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["22"]
      protocol      = "tcp"
    },
    {
      name          = "allow-http"
      description   = "Allow HTTP access"
      source_ranges = ["0.0.0.0/0"]
      ports         = ["80", "443"]
      protocol      = "tcp"
    },
    {
      name          = "allow-internal"
      description   = "Allow internal traffic"
      source_ranges = ["10.0.0.0/8"]
      ports         = ["0-65535"]
      protocol      = "tcp"
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

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

output "firewall_rules" {
  value = {
    for name, rule in google_compute_firewall.firewall_rules : name => rule.name
  }
}