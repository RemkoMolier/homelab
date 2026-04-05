# DHCP — one server per VLAN with pools and static leases.

# --- IP pools ---

resource "routeros_ip_pool" "vlans" {
  for_each = var.vlans

  name    = each.key
  ranges  = [each.value.pool]
  comment = each.value.comment
}

# --- DHCP servers ---

resource "routeros_ip_dhcp_server" "vlans" {
  for_each = var.vlans

  name            = each.key
  interface       = "vrrp${each.value.id}"
  address_pool    = routeros_ip_pool.vlans[each.key].name
  lease_time      = each.key == "guest" ? "1h" : "1d"
  dhcp_option_set = each.key == "management" ? routeros_ip_dhcp_server_option_sets.pxe_bios.name : null
  bootp_support   = each.key == "management" ? "none" : null
  comment         = each.value.comment

  depends_on = [routeros_interface_vrrp.vlans]
}

# --- DHCP networks ---

resource "routeros_ip_dhcp_server_network" "vlans" {
  for_each = var.vlans

  address        = each.value.subnet
  gateway        = each.value.gateway
  dns_server     = [each.value.gateway]
  ntp_server     = [each.value.gateway]
  next_server    = each.key == "management" ? each.value.gateway : null
  boot_file_name = each.key == "management" ? "netboot.xyz-undionly.kpxe" : null
  comment        = each.value.comment

  depends_on = [routeros_ip_dhcp_server.vlans]
}

# --- Static leases ---

resource "routeros_ip_dhcp_server_lease" "static" {
  for_each = var.dhcp_leases

  address     = each.value.address
  mac_address = each.value.mac_address
  server      = each.value.server
  comment     = each.value.comment != "" ? each.value.comment : each.key
  depends_on  = [routeros_ip_dhcp_server.vlans]
}
