provider "routeros" {
  alias    = "hap_ax2_musicroom"
  hosturl  = local.routeros_devices["hap-ax2-musicroom"].hosturl
  username = local.routeros_devices["hap-ax2-musicroom"].username
  password = local.routeros_devices["hap-ax2-musicroom"].password
  insecure = local.routeros_devices["hap-ax2-musicroom"].insecure
}

# hAP AX2 — Music Room (.15)
# CAPsMAN-managed WiFi AP. Trunk to CRS326 ether3.

locals {
  hap_ax2_musicroom_ports = {
    "ether1" = { comment = "Trunk - crs326 (${local.device_models["crs326"]})", vlans = local.all_vlan_ids }
    "ether2" = { comment = "Disabled", disabled = true }
    "ether3" = { comment = "Disabled", disabled = true }
    "ether4" = { comment = "Disabled", disabled = true }
    "ether5" = { comment = "Disabled", disabled = true }
  }

  hap_ax2_musicroom_trunk_ports = {
    for name, port in local.hap_ax2_musicroom_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "bridge", true) && lookup(port, "bond", null) == null && length(lookup(port, "vlans", [])) > 0 && lookup(port, "pvid", null) == null
  }

  hap_ax2_musicroom_access_ports = {
    for name, port in local.hap_ax2_musicroom_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "pvid", null) != null
  }
}

# Import bootstrap-created resources into Terraform state.
# Kept as reference for bootstrapping replacement devices.
import {
  to = module.hap_ax2_musicroom.module.base.routeros_interface_vlan.management
  id = "name=mgmt"
}

import {
  to = module.hap_ax2_musicroom.module.base.routeros_interface_list.management
  id = "name=mgmt-list"
}

import {
  to = module.hap_ax2_musicroom.module.base.routeros_interface_list_member.management_default
  id = "interface=mgmt"
}

import {
  to = module.hap_ax2_musicroom.module.switch.routeros_interface_bridge.this
  id = "name=bridge1"
}

import {
  for_each = local.hap_ax2_musicroom_trunk_ports
  to       = module.hap_ax2_musicroom.module.switch.routeros_interface_bridge_port.trunk[each.key]
  id       = "interface=${each.key}"
}

import {
  for_each = local.hap_ax2_musicroom_access_ports
  to       = module.hap_ax2_musicroom.module.switch.routeros_interface_bridge_port.access[each.key]
  id       = "interface=${each.key}"
}

import {
  to = module.hap_ax2_musicroom.module.switch.routeros_interface_bridge_vlan.vlans["management"]
  id = "*1"
}

import {
  to = module.hap_ax2_musicroom.module.base.routeros_system_user_group.terraform
  id = "name=terraform"
}

import {
  to = module.hap_ax2_musicroom.module.base.routeros_system_user.admin
  id = "name=admin"
}

import {
  to = module.hap_ax2_musicroom.module.capsman.routeros_wifi.wifi1
  id = "name=wifi1"
}

import {
  to = module.hap_ax2_musicroom.module.capsman.routeros_wifi.wifi2
  id = "name=wifi2"
}

module "hap_ax2_musicroom" {
  source = "./modules/devices/ap"
  providers = {
    routeros = routeros.hap_ax2_musicroom
  }

  name                     = "hap-ax2-musicroom"
  default_l2mtu            = 9124
  ip                       = local.device_ips["hap-ax2-musicroom"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  terraform_user_name      = local.routeros_devices["hap-ax2-musicroom"].username
  admin_password           = module.hap_ax2_musicroom_bootstrap.admin_passwords["hap-ax2-musicroom"]
  vlans                    = local.vlans
  users                    = local.users
  ports                    = local.hap_ax2_musicroom_ports

  depends_on = [module.hap_ax2_musicroom_bootstrap]
}

resource "terraform_data" "hap_ax2_musicroom_apply" {
  input = "hap-ax2-musicroom"

  depends_on = [
    module.hap_ax2_musicroom_bootstrap,
    module.hap_ax2_musicroom,
  ]
}

module "hap_ax2_musicroom_bootstrap" {
  source = "./modules/components/bootstrap"
  devices = {
    "hap-ax2-musicroom" = merge(nonsensitive(local.routeros_devices["hap-ax2-musicroom"]), {
      ip = local.device_ips["hap-ax2-musicroom"]
    })
  }
}
