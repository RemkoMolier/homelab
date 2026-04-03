# Router module — RB5009-specific configuration.
# Composes: firewall, NAT, DNS, DHCP, VRRP, CAPsMAN, PXE.

terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}
