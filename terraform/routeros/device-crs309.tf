provider "routeros" {
  alias    = "crs309"
  hosturl  = local.routeros_devices["crs309"].hosturl
  username = local.routeros_devices["crs309"].username
  password = local.routeros_devices["crs309"].password
  insecure = local.routeros_devices["crs309"].insecure
}

# CRS309-1G-8S+IN — 10G core switch (.11)

module "crs309" {
  source = "./modules/devices/switch"
  providers = {
    routeros = routeros.crs309
  }

  name                     = "crs309"
  ip                       = local.device_ips["crs309"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  vlans                    = local.vlans
  users                    = local.users

  ports = {
    "ether1"       = { comment = "Trunk (unused)", vlans = local.all_vlan_ids }
    "sfp-sfpplus1" = { comment = "Trunk - rb5009 (${local.device_models["rb5009"]})", vlans = local.all_vlan_ids }
    "sfp-sfpplus2" = { comment = "Trunk - crs326 (${local.device_models["crs326"]})", vlans = local.all_vlan_ids }
    "sfp-sfpplus3" = { comment = "Trunk - hap-ax2-kitchen (${local.device_models["hap-ax2-kitchen"]})", vlans = local.all_vlan_ids, speed = "2.5G-baseX" }
    "sfp-sfpplus4" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus5" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus6" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus7" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus8" = { comment = "Trunk - Horaco 10G (.20)", vlans = local.all_vlan_ids }
  }

  depends_on = [module.crs309_bootstrap]
}

resource "terraform_data" "crs309_apply" {
  input = "crs309"

  depends_on = [
    module.crs309_bootstrap,
    module.crs309,
  ]
}

module "crs309_bootstrap" {
  source  = "./modules/components/bootstrap"
  devices = { crs309 = nonsensitive(local.routeros_devices["crs309"]) }
}
