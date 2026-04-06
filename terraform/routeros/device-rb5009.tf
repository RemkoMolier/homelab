provider "routeros" {
  alias    = "rb5009"
  hosturl  = local.routeros_devices["rb5009"].hosturl
  username = local.routeros_devices["rb5009"].username
  password = local.routeros_devices["rb5009"].password
  insecure = local.routeros_devices["rb5009"].insecure
}

# RB5009UG+S+IN — Main router (.10, VRRP .1)
#
# Ports:
#   ether1     — WAN (DHCP)
#   ether2     — C2758 IPMI (.30), trunk
#   ether3-5   — Disabled
#   ether6     — VoIP (untagged VLAN 40)
#   ether7     — CCTV (untagged VLAN 50)
#   ether8     — CCTV (untagged VLAN 50)
#   sfp+1      — Trunk to CRS309

# Import bootstrap-created resources into Terraform state.
# Kept as reference for bootstrapping replacement devices.

# device-base imports
import {
  to = module.rb5009.module.base.routeros_interface_vlan.management
  id = "name=mgmt"
}

import {
  to = module.rb5009.module.base.routeros_interface_list.management
  id = "name=mgmt-list"
}

import {
  to = module.rb5009.module.base.routeros_interface_list_member.management_default
  id = "interface=mgmt"
}

import {
  to = module.rb5009.module.base.routeros_system_user_group.terraform
  id = "name=terraform"
}

import {
  to = module.rb5009.module.base.routeros_system_user.admin
  id = "name=admin"
}

# switch-bridge imports
import {
  to = module.rb5009.module.switch.routeros_interface_bridge.this
  id = "name=bridge1"
}

locals {
  rb5009_ports = {
    "ether1"       = { comment = "WAN", bridge = false }
    "ether2"       = { comment = "C2758 IPMI (.30)", pvid = 1 }
    "ether3"       = { comment = "Disabled", disabled = true }
    "ether4"       = { comment = "Disabled", disabled = true }
    "ether5"       = { comment = "Disabled", disabled = true }
    "ether6"       = { comment = "VoIP", pvid = 40 }
    "ether7"       = { comment = "CCTV", pvid = 50 }
    "ether8"       = { comment = "CCTV", pvid = 50 }
    "sfp-sfpplus1" = { comment = "Trunk - CRS309 (${local.device_models["crs309"]})", vlans = local.all_vlan_ids }
  }

  rb5009_trunk_ports = {
    for name, port in local.rb5009_ports : name => port
    if !lookup(port, "disabled", false) && length(lookup(port, "vlans", [])) > 0 && lookup(port, "pvid", null) == null && lookup(port, "bridge", true)
  }

  rb5009_access_ports = {
    for name, port in local.rb5009_ports : name => port
    if !lookup(port, "disabled", false) && lookup(port, "pvid", null) != null && lookup(port, "bridge", true)
  }
}

import {
  for_each = local.rb5009_trunk_ports
  to       = module.rb5009.module.switch.routeros_interface_bridge_port.trunk[each.key]
  id       = "interface=${each.key}"
}

import {
  for_each = local.rb5009_access_ports
  to       = module.rb5009.module.switch.routeros_interface_bridge_port.access[each.key]
  id       = "interface=${each.key}"
}

import {
  to = module.rb5009.module.switch.routeros_interface_bridge_vlan.vlans["management"]
  id = "*1"
}

# Router component imports — bootstrap management IP
import {
  to = module.rb5009.module.router.routeros_ip_address.vlans["management"]
  id = "address=172.16.1.10/24"
}

module "rb5009" {
  source = "./modules/devices/router"
  providers = {
    routeros = routeros.rb5009
  }

