variable "name" {
  description = "Device name (used as identity, DNS hostname, and certificate CN)"
  type        = string
}

variable "ip" {
  description = "Device management IP address"
  type        = string
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
    vlans    = optional(list(number), [])
    pvid     = optional(number)
    bond     = optional(string)
    l2mtu    = optional(number)
    speed    = optional(string)
  }))
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

variable "users" {
  description = "Map of user accounts to create on the device"
  type = map(object({
    password = string
    group    = string
  }))
  default = {}
}
