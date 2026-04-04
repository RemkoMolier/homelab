provider "routeros" {
  alias    = "hap_ax2_musicroom"
  hosturl  = local.routeros_devices["hap-ax2-musicroom"].hosturl
  username = local.routeros_devices["hap-ax2-musicroom"].username
  password = local.routeros_devices["hap-ax2-musicroom"].password
  insecure = local.routeros_devices["hap-ax2-musicroom"].insecure
}

# hAP AX2 — Music Room (.15)
# CAPsMAN-managed WiFi AP. Trunk to CRS326 ether3.

module "hap_ax2_musicroom" {
  source = "./modules/devices/ap"
  providers = {
    routeros = routeros.hap_ax2_musicroom
  }

  name                     = "hap-ax2-musicroom"
  ip                       = local.device_ips["hap-ax2-musicroom"]
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  vlans                    = local.vlans
  users                    = local.users

  ports = {
    "ether1" = { comment = "Trunk - crs326 (${local.device_models["crs326"]})", vlans = local.all_vlan_ids }
    "ether2" = { comment = "Disabled", disabled = true }
    "ether3" = { comment = "Disabled", disabled = true }
    "ether4" = { comment = "Disabled", disabled = true }
    "ether5" = { comment = "Disabled", disabled = true }
  }

  depends_on = [module.hap_ax2_musicroom_bootstrap]
}

resource "terraform_data" "hap_ax2_musicroom_apply" {
  input = "hap-ax2-musicroom"

  depends_on = [
    module.hap_ax2_musicroom_bootstrap,
    module.hap_ax2_musicroom,
  ]
}

module "hap_ax2_musicroom_bootstrap" {
  source  = "./modules/components/bootstrap"
  devices = { "hap-ax2-musicroom" = nonsensitive(local.routeros_devices["hap-ax2-musicroom"]) }
}
