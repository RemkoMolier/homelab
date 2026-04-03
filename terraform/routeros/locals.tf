# Shared definitions used across all device modules.
# Change VLANs or firewall zones here — all devices pick up the changes.

locals {
  pki_dir = "${path.root}/../../pki"

  vlans = {
    management = {
      id      = 1
      name    = "default"
      comment = "Management"
      subnet  = "172.16.1.0/24"
      gateway = "172.16.1.1"
      pool    = "172.16.1.200-172.16.1.249"
    }
    home = {
      id      = 10
      name    = "home"
      comment = "Home"
      subnet  = "172.16.10.0/24"
      gateway = "172.16.10.1"
      pool    = "172.16.10.100-172.16.10.249"
    }
    iot = {
      id      = 30
      name    = "iot"
      comment = "IoT"
      subnet  = "172.16.30.0/24"
      gateway = "172.16.30.1"
      pool    = "172.16.30.100-172.16.30.249"
    }
    voip = {
      id      = 40
      name    = "voip"
      comment = "VoIP"
      subnet  = "172.16.40.0/24"
      gateway = "172.16.40.1"
      pool    = "172.16.40.100-172.16.40.249"
    }
    cctv = {
      id      = 50
      name    = "cctv"
      comment = "CCTV"
      subnet  = "192.168.1.0/24"
      gateway = "192.168.1.1"
      pool    = "192.168.1.100-192.168.1.249"
    }
    guest = {
      id      = 100
      name    = "guest"
      comment = "Guest"
      subnet  = "10.1.0.0/24"
      gateway = "10.1.0.1"
      pool    = "10.1.0.10-10.1.0.249"
    }
  }

  # All VLAN IDs for trunk ports
  all_vlan_ids = [for v in local.vlans : v.id]

  # Firewall zones — used by the router module to build interface lists
  firewall_zones = {
    trusted  = ["management"]         # Full access to everything
    home     = ["home"]               # Internet + IoT + CCTV
    limited  = ["iot", "voip"]        # Internet only, no lateral movement
    isolated = ["cctv"]               # Fully isolated, no internet
    guest    = ["guest"]              # Internet only, client-isolated
  }
}
