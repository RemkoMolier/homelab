# VRRP — virtual router redundancy on each VLAN.
# Single router for now, prepared for future redundancy.

resource "routeros_interface_vrrp" "vlans" {
  for_each = var.vlans

  name      = "vrrp${each.value.id}"
  interface = local.vlan_interfaces[each.key]
  vrid      = each.value.id + var.vrrp_id_offset
  priority  = var.vrrp_priority
  comment   = "VRRP (VLAN ${each.value.id})"

  depends_on = [routeros_interface_vlan.vlans]
}
