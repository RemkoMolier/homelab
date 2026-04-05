# Switch chip module — configures legacy switch-chip VLANs for CRS1xx/2xx devices.
# Uses the CRS-specific resources in the routeros provider.
#
# On CRS1xx/2xx (QCA-8519), bridge VLAN filtering is NOT hardware-offloaded.
# VLANs must be configured via the switch-chip resources for wire-speed.
# The bridge (protocol-mode=none) provides CPU access; the switch chip
# handles all VLAN switching in hardware.
#
# VLAN 1 is the native/management VLAN:
#   - Tagged on egress only to switch1-cpu (so the CPU's VLAN interface can
#     decapsulate it)
#   - Untagged (native) on all trunk ports — no egress tag, ingress
#     translation maps untagged → VLAN 1
#
# Note: There is no Terraform resource for /interface/ethernet/switch/trunk
# or /interface/ethernet/switch/set. Hardware trunks are managed via SSH
# local-exec provisioners below.

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

  # Collect trunk member ports (part of a hardware trunk group)
  trunk_member_ports = {
    for name, port in var.ports : name => port
    if !port.disabled && port.trunk != null
  }

  # All VLAN-aware ports (for drop-if-invalid enforcement).
  # Includes physical trunk ports, access ports, trunk members, and switch1-cpu.
  vlan_aware_ports = toset(concat(
    [for name, _ in local.trunk_ports : name],
    [for name, _ in local.access_ports : name],
    [for name, _ in local.trunk_member_ports : name],
    ["switch1-cpu"],
  ))

  # All ports that participate in the default ingress translation (untagged → VLAN 1).
  # This is a single combined rule matching the CRS2xx convention:
  # trunk ports + trunk members + access ports with pvid=1 + hardware trunks.
  default_ingress_ports = toset(concat(
    [for name, _ in local.trunk_ports : name],
    [for name, _ in local.trunk_member_ports : name],
    [for name, trunk in var.trunks : name],
    [for name, port in local.access_ports : name if port.pvid == 1],
  ))

  desired_vlan_ports = {
    for vlan_key, vlan in var.vlans : vlan_key => join(",", sort(concat(
      [for name, port in local.trunk_ports : name if contains(port.vlans, vlan.id)],
      [for name, trunk in var.trunks : name if contains(trunk.vlans, vlan.id)],
      vlan.id == 1 ? ["switch1-cpu"] : [],
      [for name, port in local.access_ports : name if port.pvid == vlan.id],
    )))
  }
}

# --- Ethernet interface settings ---

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

# --- Hardware trunk groups (via SSH) ---
# CRS1xx/2xx hardware trunks have no native Terraform resource.
# Manage them idempotently via SSH: find-or-create, then set attributes.

resource "terraform_data" "trunk" {
  for_each = var.trunks

  triggers_replace = [
    each.key,
    join(",", sort(each.value.members)),
    each.value.comment,
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
        ":local trunkName \"${each.key}\"",
        ":local memberPorts \"${join(",", sort(each.value.members))}\"",
        ":local trunkComment \"${each.value.comment}\"",
        ":local existing [/interface/ethernet/switch/trunk find where name=$trunkName]",
        ":if ([:len $existing] > 0) do={ /interface/ethernet/switch/trunk set $existing member-ports=$memberPorts comment=$trunkComment } else={ /interface/ethernet/switch/trunk add name=$trunkName member-ports=$memberPorts comment=$trunkComment }",
      ])
    }
  }

  depends_on = [routeros_interface_ethernet.ports]
}

# --- Switch VLAN table ---

resource "terraform_data" "vlan_replacement" {
  for_each = var.vlans

  # RouterOS stores VLAN member ports in its own order, so the VLAN table
  # resource ignores direct drift on `ports`. Use a terraform_data
  # replacement trigger keyed by the normalized desired port set so actual
  # membership changes still recreate the VLAN rows deterministically.
  triggers_replace = {
    desired_ports = local.desired_vlan_ports[each.key]
  }
}

resource "routeros_interface_ethernet_switch_crs_vlan" "vlans" {
  for_each = var.vlans

  comment = each.value.comment
  vlan_id = each.value.id
  ports   = local.desired_vlan_ports[each.key]

  # RouterOS returns ports in its own order, causing perpetual drift.
  # Ignore direct changes to `ports`, but replace the resource when the
  # normalized desired membership set changes.
  lifecycle {
    ignore_changes       = [ports]
    replace_triggered_by = [terraform_data.vlan_replacement[each.key]]
  }

  depends_on = [
    routeros_interface_ethernet.ports,
    terraform_data.trunk,
  ]
}

# --- Egress VLAN tagging ---
# VLAN 1 (native/management) is tagged ONLY on switch1-cpu so the CPU's
# VLAN interface can process it. On all other ports VLAN 1 leaves untagged.
# All other VLANs are tagged on their respective trunk ports.

resource "routeros_interface_ethernet_switch_crs_egress_vlan_tag" "vlans" {
  for_each = var.vlans

  comment = each.value.comment
  vlan_id = each.value.id
  tagged_ports = toset(
    each.value.id == 1
    ? ["switch1-cpu"]
    : concat(
      [for name, port in local.trunk_ports : name if contains(port.vlans, each.value.id)],
      [for name, trunk in var.trunks : name if contains(trunk.vlans, each.value.id)],
    )
  )

  depends_on = [
    routeros_interface_ethernet.ports,
    terraform_data.trunk,
  ]
}

# --- Ingress VLAN translation ---
# A single rule maps untagged frames on all VLAN-aware ports to VLAN 1
# (the native/default VLAN). This matches the CRS2xx convention where one
# combined ingress rule covers trunk ports, trunk members, and hardware trunks.
# Separate rules handle access ports with non-default PVIDs.

resource "routeros_interface_ethernet_switch_crs_ingress_vlan_translation" "default" {
  ports            = local.default_ingress_ports
  customer_vid     = 0
  new_customer_vid = 1
  pcp_propagation  = "no"
  sa_learning      = "yes"

  lifecycle {
    ignore_changes = [pcp_propagation, sa_learning]
  }

  depends_on = [
    routeros_interface_ethernet_switch_crs_vlan.vlans,
    routeros_interface_ethernet_switch_crs_egress_vlan_tag.vlans,
  ]
}

resource "routeros_interface_ethernet_switch_crs_ingress_vlan_translation" "access" {
  for_each = { for name, port in local.access_ports : name => port if port.pvid != 1 }

  ports            = toset([each.key])
  customer_vid     = 0
  new_customer_vid = each.value.pvid
  pcp_propagation  = "no"
  sa_learning      = "yes"

  lifecycle {
    ignore_changes = [pcp_propagation, sa_learning]
  }

  depends_on = [
    routeros_interface_ethernet_switch_crs_vlan.vlans,
    routeros_interface_ethernet_switch_crs_egress_vlan_tag.vlans,
  ]
}
