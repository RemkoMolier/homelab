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
    if !port.disabled && port.bond == null && port.bridge
  }

  unassigned_ports = {
    for name, port in var.ports : name => port
    if port.disabled || port.bond != null || !port.bridge
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

# The bootstrap .rsc pre-configures VLAN 1 on the bridge with filtering
# enabled, so Terraform can safely apply with vlan_filtering=true from
# the start without losing management connectivity.
resource "routeros_interface_bridge" "this" {
  name           = var.bridge_name
  vlan_filtering = true
  frame_types    = var.bridge_frame_types
}

# --- Ethernet port settings ---

resource "routeros_interface_ethernet" "ports" {
  for_each = var.ports

  name             = each.key
  factory_name     = each.key
  comment          = each.value.comment
  disabled         = each.value.disabled
  l2mtu            = coalesce(each.value.l2mtu, var.default_l2mtu)
  speed            = each.value.speed
  auto_negotiation = each.value.speed == null
}

# --- Bond interfaces ---

resource "terraform_data" "ensure_unassigned_bridge_ports" {
  triggers_replace = [
    jsonencode(sort(keys(local.unassigned_ports))),
    var.bridge_name,
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      KEY_FILE=$(mktemp)
      trap 'rm -f "$KEY_FILE"' EXIT
      printf '%s\n' "$SSH_PRIVATE_KEY" > "$KEY_FILE"
      chmod 600 "$KEY_FILE"
      ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i "$KEY_FILE" \
        "$SSH_USER@$SSH_HOST" \
        "$ROUTEROS_SCRIPT"
    EOT
    environment = {
      SSH_PRIVATE_KEY = nonsensitive(var.ssh_private_key_pem)
      SSH_USER        = nonsensitive(var.ssh_user)
      SSH_HOST        = nonsensitive(var.ssh_host)
      ROUTEROS_SCRIPT = join("; ", [
        ":local bridge \"${var.bridge_name}\"",
        ":local ifaces [:toarray \"${join(",", sort(keys(local.unassigned_ports)))}\"]",
        ":foreach iface in=$ifaces do={ :local ids [/interface/bridge/port/find where bridge=$bridge interface=$iface]; :if ([:len $ids] > 0) do={ /interface/bridge/port/remove $ids } }",
      ])
    }
  }

  depends_on = [
    routeros_interface_bridge_port.trunk,
    routeros_interface_bridge_port.access,
  ]
}

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

  depends_on = [
    terraform_data.ensure_unassigned_bridge_ports
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

  depends_on = [routeros_interface_bonding.bonds]
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

  depends_on = [
    routeros_interface_bridge_port.trunk,
    routeros_interface_bridge_port.access,
    routeros_interface_bridge_port.bonds,
  ]
}
