# PXE boot — netboot.xyz for network-booting servers on the management VLAN.

resource "routeros_ip_dhcp_server_option" "pxe_bios" {
  name  = "pxe-bios-netboot.xyz"
  code  = 67
  value = "'netboot.xyz.kpxe'"
}

resource "routeros_ip_dhcp_server_option" "pxe_uefi" {
  name  = "pxe-uefi-netboot.xyz"
  code  = 67
  value = "'netboot.xyz.efi'"
}

resource "routeros_ip_dhcp_server_option_sets" "pxe_uefi" {
  name    = "pxe-uefi"
  options = routeros_ip_dhcp_server_option.pxe_uefi.name
}

resource "routeros_ip_dhcp_server_option_sets" "pxe_bios" {
  name    = "pxe-bios"
  options = routeros_ip_dhcp_server_option.pxe_bios.name
}
