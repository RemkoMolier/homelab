# VRRP — virtual router redundancy on each VLAN.
# Single router for now, prepared for future redundancy.

resource "routeros_interface_vrrp" "vlans" {
  for_each = var.vlans

  name      = "vrrp${each.value.id}"
  interface = each.value.name
  vrid      = each.value.id
  comment   = "VRRP (VLAN ${each.value.id})"
}
