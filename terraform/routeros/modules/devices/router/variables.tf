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

variable "wan_interface" {
  description = "WAN interface"
  type        = string
  default     = "ether1"
}

variable "users" {
  description = "Map of user accounts to create on the device"
  type = map(object({
    password = string
    group    = string
  }))
  default = {}
}
