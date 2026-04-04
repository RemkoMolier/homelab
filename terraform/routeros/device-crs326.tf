provider "routeros" {
  alias    = "crs326"
  hosturl  = local.routeros_devices["crs326"].hosturl
  username = local.routeros_devices["crs326"].username
  password = local.routeros_devices["crs326"].password
  insecure = local.routeros_devices["crs326"].insecure
}

# CRS326-24G-2S+RM — 24-port GbE switch (.12)

module "crs326" {
  source = "./modules/devices/switch"
  providers = {
    routeros = routeros.crs326
  }

  name                     = "crs326"
  ip                       = local.device_ips["crs326"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  vlans                    = local.vlans
  users                    = local.users

  ports = {
    "ether1"       = { comment = "Trunk", vlans = local.all_vlan_ids }
    "ether2"       = { comment = "Disabled", disabled = true }
    "ether3"       = { comment = "Trunk - hap-ax2-musicroom (${local.device_models["hap-ax2-musicroom"]})", vlans = local.all_vlan_ids }
    "ether4"       = { comment = "Disabled", disabled = true }
    "ether5"       = { comment = "Bond C2758", bond = "c2758" }
    "ether6"       = { comment = "Bond C2758", bond = "c2758" }
    "ether7"       = { comment = "Bond C2758", bond = "c2758" }
    "ether8"       = { comment = "Bond C2758", bond = "c2758" }
    "ether9"       = { comment = "Disabled", disabled = true }
    "ether10"      = { comment = "Disabled", disabled = true }
    "ether11"      = { comment = "Disabled", disabled = true }
    "ether12"      = { comment = "Disabled", disabled = true }
    "ether13"      = { comment = "Disabled", disabled = true }
    "ether14"      = { comment = "Disabled", disabled = true }
    "ether15"      = { comment = "Disabled", disabled = true }
    "ether16"      = { comment = "Disabled", disabled = true }
    "ether17"      = { comment = "Disabled", disabled = true }
    "ether18"      = { comment = "Disabled", disabled = true }
    "ether19"      = { comment = "Disabled", disabled = true }
    "ether20"      = { comment = "Disabled", disabled = true }
    "ether21"      = { comment = "Disabled", disabled = true }
    "ether22"      = { comment = "Disabled", disabled = true }
    "ether23"      = { comment = "Disabled", disabled = true }
    "ether24"      = { comment = "Disabled", disabled = true }
    "sfp-sfpplus1" = { comment = "Trunk", vlans = local.all_vlan_ids }
    "sfp-sfpplus2" = { comment = "Disabled", disabled = true }
  }

  bonds = {
    "c2758" = {
      comment = "LACP bond to C2758 server"
      vlans   = local.all_vlan_ids
    }
  }

  depends_on = [module.crs326_bootstrap]
}

resource "terraform_data" "crs326_apply" {
  input = "crs326"

  depends_on = [
    module.crs326_bootstrap,
    module.crs326,
  ]
}

module "crs326_bootstrap" {
  source  = "./modules/components/bootstrap"
  devices = { crs326 = nonsensitive(local.routeros_devices["crs326"]) }
}
