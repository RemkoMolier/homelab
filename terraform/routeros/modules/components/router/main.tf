# Router module — RB5009-specific configuration.
# Composes: firewall, NAT, DNS, DHCP, VRRP, CAPsMAN, PXE.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
  }
}
