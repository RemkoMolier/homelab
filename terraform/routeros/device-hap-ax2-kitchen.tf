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

module "hap_ax2_kitchen" {
  source = "./modules/devices/ap"
  providers = {
    routeros = routeros.hap_ax2_kitchen
  }

  name                     = "hap-ax2-kitchen"
  ip                       = local.device_ips["hap-ax2-kitchen"]
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  vlans                    = local.vlans

  ports = {
    "ether1" = { comment = "Trunk - crs309 (${module.crs309.model})", vlans = local.all_vlan_ids }
    "ether2" = { comment = "Home access port", pvid = 10 }
    "ether3" = { comment = "Home access port", pvid = 10 }
    "ether4" = { comment = "Home access port", pvid = 10 }
    "ether5" = { comment = "Home access port", pvid = 10 }
  }

  depends_on = [module.bootstrap]
}
