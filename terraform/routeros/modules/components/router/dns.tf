# DNS server — recursive resolver with static records.

resource "routeros_ip_dns" "this" {
  allow_remote_requests = true
  servers               = var.dns_servers
}

resource "routeros_ip_dns_record" "static" {
  for_each = var.dns_static_records

  name    = each.key
  address = each.value.address
  type    = each.value.type
  comment = "Managed by Terraform"
}
