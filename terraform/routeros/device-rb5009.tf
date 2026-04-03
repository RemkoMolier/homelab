provider "routeros" {
  alias    = "rb5009"
  hosturl  = var.routeros_devices["rb5009"].hosturl
  username = var.routeros_devices["rb5009"].username
  password = var.routeros_devices["rb5009"].password
  insecure = var.routeros_devices["rb5009"].insecure
}

# RB5009UG+S+IN — Main router (.10, VRRP .1)
#
# Ports:
#   ether1     — WAN (PPPoE)
#   ether2     — C2758 IPMI (.30), trunk
#   ether3-5   — Disabled
#   ether6     — VoIP (untagged VLAN 40)
#   ether7     — CCTV (untagged VLAN 50)
#   ether8     — CCTV (untagged VLAN 50)
#   sfp+1      — Trunk to CRS309

module "rb5009_cert" {
  source = "./modules/certificates"

  device_name              = "rb5009"
  device_ip                = "172.16.1.10"
  intermediate_ca_key_pem  = file("${local.pki_dir}/intermediate-ca/ca.key")
  intermediate_ca_cert_pem = file("${local.pki_dir}/intermediate-ca/ca.crt")
}

module "rb5009_base" {
  source = "./modules/device-base"
  providers = {
    routeros = routeros.rb5009
  }

  identity         = "rb5009ug+s+in"
  certificate_name = "api-cert"

  depends_on = [module.bootstrap]
}

module "rb5009_router" {
  source = "./modules/router"
  providers = {
    routeros = routeros.rb5009
  }

  vlans          = local.vlans
  firewall_zones = local.firewall_zones
  pppoe_user     = var.routeros_devices["rb5009"].username # TODO: separate PPPoE credential

  dns_static_records = {
    "truenas.home.molier.net" = { address = "172.16.1.2" }
    "git.home.molier.net"     = { address = "172.16.1.3" }
  }

  dhcp_leases = {
    # Infrastructure — Management VLAN
    "crs309"        = { address = "172.16.1.11", mac_address = "C4:AD:34:05:6C:A9", server = "management", comment = "CRS309-1G-8S+IN" }
    "crs326"        = { address = "172.16.1.12", mac_address = "B8:69:F4:34:94:B0", server = "management", comment = "CRS326-24G-2S+RM" }
    "crs226"        = { address = "172.16.1.13", mac_address = "4C:5E:0C:9C:14:E8", server = "management", comment = "CRS226-24G-2S+RM" }
    "hap-ax2-music" = { address = "172.16.1.15", mac_address = "48:A9:8A:98:34:DC", server = "management", comment = "hAP AX2 - Music Room" }
    "hap-ax2-kit"   = { address = "172.16.1.16", mac_address = "48:A9:8A:95:C6:AC", server = "management", comment = "hAP AX2 - Kitchen" }
    "horaco-10g"    = { address = "172.16.1.20", mac_address = "1C:2A:A3:1E:7E:94", server = "management", comment = "Horaco 8-port 10G" }
    "horaco-2g5"    = { address = "172.16.1.21", mac_address = "78:D8:00:32:AF:E9", server = "management", comment = "Horaco 8-port 2.5G" }
    "c2758-ipmi"    = { address = "172.16.1.30", mac_address = "0C:C4:7A:AD:BA:07", server = "management", comment = "C2758 IPMI" }
    "epyc-ipmi"     = { address = "172.16.1.31", mac_address = "D8:5E:D3:12:51:95", server = "management", comment = "Epyc3151 IPMI" }

    # TODO: Review and add remaining leases for Home, IoT, VoIP, CCTV VLANs
    # The user will manually review stale leases before adding them here.
  }

  depends_on = [module.rb5009_base]
}
