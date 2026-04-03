provider "routeros" {
  alias    = "crs226"
  hosturl  = var.routeros_devices["crs226"].hosturl
  username = var.routeros_devices["crs226"].username
  password = var.routeros_devices["crs226"].password
  insecure = var.routeros_devices["crs226"].insecure
}

# REST API provider for resources not covered by terraform-provider-routeros
provider "restapi" {
  alias                = "crs226"
  uri                  = var.routeros_devices["crs226"].hosturl
  username             = var.routeros_devices["crs226"].username
  password             = var.routeros_devices["crs226"].password
  insecure             = true
  create_method        = "PUT"
  update_method        = "PATCH"
  destroy_method       = "DELETE"
  write_returns_object = true
  id_attribute         = ".id"
  headers = {
    "Content-Type" = "application/json"
  }
}

# CRS226-24G-2S+RM — 24-port GbE switch (.13)
# Uses legacy switch-chip VLANs (cannot do hw-offloaded bridge VLAN filtering).
#
# Ports:
#   ether1      — Trunk (administration)
#   ether2      — Disabled
#   ether3-6    — Trunk group "trunk1" (QNAP / TrueNAS backup)
#   ether7      — Disabled
#   ether8-21   — Disabled
#   ether22     — CCTV access (untagged VLAN 50)
#   ether23-24  — Disabled
#   sfp+1       — Trunk
#   sfpplus2    — Trunk to CRS309
#
# Hardware trunk group managed via the restapi provider since there is
# no dedicated routeros resource for /interface/ethernet/switch/trunk.

module "crs226_cert" {
  source = "./modules/certificates"

  device_name              = "crs226"
  device_ip                = "172.16.1.13"
  intermediate_ca_key_pem  = file("${local.pki_dir}/intermediate-ca/ca.key")
  intermediate_ca_cert_pem = file("${local.pki_dir}/intermediate-ca/ca.crt")
}

module "crs226_base" {
  source = "./modules/device-base"
  providers = {
    routeros = routeros.crs226
  }

  identity         = "crs226-24g-2s+"
  certificate_name = "api-cert"

  depends_on = [module.bootstrap]
}

module "crs226_switch" {
  source = "./modules/switch-chip"
  providers = {
    routeros = routeros.crs226
  }

  vlans = local.vlans

  ports = {
    "ether1"        = { comment = "Trunk (administration)",     vlans = local.all_vlan_ids }
    "ether2"        = { comment = "Disabled",                   disabled = true }
    "ether3"        = { comment = "Trunk1 - QNAP",             trunk = "trunk1" }
    "ether4"        = { comment = "Trunk1 - QNAP",             trunk = "trunk1" }
    "ether5"        = { comment = "Trunk1 - QNAP",             trunk = "trunk1" }
    "ether6"        = { comment = "Trunk1 - QNAP",             trunk = "trunk1" }
    "ether7"        = { comment = "Disabled",                   disabled = true }
    "ether8"        = { comment = "Disabled",                   disabled = true }
    "ether9"        = { comment = "Disabled",                   disabled = true }
    "ether10"       = { comment = "Trunk",                      vlans = local.all_vlan_ids }
    "ether11"       = { comment = "Disabled",                   disabled = true }
    "ether12"       = { comment = "Trunk",                      vlans = local.all_vlan_ids }
    "ether13"       = { comment = "Disabled",                   disabled = true }
    "ether14"       = { comment = "Disabled",                   disabled = true }
    "ether15"       = { comment = "Disabled",                   disabled = true }
    "ether16"       = { comment = "Disabled",                   disabled = true }
    "ether17"       = { comment = "Disabled",                   disabled = true }
    "ether18"       = { comment = "Disabled",                   disabled = true }
    "ether19"       = { comment = "Disabled",                   disabled = true }
    "ether20"       = { comment = "Disabled",                   disabled = true }
    "ether21"       = { comment = "Disabled",                   disabled = true }
    "ether22"       = { comment = "CCTV access",                pvid = 50 }
    "ether23"       = { comment = "Disabled",                   disabled = true }
    "ether24"       = { comment = "Disabled",                   disabled = true }
    "sfp-sfpplus1"  = { comment = "Trunk",                      vlans = local.all_vlan_ids }
    "sfpplus2"      = { comment = "Trunk - CRS309",             vlans = local.all_vlan_ids }
  }

  trunks = {
    "trunk1" = {
      comment = "QNAP / TrueNAS backup"
      members = ["ether3", "ether4", "ether5", "ether6"]
      vlans   = local.all_vlan_ids
    }
  }

  depends_on = [module.crs226_base]
}

module "crs226_trunk1" {
  source = "./modules/routeros-raw"
  providers = {
    restapi = restapi.crs226
  }

  path         = "/rest/interface/ethernet/switch/trunk"
  search_key   = "name"
  search_value = "trunk1"
  data = {
    "name"         = "trunk1"
    "member-ports" = "ether3,ether4,ether5,ether6"
    "comment"      = "QNAP / TrueNAS backup"
  }

  depends_on = [module.crs226_base]
}
