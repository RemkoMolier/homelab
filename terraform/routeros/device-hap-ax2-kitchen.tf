provider "routeros" {
  alias    = "hap_ax2_kitchen"
  hosturl  = local.routeros_devices["hap-ax2-kitchen"].hosturl
  username = local.routeros_devices["hap-ax2-kitchen"].username
  password = local.routeros_devices["hap-ax2-kitchen"].password
  insecure = local.routeros_devices["hap-ax2-kitchen"].insecure
}

# hAP AX2 — Kitchen (.16)
# CAPsMAN-managed WiFi AP. Trunk to CRS309 sfp+3 (2.5G).
# Extra ethernet ports as Home VLAN access ports.

locals {
  hap_ax2_kitchen_ports = {
    "ether1" = { comment = "Trunk - crs309 (${local.device_models["crs309"]})", vlans = local.all_vlan_ids }
    "ether2" = { comment = "Home access port", pvid = 10 }
    "ether3" = { comment = "Home access port", pvid = 10 }
    "ether4" = { comment = "Home access port", pvid = 10 }
    "ether5" = { comment = "Home access port", pvid = 10 }
  }

  hap_ax2_kitchen_trunk_ports = {
    for name, port in local.hap_ax2_kitchen_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "bridge", true) && lookup(port, "bond", null) == null && length(lookup(port, "vlans", [])) > 0 && lookup(port, "pvid", null) == null
  }

  hap_ax2_kitchen_access_ports = {
    for name, port in local.hap_ax2_kitchen_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "pvid", null) != null
  }
}

# Import bootstrap-created resources into Terraform state.
# Kept as reference for bootstrapping replacement devices.
import {
  to = module.hap_ax2_kitchen.module.base.routeros_interface_vlan.management
  id = "name=mgmt"
}

import {
  to = module.hap_ax2_kitchen.module.base.routeros_interface_list.management
  id = "name=mgmt-list"
}

import {
  to = module.hap_ax2_kitchen.module.base.routeros_interface_list_member.management_default
  id = "interface=mgmt"
}

import {
  to = module.hap_ax2_kitchen.module.switch.routeros_interface_bridge.this
  id = "name=bridge1"
}

import {
  for_each = local.hap_ax2_kitchen_trunk_ports
  to       = module.hap_ax2_kitchen.module.switch.routeros_interface_bridge_port.trunk[each.key]
  id       = "interface=${each.key}"
}

import {
  for_each = local.hap_ax2_kitchen_access_ports
  to       = module.hap_ax2_kitchen.module.switch.routeros_interface_bridge_port.access[each.key]
  id       = "interface=${each.key}"
}

import {
  to = module.hap_ax2_kitchen.module.switch.routeros_interface_bridge_vlan.vlans["management"]
  id = "*1"
}

import {
  to = module.hap_ax2_kitchen.module.base.routeros_system_user_group.terraform
  id = "name=terraform"
}

import {
  to = module.hap_ax2_kitchen.module.base.routeros_system_user.admin
  id = "name=admin"
}

import {
  to = module.hap_ax2_kitchen.module.capsman.routeros_wifi.wifi1
  id = "name=wifi1"
}

import {
  to = module.hap_ax2_kitchen.module.capsman.routeros_wifi.wifi2
  id = "name=wifi2"
}

module "hap_ax2_kitchen" {
  source = "./modules/devices/ap"
  providers = {
    routeros = routeros.hap_ax2_kitchen
  }

  name                     = "hap-ax2-kitchen"
  default_l2mtu            = 9124
  ip                       = local.device_ips["hap-ax2-kitchen"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  terraform_user_name      = local.routeros_devices["hap-ax2-kitchen"].username
  admin_password           = module.hap_ax2_kitchen_bootstrap.admin_passwords["hap-ax2-kitchen"]
  vlans                    = local.vlans
  users                    = local.users
  ports                    = local.hap_ax2_kitchen_ports

  depends_on = [module.hap_ax2_kitchen_bootstrap]
}

resource "terraform_data" "hap_ax2_kitchen_apply" {
  input = "hap-ax2-kitchen"

  depends_on = [
    module.hap_ax2_kitchen_bootstrap,
    module.hap_ax2_kitchen,
  ]
}

module "hap_ax2_kitchen_bootstrap" {
  source = "./modules/components/bootstrap"
  devices = {
    "hap-ax2-kitchen" = merge(nonsensitive(local.routeros_devices["hap-ax2-kitchen"]), {
      ip = local.device_ips["hap-ax2-kitchen"]
    })
  }
}
