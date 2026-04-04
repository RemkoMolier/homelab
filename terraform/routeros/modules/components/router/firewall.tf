# Zone-based firewall rules for the RB5009.
#
# Zones:
#   trusted  (management)  — full access to everything
#   home     (home)        — internet + IoT + CCTV
#   limited  (iot, voip)   — internet only, no lateral movement
#   isolated (cctv)        — fully isolated, no internet
#   guest    (guest)       — internet only, client-isolated

# --- Interface lists for firewall zones ---

resource "routeros_interface_list" "wan" {
  name = "wan"
}

resource "routeros_interface_list_member" "wan_ether1" {
  interface = var.wan_interface
  list      = routeros_interface_list.wan.name
}

resource "routeros_interface_list" "zones" {
  for_each = var.firewall_zones
  name     = each.key
}

resource "routeros_interface_list_member" "zone_members" {
  for_each = merge([
    for zone, vlan_keys in var.firewall_zones : {
      for vlan_key in vlan_keys :
      "${zone}-${vlan_key}" => {
        list      = zone
        interface = var.vlans[vlan_key].name
      }
    }
  ]...)

  list      = routeros_interface_list.zones[each.value.list].name
  interface = each.value.interface
}

# --- Input chain ---

resource "routeros_ip_firewall_filter" "input_established" {
  chain            = "input"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Accept established/related"
}

resource "routeros_ip_firewall_filter" "input_drop_invalid" {
  chain            = "input"
  action           = "drop"
  connection_state = "invalid"
  comment          = "Drop invalid"
  place_before     = routeros_ip_firewall_filter.input_icmp.id
}

resource "routeros_ip_firewall_filter" "input_icmp" {
  chain    = "input"
  action   = "accept"
  protocol = "icmp"
  comment  = "Accept ICMP"
}

resource "routeros_ip_firewall_filter" "input_dhcp" {
  chain        = "input"
  action       = "accept"
  protocol     = "udp"
  dst_port     = "67-68"
  comment      = "Accept DHCP"
  place_before = routeros_ip_firewall_filter.input_dns.id
}

resource "routeros_ip_firewall_filter" "input_dns" {
  chain        = "input"
  action       = "accept"
  protocol     = "udp"
  dst_port     = "53"
  comment      = "Accept DNS"
  place_before = routeros_ip_firewall_filter.input_ntp.id
}

resource "routeros_ip_firewall_filter" "input_ntp" {
  chain        = "input"
  action       = "accept"
  protocol     = "udp"
  dst_port     = "123"
  comment      = "Accept NTP"
  place_before = routeros_ip_firewall_filter.input_capsman.id
}

resource "routeros_ip_firewall_filter" "input_capsman" {
  chain             = "input"
  action            = "accept"
  protocol          = "udp"
  dst_port          = "5246-5247"
  in_interface_list = routeros_interface_list.zones["trusted"].name
  comment           = "Accept CAPsMAN from management"
  place_before      = routeros_ip_firewall_filter.input_drop_wan.id
}

resource "routeros_ip_firewall_filter" "input_drop_wan" {
  chain             = "input"
  action            = "drop"
  in_interface_list = routeros_interface_list.wan.name
  log               = true
  log_prefix        = "wan-input"
  comment           = "Drop WAN input"
  place_before      = routeros_ip_firewall_filter.input_drop_all.id
}

resource "routeros_ip_firewall_filter" "input_drop_all" {
  chain   = "input"
  action  = "drop"
  comment = "Drop all other input"
}

# --- Forward chain ---

resource "routeros_ip_firewall_filter" "forward_established" {
  chain            = "forward"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Accept established/related"
}

resource "routeros_ip_firewall_filter" "forward_drop_invalid" {
  chain            = "forward"
  action           = "drop"
  connection_state = "invalid"
  comment          = "Drop invalid"
  place_before     = routeros_ip_firewall_filter.forward_trusted_any.id
}

resource "routeros_ip_firewall_filter" "forward_trusted_any" {
  chain             = "forward"
  action            = "accept"
  in_interface_list = routeros_interface_list.zones["trusted"].name
  comment           = "Trusted: full access"
  place_before      = routeros_ip_firewall_filter.forward_home_internet.id
}

resource "routeros_ip_firewall_filter" "forward_home_internet" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["home"].name
  out_interface_list = routeros_interface_list.wan.name
  comment            = "Home: internet access"
  place_before       = routeros_ip_firewall_filter.forward_home_iot.id
}

resource "routeros_ip_firewall_filter" "forward_home_iot" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["home"].name
  out_interface_list = routeros_interface_list.zones["limited"].name
  comment            = "Home: access IoT/VoIP devices"
  place_before       = routeros_ip_firewall_filter.forward_home_cctv.id
}

resource "routeros_ip_firewall_filter" "forward_home_cctv" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["home"].name
  out_interface_list = routeros_interface_list.zones["isolated"].name
  comment            = "Home: view CCTV cameras"
  place_before       = routeros_ip_firewall_filter.forward_limited_internet.id
}

resource "routeros_ip_firewall_filter" "forward_limited_internet" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["limited"].name
  out_interface_list = routeros_interface_list.wan.name
  comment            = "Limited (IoT/VoIP): internet only"
  place_before       = routeros_ip_firewall_filter.forward_guest_internet.id
}

resource "routeros_ip_firewall_filter" "forward_guest_internet" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = routeros_interface_list.zones["guest"].name
  out_interface_list = routeros_interface_list.wan.name
  comment            = "Guest: internet only"
  place_before       = routeros_ip_firewall_filter.forward_drop_all.id
}

resource "routeros_ip_firewall_filter" "forward_drop_all" {
  chain      = "forward"
  action     = "drop"
  log        = true
  log_prefix = "forward-drop"
  comment    = "Drop all other forward traffic"
}
