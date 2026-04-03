variable "vlans" {
  description = "Map of VLAN definitions"
  type = map(object({
    id      = number
    name    = string
    comment = string
    subnet  = string
    gateway = string
    pool    = string
  }))
}

variable "firewall_zones" {
  description = "Map of firewall zone names to VLAN keys"
  type        = map(list(string))
}

variable "pppoe_interface" {
  description = "WAN interface for PPPoE"
  type        = string
  default     = "ether1"
}

variable "pppoe_user" {
  description = "PPPoE username"
  type        = string
  sensitive   = true
}

variable "dns_static_records" {
  description = "Map of static DNS records"
  type = map(object({
    address = string
    type    = optional(string, "A")
  }))
  default = {}
}

variable "dhcp_leases" {
  description = "Map of static DHCP leases"
  type = map(object({
    address     = string
    mac_address = string
    server      = string
    comment     = optional(string, "")
  }))
  default = {}
}
