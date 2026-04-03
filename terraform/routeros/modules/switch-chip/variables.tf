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
    trunk    = optional(string)            # Switch trunk group name (bond)
    l2mtu    = optional(number)
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
