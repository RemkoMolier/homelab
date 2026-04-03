# RouterOS management module — configures MikroTik devices via the routeros
# provider over HTTPS. Runs after the bootstrap module has ensured all
# devices are reachable.
#
# The provider uses the RB5009 as the default device. Additional devices
# are managed via provider aliases.

terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
  }
}

# Default provider — RB5009 (main router)
provider "routeros" {
  hosturl  = var.devices["rb5009"].hosturl
  username = var.devices["rb5009"].username
  password = var.devices["rb5009"].password
  insecure = var.devices["rb5009"].insecure
}

# TODO: Add provider aliases for additional devices:
#
# provider "routeros" {
#   alias    = "crs309"
#   hosturl  = var.devices["crs309"].hosturl
#   username = var.devices["crs309"].username
#   password = var.devices["crs309"].password
#   insecure = var.devices["crs309"].insecure
# }
#
# Then use: resource "routeros_..." "..." { provider = routeros.crs309 }

# TODO: Add device configuration resources here
#   - System identity, NTP, clock
#   - Services hardening (disable telnet, ftp, www, etc.)
#   - SSH strong crypto
#   - Firewall rules
#   - DNS records
#   - DHCP server/leases
#   - VLANs, bridge config
#   - CAPsMAN WiFi
#   - WireGuard
#   - BGP
