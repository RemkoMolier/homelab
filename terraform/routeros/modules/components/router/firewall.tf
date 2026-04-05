# Zone-based firewall rules for the RB5009.
#
# Zones:
#   trusted  (management)  — full access to everything
#   home     (home)        — internet + IoT + CCTV
#   limited  (iot, voip)   — internet only, no lateral movement
#   isolated (cctv)        — fully isolated, no internet
#   guest    (guest)       — internet only, client-isolated
#
# Rule ordering: rules are chained with depends_on so they are created
# top-down (accept rules first, drop rules last). This avoids the
# place_before problem where drop rules are created before accept rules,
# which would kill the Terraform API connection mid-apply.

# --- Interface lists for firewall zones ---

resource "routeros_interface_list" "wan" {
  name = "wan-list"
}

resource "routeros_interface_list_member" "wan" {
  for_each  = var.wan_interfaces
  interface = each.key
  list      = routeros_interface_list.wan.name
}

resource "routeros_interface_list" "zones" {
  for_each = var.firewall_zones
  name     = "${each.key}-list"
}

resource "routeros_interface_list_member" "zone_members" {
  for_each = merge([
    for zone, vlan_keys in var.firewall_zones : {
      for vlan_key in vlan_keys :
      "${zone}-${vlan_key}" => {
        list      = zone
        interface = local.vlan_interfaces[vlan_key]
      }
    }
  ]...)

  list      = routeros_interface_list.zones[each.value.list].name
  interface = each.value.interface

  depends_on = [routeros_interface_vlan.vlans]
}

resource "routeros_interface_list_member" "zone_vrrp_members" {
  for_each = merge([
    for zone, vlan_keys in var.firewall_zones : {
      for vlan_key in vlan_keys :
      "${zone}-vrrp${var.vlans[vlan_key].id}" => {
        list      = zone
        interface = "vrrp${var.vlans[vlan_key].id}"
      }
    }
  ]...)

  list      = routeros_interface_list.zones[each.value.list].name
  interface = each.value.interface

  depends_on = [routeros_interface_vrrp.vlans]
}

# --- Input chain ---
# Order: established → drop-invalid → icmp → dhcp → dns → ntp →
#        ssh → https → capsman → drop-wan → drop-all

resource "routeros_ip_firewall_filter" "input_established" {
  chain            = "input"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Accept established/related"

  depends_on = [
    routeros_interface_list_member.wan,
    routeros_interface_list_member.zone_members,
  ]
}

resource "routeros_ip_firewall_filter" "input_drop_invalid" {
  chain            = "input"
  action           = "drop"
  connection_state = "invalid"
  comment          = "Drop invalid"

  depends_on = [routeros_ip_firewall_filter.input_established]
}

resource "routeros_ip_firewall_filter" "input_icmp" {
  chain    = "input"
  action   = "accept"
  protocol = "icmp"
  comment  = "Accept ICMP"

  depends_on = [routeros_ip_firewall_filter.input_drop_invalid]
}

resource "routeros_ip_firewall_filter" "input_dhcp" {
  chain    = "input"
  action   = "accept"
  protocol = "udp"
  dst_port = "67-68"
  comment  = "Accept DHCP"

  depends_on = [routeros_ip_firewall_filter.input_icmp]
}

resource "routeros_ip_firewall_filter" "input_dns" {
  chain    = "input"
  action   = "accept"
  protocol = "udp"
  dst_port = "53"
  comment  = "Accept DNS"

  depends_on = [routeros_ip_firewall_filter.input_dhcp]
}

resource "routeros_ip_firewall_filter" "input_ntp" {
  chain    = "input"
  action   = "accept"
  protocol = "udp"
  dst_port = "123"
  comment  = "Accept NTP"

  depends_on = [routeros_ip_firewall_filter.input_dns]
}

resource "routeros_ip_firewall_filter" "input_ssh" {
  chain             = "input"
  action            = "accept"
  protocol          = "tcp"
  dst_port          = "22"
  in_interface_list = routeros_interface_list.zones["trusted"].name
  comment           = "Accept SSH from management"

  depends_on = [routeros_ip_firewall_filter.input_ntp]
}

