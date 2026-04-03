provider "routeros" {
  alias    = "crs309"
  hosturl  = var.routeros_devices["crs309"].hosturl
  username = var.routeros_devices["crs309"].username
  password = var.routeros_devices["crs309"].password
  insecure = var.routeros_devices["crs309"].insecure
}

# CRS309-1G-8S+IN — 10G core switch (.11)
#
# Ports:
#   ether1     — Trunk (not used currently)
#   sfp+1      — Trunk to RB5009
#   sfp+2      — Trunk to CRS326
#   sfp+3      — Trunk to hAP AX2 Kitchen (2.5G)
#   sfp+4-7    — Disabled
#   sfp+8      — Trunk to CRS226

module "crs309_cert" {
  source = "./modules/certificates"

  device_name              = "crs309"
  device_ip                = "172.16.1.11"
  intermediate_ca_key_pem  = file("${local.pki_dir}/intermediate-ca/ca.key")
  intermediate_ca_cert_pem = file("${local.pki_dir}/intermediate-ca/ca.crt")
}

module "crs309_base" {
  source = "./modules/device-base"
  providers = {
    routeros = routeros.crs309
  }

  identity         = "crs309-1g-8s+"
  certificate_name = "api-cert"

  depends_on = [module.bootstrap]
}

module "crs309_switch" {
  source = "./modules/switch-bridge"
  providers = {
    routeros = routeros.crs309
  }

  vlans = local.vlans

  ports = {
    "ether1"        = { comment = "Trunk (unused)",            disabled = false, vlans = local.all_vlan_ids }
    "sfp-sfpplus1"  = { comment = "Trunk - RB5009",            vlans = local.all_vlan_ids }
    "sfp-sfpplus2"  = { comment = "Trunk - CRS326",            vlans = local.all_vlan_ids }
    "sfp-sfpplus3"  = { comment = "Trunk - hAP AX2 Kitchen",   vlans = local.all_vlan_ids, speed = "2.5G-baseX" }
    "sfp-sfpplus4"  = { comment = "Disabled", disabled = true }
    "sfp-sfpplus5"  = { comment = "Disabled", disabled = true }
    "sfp-sfpplus6"  = { comment = "Disabled", disabled = true }
    "sfp-sfpplus7"  = { comment = "Disabled", disabled = true }
    "sfp-sfpplus8"  = { comment = "Trunk - CRS226",            vlans = local.all_vlan_ids }
  }

  depends_on = [module.crs309_base]
}
