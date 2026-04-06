variable "name" {
  description = "Device name (used as identity, DNS hostname, and certificate CN)"
  type        = string
}

variable "ip" {
  description = "Device management IP address"
  type        = string
}

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

variable "ssids" {
  description = "Map of WiFi SSID configurations"
  type = map(object({
    ssid                 = string
    vlan_id              = number
    authentication_types = optional(list(string), ["wpa2-psk", "wpa3-psk"])
    hide_ssid            = optional(bool, false)
    disabled             = optional(bool, false)
    client_isolation     = optional(bool, false)
    bands                = optional(list(string), ["2ghz-ax", "5ghz-ax"])
  }))
  default = {}
}

variable "master_ssid" {
  description = "Key from ssids map used as master configuration for provisioning"
  type        = string
  default     = "home"
}

variable "wifi_passwords" {
  description = "Map of WiFi PSK passwords by security profile name"
  type        = map(string)
  sensitive   = true
  default     = {}
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

variable "intermediate_ca_key_pem" {
  description = "Intermediate CA private key in PEM format"
  type        = string
  sensitive   = true
}

variable "intermediate_ca_cert_pem" {
  description = "Intermediate CA certificate in PEM format"
  type        = string
}

variable "root_ca_cert_pem" {
  description = "Root CA certificate in PEM format"
  type        = string
}

variable "management_subnet" {
  description = "Management subnet for restricting access"
  type        = string
  default     = "172.16.1.0/24"
}

variable "dns_servers" {
  description = "List of DNS servers used by the device"
  type        = list(string)
  default     = ["172.16.1.1"]
}

variable "terraform_host" {
  description = "Terraform workstation IP for api-ssl restriction"
  type        = string
  default     = "172.16.1.245/32"
}

variable "terraform_user_name" {
  description = "Bootstrap Terraform user that should receive an SSH public key"
  type        = string
  default     = "terraform"
}

variable "ports" {
  description = "Map of port configurations"
  type = map(object({
    comment  = optional(string, "")
    disabled = optional(bool, false)
    vlans    = optional(list(number), [])
    pvid     = optional(number)
    bond     = optional(string)
    bridge   = optional(bool, true)
    l2mtu    = optional(number)
    speed    = optional(string)
  }))
  default = {}
}

variable "bonds" {
  description = "Map of bond (LACP) groups"
  type = map(object({
    mode    = optional(string, "802.3ad")
    comment = optional(string, "")
    mtu     = optional(number)
    vlans   = optional(list(number), [])
    pvid    = optional(number)
  }))
  default = {}
}

variable "default_l2mtu" {
  description = "Default L2 MTU for all ports on this device"
  type        = number
  default     = null
}

variable "wan_interfaces" {
  description = "Map of WAN interfaces with DHCP client and/or masquerade"
  type = map(object({
    dhcp_client = optional(bool, true)
    masquerade  = optional(bool, true)
  }))
  default = {}
}

variable "users" {
  description = "Map of user accounts to create on the device"
  type = map(object({
    password = string
    group    = string
  }))
  default = {}
}
