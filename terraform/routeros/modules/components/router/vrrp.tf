# VRRP — virtual router redundancy on each VLAN.
# Single router for now, prepared for future redundancy.

resource "routeros_interface_vrrp" "vlans" {
  for_each = var.vlans

  name      = "vrrp${each.value.id}"
  interface = local.vlan_interfaces[each.key]
  vrid      = each.value.id + var.vrrp_id_offset
  priority  = var.vrrp_priority
  comment   = "VRRP (VLAN ${each.value.id})"

  lifecycle {
    precondition {
      condition     = each.value.id + var.vrrp_id_offset >= 1 && each.value.id + var.vrrp_id_offset <= 255
      error_message = "VRID for VLAN ${each.value.id} is ${each.value.id + var.vrrp_id_offset}, which is outside the valid range 1–255."
    }
  }

  depends_on = [routeros_interface_vlan.vlans]
}
