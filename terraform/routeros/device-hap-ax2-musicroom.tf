provider "routeros" {
  alias    = "hap_ax2_musicroom"
  hosturl  = var.routeros_devices["hap-ax2-musicroom"].hosturl
  username = var.routeros_devices["hap-ax2-musicroom"].username
  password = var.routeros_devices["hap-ax2-musicroom"].password
  insecure = var.routeros_devices["hap-ax2-musicroom"].insecure
}

# hAP AX2 — Music Room (.15)
# CAPsMAN-managed WiFi AP. WiFi config is pushed from the RB5009.
#
# Ports:
#   ether1     — Trunk to CRS326 ether3
#   ether2-5   — Disabled

module "hap_ax2_musicroom_cert" {
  source = "./modules/certificates"

  device_name              = "hap-ax2-musicroom"
  device_ip                = "172.16.1.15"
  intermediate_ca_key_pem  = file("${local.pki_dir}/intermediate-ca/ca.key")
  intermediate_ca_cert_pem = file("${local.pki_dir}/intermediate-ca/ca.crt")
}

module "hap_ax2_musicroom_base" {
  source = "./modules/device-base"
  providers = {
    routeros = routeros.hap_ax2_musicroom
  }

  identity         = "hap-ax2-musicroom"
  certificate_name = "api-cert"

  depends_on = [module.bootstrap]
}

module "hap_ax2_musicroom_switch" {
  source = "./modules/switch-bridge"
  providers = {
    routeros = routeros.hap_ax2_musicroom
  }

  vlans = local.vlans

  ports = {
    "ether1" = { comment = "Trunk - CRS326", vlans = local.all_vlan_ids }
    "ether2" = { comment = "Disabled", disabled = true }
    "ether3" = { comment = "Disabled", disabled = true }
    "ether4" = { comment = "Disabled", disabled = true }
    "ether5" = { comment = "Disabled", disabled = true }
  }

  depends_on = [module.hap_ax2_musicroom_base]
}