  name                     = "rb5009"
  default_l2mtu            = 9796
  ip                       = local.device_ips["rb5009"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  terraform_user_name      = local.routeros_devices["rb5009"].username
  admin_password           = module.rb5009_bootstrap.admin_passwords["rb5009"]
  users                    = local.users

  wan_interfaces = {
    "ether1" = {}
  }

  ports = local.rb5009_ports

  vlans          = local.vlans
  firewall_zones = local.firewall_zones
  ssids          = local.ssids
  master_ssid    = local.master_ssid
  wifi_passwords = local.wifi_passwords

  dns_static_records = {
    "rb5009.${local.domain}"            = { address = local.device_ips["rb5009"] }
    "crs309.${local.domain}"            = { address = local.device_ips["crs309"] }
    "crs326.${local.domain}"            = { address = local.device_ips["crs326"] }
    "crs226.${local.domain}"            = { address = local.device_ips["crs226"] }
    "hap-ax2-musicroom.${local.domain}" = { address = local.device_ips["hap-ax2-musicroom"] }
    "hap-ax2-kitchen.${local.domain}"   = { address = local.device_ips["hap-ax2-kitchen"] }
    "truenas.${local.domain}"           = { address = "172.16.1.2" }
    "git.${local.domain}"               = { address = "172.16.1.3" }
  }

  dhcp_leases = {
    # Management (VLAN 1)
    "c2758-ipmi"  = { address = "172.16.1.30", mac_address = "0C:C4:7A:AD:BA:07", server = "management", comment = "C2758 IPMI" }
    "epyc-ipmi"   = { address = "172.16.1.31", mac_address = "D8:5E:D3:12:51:95", server = "management", comment = "Epyc3151 IPMI" }
    "homelab-git" = { address = "172.16.1.3", mac_address = "00:16:3E:6C:68:66", server = "management", comment = "Homelab Git" }

    # Home (VLAN 10)
    "appletv-living"    = { address = "172.16.10.10", mac_address = "50:DE:06:82:95:91", server = "home", comment = "LivingRoom AppleTV" }
    "yamaha-av"         = { address = "172.16.10.11", mac_address = "F8:33:31:C6:26:46", server = "home", comment = "LivingRoom Yamaha AV" }
    "office-powerstrip" = { address = "172.16.10.40", mac_address = "48:E1:E9:BB:92:A0", server = "home", comment = "Office Power Strip" }
    "office-homepod"    = { address = "172.16.10.41", mac_address = "58:D3:49:4E:8F:48", server = "home", comment = "Office Homepod" }

    # IoT (VLAN 30)
    "ac-livingroom"   = { address = "172.16.30.10", mac_address = "04:C4:61:B9:C3:AA", server = "iot", comment = "LivingRoom AC" }
    "ac-elena"        = { address = "172.16.30.20", mac_address = "DC:FE:23:B8:03:22", server = "iot", comment = "Elena AC" }
    "ac-maksim"       = { address = "172.16.30.30", mac_address = "DC:FE:23:B8:1D:DA", server = "iot", comment = "Maksim AC" }
    "ac-office"       = { address = "172.16.30.40", mac_address = "04:C4:61:B9:C3:8E", server = "iot", comment = "Office AC" }
    "ac-musicroom"    = { address = "172.16.30.50", mac_address = "DC:FE:23:B8:27:46", server = "iot", comment = "Musicroom AC" }
    "heating-kitchen" = { address = "172.16.30.60", mac_address = "B8:74:24:2A:A0:A6", server = "iot", comment = "Kitchen Heating" }

    # VoIP (VLAN 40)
    "grandstream-h802" = { address = "172.16.40.10", mac_address = "C0:74:AD:52:71:1C", server = "voip", comment = "Grandstream H802" }
    "cisco-spa112"     = { address = "172.16.40.11", mac_address = "00:A2:89:5B:6D:A3", server = "voip", comment = "Cisco SPA112" }

    # CCTV (VLAN 50)
    "nvr"                 = { address = "192.168.1.30", mac_address = "24:52:6A:A8:74:BC", server = "cctv", comment = "DHI-NVR5216-4KS2" }
    "vto"                 = { address = "192.168.1.50", mac_address = "24:52:6A:FE:CE:68", server = "cctv", comment = "VTO Doorbell" }
    "vth-display"         = { address = "192.168.1.51", mac_address = "24:52:6A:D0:81:4B", server = "cctv", comment = "VTH Display" }
    "ipc-e1b3000"         = { address = "192.168.1.60", mac_address = "00:2A:2A:5C:6E:71", server = "cctv", comment = "IPC-E1B3000-DH" }
    "ipc-hdw5231r"        = { address = "192.168.1.61", mac_address = "00:12:31:B6:10:52", server = "cctv", comment = "IPC-HDW5231R-ZE" }
    "ipc-62"              = { address = "192.168.1.62", mac_address = "00:12:42:19:35:7A", server = "cctv", comment = "CCTV camera" }
    "ipc-63"              = { address = "192.168.1.63", mac_address = "00:12:41:E8:D2:BE", server = "cctv", comment = "CCTV camera" }
    "asecam-garden-left"  = { address = "192.168.1.70", mac_address = "F6:3A:80:17:59:17", server = "cctv", comment = "Asecam 8mp - Garden Left" }
    "asecam-garden-right" = { address = "192.168.1.71", mac_address = "F6:3A:80:17:56:E5", server = "cctv", comment = "Asecam 8mp - Garden Right" }
    "asecam-fixed-left"   = { address = "192.168.1.72", mac_address = "F6:80:00:08:AA:4B", server = "cctv", comment = "Asecam 8mp - Fixed Left" }
    "asecam-fixed-right"  = { address = "192.168.1.73", mac_address = "F6:80:00:08:A9:CF", server = "cctv", comment = "Asecam 8mp - Fixed Right" }
    "anj-ptz-garden-left" = { address = "192.168.1.80", mac_address = "F0:00:05:09:EF:CB", server = "cctv", comment = "Anj PTZ - Garden Left" }
  }

  depends_on = [module.rb5009_bootstrap]
}

resource "terraform_data" "rb5009_apply" {
  input = "rb5009"

  depends_on = [
    module.rb5009_bootstrap,
    module.rb5009,
  ]
}

module "rb5009_bootstrap" {
  source = "./modules/components/bootstrap"
  devices = {
    rb5009 = merge(nonsensitive(local.routeros_devices["rb5009"]), {
      ip = local.device_ips["rb5009"]
    })
  }
}
