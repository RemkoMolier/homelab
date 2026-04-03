variable "devices" {
  description = "Map of MikroTik devices to manage"
  type = map(object({
    hosturl        = string
    username       = string
    password       = string
    insecure       = optional(bool, false)
    bootstrap_ip   = optional(string)
    bootstrap_user = optional(string, "admin")
    bootstrap_pass = optional(string, "")
  }))
  sensitive = true
}

variable "intermediate_ca_key_pem" {
  description = "Intermediate CA private key in PEM format (from git-crypt)"
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
