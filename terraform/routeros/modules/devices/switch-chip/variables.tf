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
    trunk    = optional(string)
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

variable "intermediate_ca_key_pem" {
  description = "Intermediate CA private key in PEM format"
  type        = string
  sensitive   = true
}

variable "intermediate_ca_cert_pem" {
  description = "Intermediate CA certificate in PEM format"
  type        = string
}

variable "management_subnet" {
  description = "Management subnet for restricting access"
  type        = string
  default     = "172.16.1.0/24"
}

variable "terraform_host" {
  description = "Terraform workstation IP for api-ssl restriction"
  type        = string
  default     = "172.16.1.245/32"
}
