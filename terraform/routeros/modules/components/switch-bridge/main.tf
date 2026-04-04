# Switch bridge module — configures bridge VLAN filtering with port maps.
# Used by CRS309, CRS326, and hAP AX2 devices.

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
  # Collect all active (non-disabled, non-bond-member) ports for bridge membership
  bridge_ports = {
    for name, port in var.ports : name => port
    if !port.disabled && port.bond == null
  }

  # Build trunk ports: ports with tagged VLANs and no pvid
  trunk_ports = {
    for name, port in local.bridge_ports : name => port
    if length(port.vlans) > 0 && port.pvid == null
  }

  # Build access ports: ports with a pvid (untagged VLAN)
  access_ports = {
    for name, port in local.bridge_ports : name => port
    if port.pvid != null
  }

  # Build the VLAN table: for each VLAN, which ports are tagged
  vlan_tagged_ports = {
    for vlan_key, vlan in var.vlans : vlan_key => concat(
      [for name, port in local.trunk_ports : name if contains(port.vlans, vlan.id)],
      [for name, bond in var.bonds : name if contains(bond.vlans, vlan.id)],
    )
  }

  # For each VLAN, which ports are untagged
  vlan_untagged_ports = {
    for vlan_key, vlan in var.vlans : vlan_key => concat(
      [for name, port in local.access_ports : name if port.pvid == vlan.id],
      [for name, bond in var.bonds : name if bond.pvid == vlan.id],
    )
  }
}

# --- Bridge ---

resource "routeros_interface_bridge" "this" {
  name           = var.bridge_name
  vlan_filtering = true
  frame_types    = "admit-only-vlan-tagged"
}

# --- Ethernet port settings ---

resource "routeros_interface_ethernet" "ports" {
  for_each = var.ports

  name         = each.key
  factory_name = each.key
  comment      = each.value.comment
  disabled     = each.value.disabled
  l2mtu        = each.value.l2mtu
}

# --- Bond interfaces ---

resource "routeros_interface_bonding" "bonds" {
  for_each = var.bonds

  name    = each.key
  mode    = each.value.mode
  comment = each.value.comment
  mtu     = each.value.mtu
  slaves = [
    for name, port in var.ports : name
    if port.bond == each.key
  ]
}

# --- Bridge ports (non-bond, non-disabled) ---

resource "routeros_interface_bridge_port" "trunk" {
  for_each = local.trunk_ports

  bridge    = routeros_interface_bridge.this.name
  interface = each.key
  comment   = each.value.comment
}

resource "routeros_interface_bridge_port" "access" {
  for_each = local.access_ports

  bridge      = routeros_interface_bridge.this.name
  interface   = each.key
  comment     = each.value.comment
  pvid        = each.value.pvid
  frame_types = "admit-only-untagged-and-priority-tagged"
}

# --- Bridge ports for bonds ---

resource "routeros_interface_bridge_port" "bonds" {
  for_each = var.bonds

  bridge    = routeros_interface_bridge.this.name
  interface = each.key
  comment   = each.value.comment
}

# --- Management VLAN ---

resource "routeros_interface_vlan" "management" {
  comment   = "Management (VLAN 1)"
  interface = routeros_interface_bridge.this.name
  name      = "default"
  vlan_id   = 1
}

# --- Bridge VLAN table ---

resource "routeros_interface_bridge_vlan" "vlans" {
  for_each = var.vlans

  bridge   = routeros_interface_bridge.this.name
  comment  = each.value.comment
  vlan_ids = [each.value.id]

  tagged = concat(
    each.value.id == 1 ? [routeros_interface_bridge.this.name] : [],
    local.vlan_tagged_ports[each.key],
  )

  untagged = local.vlan_untagged_ports[each.key]
}
