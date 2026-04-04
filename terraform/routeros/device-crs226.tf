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

provider "restapi" {
  alias          = "crs226_set"
  uri            = local.routeros_devices["crs226"].hosturl
  username       = local.routeros_devices["crs226"].username
  password       = local.routeros_devices["crs226"].password
  insecure       = true
  create_method  = "PUT"
  update_method  = "PATCH"
  destroy_method = "DELETE"
  # RouterOS command-style endpoints such as `/set` return `[]` on success,
  # so the generic provider must read the object back after the write.
  write_returns_object = false
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
  root_ca_cert_pem         = local.root_ca_cert_pem
  intermediate_ca_key_pem  = local.intermediate_ca_key_pem
  intermediate_ca_cert_pem = local.intermediate_ca_cert_pem
  vlans                    = local.vlans
  users                    = local.users

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

  depends_on = [module.crs226_bootstrap, module.crs226_trunk1]
}

# Import the bootstrap-created management IP so Terraform adopts it
# (and moves it from bridge1 to the mgmt VLAN interface).
# Query the ID after bootstrap:
#   curl -sk -u terraform:PASS https://172.16.1.13/rest/ip/address
# Remove this block after the first successful apply.
import {
  to = module.crs226.routeros_ip_address.management
  id = "*1"
}

# Switch-chip enforcement patch.
# Manage this via the raw REST module instead of the typed routeros provider
# resource, because the typed resource replays mirror fields like
# `ingress-mirror0=switch1-cpu,...` that RouterOS rejects on update.
module "crs226_switch_enforcement" {
  source = "./modules/components/routeros-raw"
  providers = {
    restapi = restapi.crs226_set
  }

  path        = "/rest/interface/ethernet/switch"
  create_path = "/rest/interface/ethernet/switch/set"
  # CRS2xx exposes this as a singleton menu. The read response includes a
  # stable `name`, but no `.id`, so use `name` as the resource identity.
  read_path     = "/rest/interface/ethernet/switch"
  create_method = "POST"
  update_path   = "/rest/interface/ethernet/switch/set"
  update_method = "POST"
  id_attribute  = "name"
  unordered_csv_keys = [
    "drop-if-invalid-or-src-port-not-member-of-vlan-on-ports",
  ]
  ignore_changes_to = [
    "bridge-type",
    "bypass-ingress-port-policing-for",
    "bypass-l2-security-check-filter-for",
    "bypass-vlan-ingress-filter-for",
    "drop-if-no-vlan-assignment-on-ports",
    "egress-mirror-ratio",
    "egress-mirror0",
    "egress-mirror1",
    "fdb-uses",
    "forward-unknown-vlan",
    "ingress-mirror-ratio",
    "ingress-mirror0",
    "ingress-mirror1",
    "mac-level-isolation",
    "mirror-egress-if-ingress-mirrored",
    "mirror-tx-on-mirror-port",
    "mirrored-packet-drop-precedence",
    "mirrored-packet-qos-priority",
    "multicast-lookup-mode",
    "override-existing-when-ufdb-full",
    "type",
    "unicast-fdb-timeout",
    "unknown-vlan-lookup-mode",
    "use-cvid-in-one2one-vlan-lookup",
    "use-svid-in-one2one-vlan-lookup",
    "vlan-uses",
  ]
  data = {
    "name" = "switch1"
    # RouterOS CLI accepts `switch1-cpu` in this list, but the REST/provider
    # update path validates only physical ports and hardware trunks here.
    "drop-if-invalid-or-src-port-not-member-of-vlan-on-ports" = join(",", sort([
      for port in tolist(module.crs226.vlan_aware_ports) : port
      if port != "switch1-cpu"
    ]))
  }

  depends_on = [module.crs226]
}

# Apply anchor for targeted single-device runs.
# Targeting this resource pulls in the full CRS226 dependency chain:
# bootstrap -> hardware trunk -> device module -> switch enforcement.
resource "terraform_data" "crs226_apply" {
  input = "crs226"

  depends_on = [
    module.crs226_bootstrap,
    module.crs226_trunk1,
    module.crs226,
    module.crs226_switch_enforcement,
  ]
}

module "crs226_bootstrap" {
  source  = "./modules/components/bootstrap"
  devices = { crs226 = nonsensitive(local.routeros_devices["crs226"]) }
}

# Hardware trunk — must be created before switch-chip VLAN config
# because egress VLAN tags reference trunk1 as a port.
module "crs226_trunk1" {
  source = "./modules/components/routeros-raw"
  providers = {
    restapi = restapi.crs226
  }

  path         = "/rest/interface/ethernet/switch/trunk"
  read_path    = "/rest/interface/ethernet/switch/trunk"
  search_key   = "name"
  search_value = "trunk1"
  unordered_csv_keys = [
    "member-ports",
  ]
  # RouterOS returns additional/default trunk fields that the generic REST
  # provider treats as drift. Ignore the noisy server shape, but keep the
  # module's postcondition to verify name/member-ports/comment round-trip.
  ignore_all_server_changes = true
  data = {
    "name"         = "trunk1"
    "member-ports" = "ether3,ether4,ether5,ether6"
    "comment"      = "QNAP / TrueNAS backup"
  }

  depends_on = [module.crs226_bootstrap]
}
