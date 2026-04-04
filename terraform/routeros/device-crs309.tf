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
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  vlans                    = local.vlans

  ports = {
    "ether1"       = { comment = "Trunk (unused)", vlans = local.all_vlan_ids }
    "sfp-sfpplus1" = { comment = "Trunk - rb5009 (${module.rb5009.model})", vlans = local.all_vlan_ids }
    "sfp-sfpplus2" = { comment = "Trunk - crs326 (${module.crs326.model})", vlans = local.all_vlan_ids }
    "sfp-sfpplus3" = { comment = "Trunk - hap-ax2-kitchen (${module.hap_ax2_kitchen.model})", vlans = local.all_vlan_ids, speed = "2.5G-baseX" }
    "sfp-sfpplus4" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus5" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus6" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus7" = { comment = "Disabled", disabled = true }
    "sfp-sfpplus8" = { comment = "Trunk - crs226 (${module.crs226.model})", vlans = local.all_vlan_ids }
  }

  depends_on = [module.bootstrap]
}
