provider "routeros" {
  alias    = "hap_ax2_kitchen"
  hosturl  = var.routeros_devices["hap-ax2-kitchen"].hosturl
  username = var.routeros_devices["hap-ax2-kitchen"].username
  password = var.routeros_devices["hap-ax2-kitchen"].password
  insecure = var.routeros_devices["hap-ax2-kitchen"].insecure
}

# hAP AX2 — Kitchen (.16)
# CAPsMAN-managed WiFi AP. WiFi config is pushed from the RB5009.
# Extra ethernet ports serve as Home VLAN access ports.
#
# Ports:
#   ether1     — Trunk to CRS309 sfp+3 (2.5G)
#   ether2-5   — Access ports, Home VLAN 10 (untagged)

module "hap_ax2_kitchen_cert" {
  source = "./modules/certificates"

  device_name              = "hap-ax2-kitchen"
  device_ip                = "172.16.1.16"
  intermediate_ca_key_pem  = file("${local.pki_dir}/intermediate-ca/ca.key")
  intermediate_ca_cert_pem = file("${local.pki_dir}/intermediate-ca/ca.crt")
}

module "hap_ax2_kitchen_base" {
  source = "./modules/device-base"
  providers = {
    routeros = routeros.hap_ax2_kitchen
  }

  identity         = "hap-ax2-kitchen"
  certificate_name = "api-cert"

  depends_on = [module.bootstrap]
}

module "hap_ax2_kitchen_switch" {
  source = "./modules/switch-bridge"
  providers = {
    routeros = routeros.hap_ax2_kitchen
  }

  vlans = local.vlans

  ports = {
    "ether1" = { comment = "Trunk - CRS309 sfp+3", vlans = local.all_vlan_ids }
    "ether2" = { comment = "Home access port", pvid = 10 }
    "ether3" = { comment = "Home access port", pvid = 10 }
    "ether4" = { comment = "Home access port", pvid = 10 }
    "ether5" = { comment = "Home access port", pvid = 10 }
  }

  depends_on = [module.hap_ax2_kitchen_base]
}
