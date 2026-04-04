# Switch chip module — configures legacy switch-chip VLANs for CRS1xx/2xx devices.
# Uses the CRS-specific resources in the routeros provider.
#
# Note: There is no Terraform resource for /interface/ethernet/switch/trunk.
# Hardware trunk groups (bonding) must be configured manually or via a
# generic routeros_rest resource if available.

terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

locals {
  # Collect trunk ports (tagged VLANs)
  trunk_ports = {
    for name, port in var.ports : name => port
    if !port.disabled && length(port.vlans) > 0 && port.pvid == null
  }

  # Collect access ports (untagged VLAN via pvid)
  access_ports = {
    for name, port in var.ports : name => port
    if !port.disabled && port.pvid != null
  }

  # All active port names for VLAN membership (trunks + trunk group members)
  all_trunk_port_names = concat(
    [for name, port in local.trunk_ports : name],
    [for name, trunk in var.trunks : name],
  )
}

# --- Switch VLAN table ---

resource "routeros_interface_ethernet_switch_crs_vlan" "vlans" {
  for_each = var.vlans

  comment = each.value.comment
  vlan_id = each.value.id
  ports = join(",", concat(
    [for name, port in local.trunk_ports : name if contains(port.vlans, each.value.id)],
    [for name, trunk in var.trunks : name if contains(trunk.vlans, each.value.id)],
    each.value.id == 1 ? ["switch1-cpu"] : [],
    [for name, port in local.access_ports : name if port.pvid == each.value.id],
  ))
}

# --- Egress VLAN tagging ---

resource "routeros_interface_ethernet_switch_crs_egress_vlan_tag" "vlans" {
  for_each = var.vlans

  comment = each.value.comment
  vlan_id = each.value.id
  tagged_ports = join(",", concat(
    each.value.id == 1 ? ["switch1-cpu"] : [],
    [for name, port in local.trunk_ports : name if contains(port.vlans, each.value.id)],
    [for name, trunk in var.trunks : name if contains(trunk.vlans, each.value.id)],
  ))
}

# --- Ingress VLAN translation (untagged → VLAN) ---

resource "routeros_interface_ethernet_switch_crs_ingress_vlan_translation" "access" {
  for_each = local.access_ports

  ports            = each.key
  customer_vid     = 0
  new_customer_vid = each.value.pvid
}

# Default ingress translation for trunk ports (untagged → VLAN 1)
resource "routeros_interface_ethernet_switch_crs_ingress_vlan_translation" "trunk_default" {
  ports            = join(",", [for name, port in local.trunk_ports : name])
  customer_vid     = 0
  new_customer_vid = 1
}
