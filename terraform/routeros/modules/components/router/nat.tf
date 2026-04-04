# NAT — PPPoE masquerade for internet access.

resource "routeros_ip_firewall_nat" "masquerade" {
  chain         = "srcnat"
  action        = "masquerade"
  out_interface = var.wan_interface
  comment       = "Masquerade outbound traffic"
}
