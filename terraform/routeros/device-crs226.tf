provider "routeros" {
  alias    = "crs226"
  hosturl  = local.routeros_devices["crs226"].hosturl
  username = local.routeros_devices["crs226"].username
  password = local.routeros_devices["crs226"].password
  insecure = local.routeros_devices["crs226"].insecure
}

provider "restapi" {
  alias                = "crs226"
  uri                  = local.routeros_devices["crs226"].hosturl
  username             = local.routeros_devices["crs226"].username
  password             = local.routeros_devices["crs226"].password
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
# Uplink: sfp+1 → Horaco 10G (.20). sfpplus2 is empty.
# Legacy switch-chip VLANs. Hardware trunk via restapi provider.

module "crs226" {
  source = "./modules/devices/switch-chip"
  providers = {
    routeros = routeros.crs226
  }

  name                     = "crs226"
  ip                       = local.device_ips["crs226"]
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  vlans                    = local.vlans

  ports = {
    "ether1"       = { comment = "Epyc IPMI (.31)", pvid = 1 }
    "ether2"       = { comment = "Disabled", disabled = true }
    "ether3"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether4"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether5"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether6"       = { comment = "Trunk1 - QNAP", trunk = "trunk1" }
    "ether7"       = { comment = "Disabled", disabled = true }
    "ether8"       = { comment = "Disabled", disabled = true }
    "ether9"       = { comment = "Disabled", disabled = true }
    "ether10"      = { comment = "Trunk", vlans = local.all_vlan_ids }
    "ether11"      = { comment = "Disabled", disabled = true }
    "ether12"      = { comment = "Trunk", vlans = local.all_vlan_ids }
    "ether13"      = { comment = "Disabled", disabled = true }
    "ether14"      = { comment = "Disabled", disabled = true }
    "ether15"      = { comment = "Disabled", disabled = true }
    "ether16"      = { comment = "Disabled", disabled = true }
    "ether17"      = { comment = "Disabled", disabled = true }
    "ether18"      = { comment = "Disabled", disabled = true }
    "ether19"      = { comment = "Disabled", disabled = true }
    "ether20"      = { comment = "Disabled", disabled = true }
    "ether21"      = { comment = "Disabled", disabled = true }
    "ether22"      = { comment = "CCTV access", pvid = 50 }
    "ether23"      = { comment = "Disabled", disabled = true }
    "ether24"      = { comment = "Disabled", disabled = true }
    "sfp-sfpplus1" = { comment = "Trunk - Horaco 10G (.20)", vlans = local.all_vlan_ids }
    "sfpplus2"     = { comment = "Disabled", disabled = true }
  }

  trunks = {
    "trunk1" = {
      comment = "QNAP / TrueNAS backup"
      members = ["ether3", "ether4", "ether5", "ether6"]
      vlans   = local.all_vlan_ids
    }
  }

  depends_on = [module.bootstrap]
}

# Hardware trunk — not covered by routeros provider
module "crs226_trunk1" {
  source = "./modules/components/routeros-raw"
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

  depends_on = [module.crs226]
}
