variable "devices" {
  description = "Map of MikroTik devices to bootstrap"
  type = map(object({
    hosturl              = string
    username             = string
    password             = string
    insecure             = optional(bool, false)
    ip                   = string
    prefix_length        = optional(number, 24)
    management_subnet    = optional(string, "172.16.1.0/24")
    gateway              = optional(string, "172.16.1.1")
    bridge_protocol_mode = optional(string, "rstp")
    vlan_mode            = optional(string, "bridge") # "bridge" or "switch-chip"
  }))
}
