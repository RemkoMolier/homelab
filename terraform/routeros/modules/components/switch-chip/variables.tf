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
    vlans    = optional(list(number), []) # Tagged VLAN IDs on this port
    pvid     = optional(number)           # Untagged VLAN (access port)
    trunk    = optional(string)           # Switch trunk group name (bond)
    l2mtu    = optional(number)
    speed    = optional(string) # Force speed (e.g., "2.5G-baseX")
  }))
}

variable "trunks" {
  description = "Map of switch trunk groups (hardware bonding)"
  type = map(object({
    comment = optional(string, "")
    members = list(string)
    vlans   = optional(list(number), [])
    pvid    = optional(number)
  }))
  default = {}
}

variable "default_l2mtu" {
  description = "Default L2 MTU for all ports (device-specific, overridden per port)"
  type        = number
  default     = null
}

variable "ssh_host" {
  description = "Device SSH host for managing switch trunk groups"
  type        = string
}

variable "ssh_user" {
  description = "Device SSH user"
  type        = string
}

variable "ssh_private_key_pem" {
  description = "SSH private key in PEM format"
  type        = string
  sensitive   = true
}
