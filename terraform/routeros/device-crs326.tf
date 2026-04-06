provider "routeros" {
  alias    = "crs326"
  hosturl  = local.routeros_devices["crs326"].hosturl
  username = local.routeros_devices["crs326"].username
  password = local.routeros_devices["crs326"].password
  insecure = local.routeros_devices["crs326"].insecure
}

# CRS326-24G-2S+RM — 24-port GbE switch (.12)

locals {
  crs326_ports = {
    "ether1"       = { comment = "Trunk", vlans = local.all_vlan_ids }
    "ether2"       = { comment = "Disabled", disabled = true }
    "ether3"       = { comment = "Trunk - hap-ax2-musicroom (${local.device_models["hap-ax2-musicroom"]})", vlans = local.all_vlan_ids }
    "ether4"       = { comment = "Disabled", disabled = true }
    "ether5"       = { comment = "Bond C2758", bond = "c2758" }
    "ether6"       = { comment = "Bond C2758", bond = "c2758" }
    "ether7"       = { comment = "Bond C2758", bond = "c2758" }
    "ether8"       = { comment = "Bond C2758", bond = "c2758" }
    "ether9"       = { comment = "Disabled", disabled = true }
    "ether10"      = { comment = "Disabled", disabled = true }
    "ether11"      = { comment = "Disabled", disabled = true }
    "ether12"      = { comment = "Disabled", disabled = true }
    "ether13"      = { comment = "Disabled", disabled = true }
    "ether14"      = { comment = "Disabled", disabled = true }
    "ether15"      = { comment = "Disabled", disabled = true }
    "ether16"      = { comment = "Disabled", disabled = true }
    "ether17"      = { comment = "Disabled", disabled = true }
    "ether18"      = { comment = "Disabled", disabled = true }
    "ether19"      = { comment = "Disabled", disabled = true }
    "ether20"      = { comment = "Disabled", disabled = true }
    "ether21"      = { comment = "Disabled", disabled = true }
    "ether22"      = { comment = "Disabled", disabled = true }
    "ether23"      = { comment = "Disabled", disabled = true }
    "ether24"      = { comment = "Disabled", disabled = true }
    "sfp-sfpplus1" = { comment = "Trunk", vlans = local.all_vlan_ids }
    "sfp-sfpplus2" = { comment = "Disabled", disabled = true }
  }

  crs326_trunk_ports = {
    for name, port in local.crs326_ports : name => port
    if !lookup(port, "disabled", false) && length(lookup(port, "vlans", [])) > 0 && lookup(port, "pvid", null) == null && lookup(port, "bond", null) == null
  }

  crs326_access_ports = {
    for name, port in local.crs326_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "pvid", null) != null && lookup(port, "bond", null) == null
  }

}

# Import bootstrap-created resources into Terraform state.
# Kept as reference for bootstrapping replacement devices.
import {
  to = module.crs326.module.base.routeros_interface_vlan.management
  id = "name=mgmt"
}

import {
  to = module.crs326.module.base.routeros_interface_list.management
  id = "name=mgmt-list"
}

import {
  to = module.crs326.module.base.routeros_interface_list_member.management_default
  id = "interface=mgmt"
}

import {
  to = module.crs326.module.switch.routeros_interface_bridge.this
  id = "name=bridge1"
}

import {
  for_each = local.crs326_trunk_ports
  to       = module.crs326.module.switch.routeros_interface_bridge_port.trunk[each.key]
  id       = "interface=${each.key}"
}

import {
  for_each = local.crs326_access_ports
  to       = module.crs326.module.switch.routeros_interface_bridge_port.access[each.key]
  id       = "interface=${each.key}"
}

import {
  to = module.crs326.module.switch.routeros_interface_bridge_vlan.vlans["management"]
  id = "*1"
}

import {
  to = module.crs326.module.base.routeros_system_user_group.terraform
  id = "name=terraform"
}

import {
  to = module.crs326.module.base.routeros_system_user.admin
  id = "name=admin"
}

module "crs326" {
  source = "./modules/devices/switch"
  providers = {
    routeros = routeros.crs326
  }

  name                     = "crs326"
  default_l2mtu            = 10218
  ip                       = local.device_ips["crs326"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  terraform_user_name      = local.routeros_devices["crs326"].username
  admin_password           = module.crs326_bootstrap.admin_passwords["crs326"]
  vlans                    = local.vlans
  users                    = local.users
  ports                    = local.crs326_ports

  bonds = {
    "c2758" = {
      comment = "LACP bond to C2758 server"
      vlans   = local.all_vlan_ids
    }
  }

  depends_on = [module.crs326_bootstrap]
}

resource "terraform_data" "crs326_apply" {
  input = "crs326"

  depends_on = [
    module.crs326_bootstrap,
    module.crs326,
  ]
}

module "crs326_bootstrap" {
  source = "./modules/components/bootstrap"
  devices = {
    crs326 = merge(nonsensitive(local.routeros_devices["crs326"]), {
      ip = local.device_ips["crs326"]
    })
  }
}
