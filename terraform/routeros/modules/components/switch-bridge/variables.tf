variable "bridge_name" {
  description = "Name of the bridge interface"
  type        = string
  default     = "bridge1"
}

variable "vlans" {
  description = "Map of VLAN definitions (from locals)"
  type = map(object({
    id             = number
    name           = string
    comment        = string
    subnet         = optional(string)
    gateway        = optional(string)
    router_address = optional(string)
    pool           = optional(string)
  }))
}

variable "ports" {
  description = "Map of port configurations"
  type = map(object({
    comment  = optional(string, "")
    disabled = optional(bool, false)
    vlans    = optional(list(number), []) # Tagged VLAN IDs on this port
    pvid     = optional(number)           # Untagged VLAN (access port)
    bond     = optional(string)           # Bond group name (if member)
    bridge   = optional(bool, true)       # Include in bridge (false for WAN port)
    l2mtu    = optional(number)
    speed    = optional(string) # Force speed (e.g., "2.5G-baseX")
  }))
}

variable "bonds" {
  description = "Map of bond (LACP) groups"
  type = map(object({
    mode    = optional(string, "802.3ad")
    comment = optional(string, "")
    mtu     = optional(number)
    vlans   = optional(list(number), []) # Tagged VLANs on the bond
    pvid    = optional(number)           # Untagged VLAN (if access bond)
  }))
  default = {}
}


variable "bridge_frame_types" {
  description = "Frame types for the bridge interface. Use admit-all for CAPsMAN APs (wifi-qcom requires it for dynamic VLAN membership)."
  type        = string
  default     = "admit-only-vlan-tagged"
}

variable "default_l2mtu" {
  description = "Default L2 MTU for all ports (device-specific, overridden per port)"
  type        = number
  default     = null
}

variable "ssh_host" {
  description = "Mikrotik SSH Host"
  type        = string
}

variable "ssh_user" {
  description = "Mikrotik SSH User"
  type        = string
}

variable "ssh_private_key_pem" {
  description = "Mikrotik SSH Private Key"
  type        = string
  sensitive   = true
}
