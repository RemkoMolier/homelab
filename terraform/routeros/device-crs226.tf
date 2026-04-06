provider "routeros" {
  alias    = "crs226"
  hosturl  = local.routeros_devices["crs226"].hosturl
  username = local.routeros_devices["crs226"].username
  password = local.routeros_devices["crs226"].password
  insecure = local.routeros_devices["crs226"].insecure
}

# CRS226-24G-2S+RM — 24-port GbE switch (.13)
# Uplink: sfp+1 → Horaco 10G (.20). sfpplus2 is empty.
# Legacy switch-chip VLANs. Hardware trunk managed via SSH.

# Import bootstrap-created resources into Terraform state.
# Kept as reference for bootstrapping replacement devices.
import {
  to = module.crs226.module.base.routeros_interface_vlan.management
  id = "name=mgmt"
}

import {
  to = module.crs226.module.base.routeros_interface_list.management
  id = "name=mgmt-list"
}

import {
  to = module.crs226.module.base.routeros_interface_list_member.management_default
  id = "interface=mgmt"
}

import {
  to = module.crs226.module.switch.routeros_interface_ethernet_switch_crs_vlan.vlans["management"]
  id = "vlan-id=1"
}

import {
  to = module.crs226.module.switch.routeros_interface_ethernet_switch_crs_egress_vlan_tag.vlans["management"]
  id = "vlan-id=1"
}

import {
  to = module.crs226.module.switch.routeros_interface_ethernet_switch_crs_ingress_vlan_translation.default
  id = "new-customer-vid=1"
}

import {
  to = module.crs226.module.base.routeros_system_user_group.terraform
  id = "name=terraform"
}

import {
  to = module.crs226.module.base.routeros_system_user.admin
  id = "name=admin"
}

module "crs226" {
  source = "./modules/devices/switch-chip"
  providers = {
    routeros = routeros.crs226
  }

  name                     = "crs226"
  default_l2mtu            = 9204
  ip                       = local.device_ips["crs226"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  terraform_user_name      = local.routeros_devices["crs226"].username
  vlans                    = local.vlans
  users                    = local.users

  ports = {
    "ether1"       = { comment = "Epyc IPMI (.31)", pvid = 1 }
    "ether2"       = { comment = "Disabled", disabled = true }
    "ether3"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether4"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether5"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether6"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether7"       = { comment = "Disabled", disabled = true }
    "ether8"       = { comment = "Disabled", disabled = true }
    "ether9"       = { comment = "Disabled", disabled = true }
    "ether10"      = { comment = "Trunk", vlans = local.all_vlan_ids }
    "ether11"      = { comment = "Disabled", disabled = true }
    "ether12"      = { comment = "Trunk", vlans = local.all_vlan_ids }
    "ether13"      = { comment = "Disabled", disabled = true }
    "ether14"      = { comment = "Disabled", disabled = true }
    "ether15"      = { comment = "Disabled", disabled = true }
    "ether16"      = { comment = "Disabled", disabled = true }
    "ether17"      = { comment = "Disabled", disabled = true }
    "ether18"      = { comment = "Disabled", disabled = true }
    "ether19"      = { comment = "Disabled", disabled = true }
    "ether20"      = { comment = "Disabled", disabled = true }
    "ether21"      = { comment = "Disabled", disabled = true }
    "ether22"      = { comment = "CCTV access", pvid = 50 }
    "ether23"      = { comment = "Disabled", disabled = true }
    "ether24"      = { comment = "Disabled", disabled = true }
    "sfp-sfpplus1" = { comment = "Trunk - Horaco 10G (.20)", vlans = local.all_vlan_ids }
    "sfpplus2"     = { comment = "Disabled", disabled = true }
  }

  trunks = {
    "trunk1" = {
      comment = "QNAP / TrueNAS backup"
      members = ["ether3", "ether4", "ether5", "ether6"]
      vlans   = local.all_vlan_ids
    }
  }

  depends_on = [module.crs226_bootstrap]
}

# Apply anchor for targeted single-device runs.
# Targeting this resource pulls in the full CRS226 dependency chain:
# bootstrap -> device module (incl. hardware trunks via SSH) -> switch enforcement.
resource "terraform_data" "crs226_apply" {
  input = "crs226"

  depends_on = [
    module.crs226_bootstrap,
    module.crs226,
  ]
}

module "crs226_bootstrap" {
  source = "./modules/components/bootstrap"
  devices = {
    crs226 = merge(nonsensitive(local.routeros_devices["crs226"]), {
      ip                   = local.device_ips["crs226"]
      bridge_protocol_mode = "none" # CRS2xx: switch-chip handles VLANs, not bridge
      vlan_mode            = "switch-chip"
    })
  }
}
