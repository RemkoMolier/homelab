# Router module — RB5009-specific configuration.
# Composes: VLAN interfaces, firewall, DNS, DHCP, VRRP, CAPsMAN, PXE.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
  }
}

locals {
  # Non-management VLANs need their own /interface/vlan on the bridge.
  # Management uses the "mgmt" interface created by device-base.
  non_mgmt_vlans = { for k, v in var.vlans : k => v if k != "management" }

  # Map VLAN keys to their actual interface names.
  vlan_interfaces = merge(
    { management = var.management_interface },
    { for k, v in local.non_mgmt_vlans : k => v.name },
  )
}

# --- VLAN interfaces on the bridge ---
# Management (VLAN 1) is created by device-base as "mgmt".
# All other VLANs get their own interface here.

resource "routeros_interface_vlan" "vlans" {
  for_each = local.non_mgmt_vlans

  name      = each.value.name
  vlan_id   = each.value.id
  interface = var.bridge_name
  comment   = each.value.comment

  # Wait for interface lists to be renamed (e.g., "home" → "home-list")
  # to avoid name collisions in the RouterOS namespace.
  depends_on = [routeros_interface_list.zones]
}
