provider "routeros" {
  alias    = "crs309"
  hosturl  = local.routeros_devices["crs309"].hosturl
  username = local.routeros_devices["crs309"].username
  password = local.routeros_devices["crs309"].password
  insecure = local.routeros_devices["crs309"].insecure
}

# CRS309-1G-8S+IN — 10G core switch (.11)

locals {
  crs309_ports = {
    "ether1"       = { comment = "Trunk (unused)", vlans = local.all_vlan_ids }
    "sfp-sfpplus1" = { comment = "Trunk - rb5009 (${local.device_models["rb5009"]})", vlans = local.all_vlan_ids }
    "sfp-sfpplus2" = { comment = "Trunk - crs326 (${local.device_models["crs326"]})", vlans = local.all_vlan_ids }
    "sfp-sfpplus3" = { comment = "Trunk - hap-ax2-kitchen (${local.device_models["hap-ax2-kitchen"]})", vlans = local.all_vlan_ids, speed = "2.5G-baseX" }
    "sfp-sfpplus4" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus5" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus6" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus7" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus8" = { comment = "Trunk - Horaco 10G (.20)", vlans = local.all_vlan_ids }
  }

  crs309_trunk_ports = {
    for name, port in local.crs309_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "bridge", true) && lookup(port, "bond", null) == null && length(lookup(port, "vlans", [])) > 0 && lookup(port, "pvid", null) == null
  }

  crs309_access_ports = {
    for name, port in local.crs309_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "bridge", true) && lookup(port, "bond", null) == null && lookup(port, "pvid", null) != null
  }
}

# Import bootstrap-created resources into Terraform state.
# Kept as reference for bootstrapping replacement devices.
import {
  to = module.crs309.module.base.routeros_interface_vlan.management
  id = "name=mgmt"
}

import {
  to = module.crs309.module.base.routeros_interface_list.management
  id = "name=mgmt-list"
}

import {
  to = module.crs309.module.base.routeros_interface_list_member.management_default
  id = "interface=mgmt"
}

import {
  to = module.crs309.module.switch.routeros_interface_bridge.this
  id = "name=bridge1"
}

import {
  for_each = local.crs309_trunk_ports
  to       = module.crs309.module.switch.routeros_interface_bridge_port.trunk[each.key]
  id       = "interface=${each.key}"
}

import {
  for_each = local.crs309_access_ports
  to       = module.crs309.module.switch.routeros_interface_bridge_port.access[each.key]
  id       = "interface=${each.key}"
}

import {
  to = module.crs309.module.switch.routeros_interface_bridge_vlan.vlans["management"]
  id = "*1"
}

import {
  to = module.crs309.module.base.routeros_system_user_group.terraform
  id = "name=terraform"
}

import {
  to = module.crs309.module.base.routeros_system_user.admin
  id = "name=admin"
}

module "crs309" {
  source = "./modules/devices/switch"
  providers = {
    routeros = routeros.crs309
  }

  name                     = "crs309"
  default_l2mtu            = 10218
  ip                       = local.device_ips["crs309"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  terraform_user_name      = local.routeros_devices["crs309"].username
  admin_password           = module.crs309_bootstrap.admin_passwords["crs309"]
  vlans                    = local.vlans
  users                    = local.users
  ports                    = local.crs309_ports

  depends_on = [module.crs309_bootstrap]
}

resource "terraform_data" "crs309_apply" {
  input = "crs309"

  depends_on = [
    module.crs309_bootstrap,
    module.crs309,
  ]
}

module "crs309_bootstrap" {
  source = "./modules/components/bootstrap"
  devices = {
    crs309 = merge(nonsensitive(local.routeros_devices["crs309"]), {
      ip = local.device_ips["crs309"]
    })
  }
}
