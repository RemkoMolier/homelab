variable "bridge_name" {
  description = "Name of the bridge interface"
  type        = string
  default     = "bridge1"
}

variable "vlans" {
  description = "Map of VLAN definitions (from locals)"
  type = map(object({
    id      = number
    name    = string
    comment = string
  }))
}

variable "ports" {
  description = "Map of port configurations"
  type = map(object({
    comment  = optional(string, "")
    disabled = optional(bool, false)
    vlans    = optional(list(number), [])  # Tagged VLAN IDs on this port
    pvid     = optional(number)            # Untagged VLAN (access port)
    bond     = optional(string)            # Bond group name (if member)
    l2mtu    = optional(number)
    speed    = optional(string)            # Force speed (e.g., "2.5G-baseX")
  }))
}

variable "bonds" {
  description = "Map of bond (LACP) groups"
  type = map(object({
    mode    = optional(string, "802.3ad")
    comment = optional(string, "")
    mtu     = optional(number)
    vlans   = optional(list(number), [])   # Tagged VLANs on the bond
    pvid    = optional(number)             # Untagged VLAN (if access bond)
  }))
  default = {}
}
