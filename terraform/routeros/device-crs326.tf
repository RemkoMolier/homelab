provider "routeros" {
  alias    = "crs326"
  hosturl  = var.routeros_devices["crs326"].hosturl
  username = var.routeros_devices["crs326"].username
  password = var.routeros_devices["crs326"].password
  insecure = var.routeros_devices["crs326"].insecure
}

# CRS326-24G-2S+RM — 24-port GbE switch (.12)
#
# Ports:
#   ether1     — Trunk (uplink via CRS309)
#   ether2     — Disabled
#   ether3     — Trunk to hAP AX2 Music Room
#   ether4     — Disabled (label says Kitchen but Kitchen is on CRS309 sfp+3)
#   ether5-8   — Bond "c2758" (LACP to C2758 server)
#   ether9-24  — Disabled
#   sfp+1      — Trunk (uplink via CRS309)
#   sfp+2      — Disabled

module "crs326_cert" {
  source = "./modules/certificates"

  device_name              = "crs326"
  device_ip                = "172.16.1.12"
  intermediate_ca_key_pem  = file("${local.pki_dir}/intermediate-ca/ca.key")
  intermediate_ca_cert_pem = file("${local.pki_dir}/intermediate-ca/ca.crt")
}

module "crs326_base" {
  source = "./modules/device-base"
  providers = {
    routeros = routeros.crs326
  }

  identity         = "crs326-24g-2s+"
  certificate_name = "api-cert"

  depends_on = [module.bootstrap]
}

module "crs326_switch" {
  source = "./modules/switch-bridge"
  providers = {
    routeros = routeros.crs326
  }

  vlans = local.vlans

  ports = {
    "ether1"        = { comment = "Trunk",                      vlans = local.all_vlan_ids }
    "ether2"        = { comment = "Disabled",                   disabled = true }
    "ether3"        = { comment = "Trunk - hAP AX2 Music Room", vlans = local.all_vlan_ids }
    "ether4"        = { comment = "Disabled",                   disabled = true }
    "ether5"        = { comment = "Bond C2758",                 bond = "c2758" }
    "ether6"        = { comment = "Bond C2758",                 bond = "c2758" }
    "ether7"        = { comment = "Bond C2758",                 bond = "c2758" }
    "ether8"        = { comment = "Bond C2758",                 bond = "c2758" }
    "ether9"        = { comment = "Disabled", disabled = true }
    "ether10"       = { comment = "Disabled", disabled = true }
    "ether11"       = { comment = "Disabled", disabled = true }
    "ether12"       = { comment = "Disabled", disabled = true }
    "ether13"       = { comment = "Disabled", disabled = true }
    "ether14"       = { comment = "Disabled", disabled = true }
    "ether15"       = { comment = "Disabled", disabled = true }
    "ether16"       = { comment = "Disabled", disabled = true }
    "ether17"       = { comment = "Disabled", disabled = true }
    "ether18"       = { comment = "Disabled", disabled = true }
    "ether19"       = { comment = "Disabled", disabled = true }
    "ether20"       = { comment = "Disabled", disabled = true }
    "ether21"       = { comment = "Disabled", disabled = true }
    "ether22"       = { comment = "Disabled", disabled = true }
    "ether23"       = { comment = "Disabled", disabled = true }
    "ether24"       = { comment = "Disabled", disabled = true }
    "sfp-sfpplus1"  = { comment = "Trunk",                      vlans = local.all_vlan_ids }
    "sfp-sfpplus2"  = { comment = "Disabled",                   disabled = true }
  }

  bonds = {
    "c2758" = {
      comment = "LACP bond to C2758 server"
      vlans   = local.all_vlan_ids
    }
  }

  depends_on = [module.crs326_base]
}
