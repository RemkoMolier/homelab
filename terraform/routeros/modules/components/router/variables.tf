variable "vlans" {
  description = "Map of VLAN definitions"
  type = map(object({
    id             = number
    name           = string
    comment        = string
    subnet         = string
    gateway        = string
    router_address = string
    pool           = string
  }))
}

variable "firewall_zones" {
  description = "Map of firewall zone names to VLAN keys"
  type        = map(list(string))
}

variable "wan_interfaces" {
  description = "Map of WAN interfaces (keys are interface names)"
  type        = map(any)
}

variable "dns_static_records" {
  description = "Map of static DNS records"
  type = map(object({
    address = string
    type    = optional(string, "A")
  }))
  default = {}
}

variable "ssh_host" {
  description = "Device SSH host"
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

variable "management_interface" {
  description = "Name of the management VLAN interface (created by device-base)"
  type        = string
  default     = "mgmt"
}

variable "bridge_name" {
  description = "Name of the bridge interface for VLAN sub-interfaces"
  type        = string
  default     = "bridge1"
}

variable "management_dhcp_server" {
  description = "Name of the management DHCP server (for PXE matcher)"
  type        = string
  default     = "management"
}

variable "management_pool" {
  description = "Name of the management IP pool (for PXE matcher)"
  type        = string
  default     = "management"
}

variable "management_subnet" {
  description = "Management subnet CIDR (for TFTP access restriction)"
  type        = string
  default     = "172.16.1.0/24"
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
