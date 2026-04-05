# IP addresses — router address and VRRP virtual IP per VLAN.

resource "routeros_ip_address" "vlans" {
  for_each = var.vlans

  address   = each.value.router_address
  interface = local.vlan_interfaces[each.key]
  comment   = "${each.value.comment} IP (VLAN ${each.value.id})"

  depends_on = [routeros_interface_vlan.vlans]
}

resource "routeros_ip_address" "vrrp" {
  for_each = var.vlans

  address   = "${each.value.gateway}/32"
  interface = routeros_interface_vrrp.vlans[each.key].name
  comment   = "VRRP IP (VLAN ${each.value.id})"
}