resource "routeros_ip_firewall_filter" "input_https" {
  chain             = "input"
  action            = "accept"
  protocol          = "tcp"
  dst_port          = "443,8291,8729"
  in_interface_list = routeros_interface_list.zones["trusted"].name
  comment           = "Accept HTTPS/Winbox/API-SSL from management"

  depends_on = [routeros_ip_firewall_filter.input_ssh]
}

resource "routeros_ip_firewall_filter" "input_capsman" {
  chain             = "input"
  action            = "accept"
  protocol          = "udp"
  dst_port          = "5246-5247"
  in_interface_list = routeros_interface_list.zones["trusted"].name
  comment           = "Accept CAPsMAN from management"

  depends_on = [routeros_ip_firewall_filter.input_https]
}

resource "routeros_ip_firewall_filter" "input_drop_wan" {
  chain             = "input"
  action            = "drop"
  in_interface_list = routeros_interface_list.wan.name
  log               = true
  log_prefix        = "wan-input"
  comment           = "Drop WAN input"

  depends_on = [routeros_ip_firewall_filter.input_capsman]
}

resource "routeros_ip_firewall_filter" "input_drop_all" {
  chain   = "input"
  action  = "drop"
  comment = "Drop all other input"

  depends_on = [routeros_ip_firewall_filter.input_drop_wan]
}

# --- Forward chain ---
# Order: established → drop-invalid → trusted → home-internet →
#        home-iot → home-cctv → limited-internet → guest-internet → drop-all

resource "routeros_ip_firewall_filter" "forward_established" {
  chain            = "forward"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Accept established/related"

  depends_on = [
    routeros_interface_list_member.wan,
    routeros_interface_list_member.zone_members,
  ]
}

resource "routeros_ip_firewall_filter" "forward_drop_invalid" {
  chain            = "forward"
  action           = "drop"
  connection_state = "invalid"
  comment          = "Drop invalid"

  depends_on = [routeros_ip_firewall_filter.forward_established]
}

resource "routeros_ip_firewall_filter" "forward_isolated_drop_wan" {
  chain              = "forward"
  action             = "drop"
  in_interface_list  = routeros_interface_list.zones["isolated"].name
  out_interface_list = routeros_interface_list.wan.name
  comment            = "Isolated (CCTV): silently drop internet"

  depends_on = [routeros_ip_firewall_filter.forward_drop_invalid]
}

resource "routeros_ip_firewall_filter" "forward_trusted_any" {
  chain             = "forward"
  action            = "accept"
  in_interface_list = routeros_interface_list.zones["trusted"].name
  comment           = "Trusted: full access"

  depends_on = [routeros_ip_firewall_filter.forward_isolated_drop_wan]
}

resource "routeros_ip_firewall_filter" "forward_home_internet" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["home"].name
  out_interface_list = routeros_interface_list.wan.name
  comment            = "Home: internet access"

  depends_on = [routeros_ip_firewall_filter.forward_trusted_any]
}

resource "routeros_ip_firewall_filter" "forward_home_iot" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["home"].name
  out_interface_list = routeros_interface_list.zones["limited"].name
  comment            = "Home: access IoT/VoIP devices"

  depends_on = [routeros_ip_firewall_filter.forward_home_internet]
}

resource "routeros_ip_firewall_filter" "forward_home_cctv" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["home"].name
  out_interface_list = routeros_interface_list.zones["isolated"].name
  comment            = "Home: view CCTV cameras"

  depends_on = [routeros_ip_firewall_filter.forward_home_iot]
}

resource "routeros_ip_firewall_filter" "forward_limited_internet" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["limited"].name
  out_interface_list = routeros_interface_list.wan.name
  comment            = "Limited (IoT/VoIP): internet only"

  depends_on = [routeros_ip_firewall_filter.forward_home_cctv]
}

resource "routeros_ip_firewall_filter" "forward_guest_internet" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["guest"].name
  out_interface_list = routeros_interface_list.wan.name
  comment            = "Guest: internet only"

  depends_on = [routeros_ip_firewall_filter.forward_limited_internet]
}

resource "routeros_ip_firewall_filter" "forward_drop_all" {
  chain      = "forward"
  action     = "drop"
  log        = true
  log_prefix = "forward-drop"
  comment    = "Drop all other forward traffic"

  depends_on = [routeros_ip_firewall_filter.forward_guest_internet]
}
