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

module "rb5009" {
  source = "./modules/devices/router"
  providers = {
    routeros = routeros.rb5009
  }

  name                     = "rb5009"
  ip                       = local.device_ips["rb5009"]
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem

  vlans          = local.vlans
  firewall_zones = local.firewall_zones
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
    # Non-MikroTik devices that still need DHCP leases (no static IP config)
    "horaco-10g" = { address = "172.16.1.20", mac_address = "1C:2A:A3:1E:7E:94", server = "management", comment = "horaco-10g (Horaco 8-port 10G)" }
    "horaco-2g5" = { address = "172.16.1.21", mac_address = "78:D8:00:32:AF:E9", server = "management", comment = "horaco-2g5 (Horaco 8-port 2.5G)" }
    "c2758-ipmi" = { address = "172.16.1.30", mac_address = "0C:C4:7A:AD:BA:07", server = "management", comment = "c2758-ipmi (C2758 IPMI)" }
    "epyc-ipmi"  = { address = "172.16.1.31", mac_address = "D8:5E:D3:12:51:95", server = "management", comment = "epyc-ipmi (Epyc3151 IPMI)" }

    # TODO: Review and add remaining leases for Home, IoT, VoIP, CCTV VLANs
  }

  depends_on = [module.bootstrap]
}
