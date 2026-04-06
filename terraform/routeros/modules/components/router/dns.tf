# DNS server — recursive resolver with static records.

# Upstream servers are learned from the WAN DHCP client — do not set
# `servers` here or it will override the dynamic entries.
resource "routeros_ip_dns" "this" {
  allow_remote_requests = true
}

resource "routeros_ip_dns_record" "static" {
  for_each = var.dns_static_records

  name    = each.key
  address = each.value.address
  type    = each.value.type
  comment = "Managed by Terraform"
}
