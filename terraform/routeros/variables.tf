variable "state_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "Passphrase must be at least 16 characters."
  }
}

variable "routeros_devices" {
  description = "Map of MikroTik devices to manage"
  type = map(object({
    hosturl       = string
    username      = string
    password      = string
    insecure      = optional(bool, false)
    bootstrap_ip  = optional(string)
    bootstrap_user = optional(string, "admin")
    bootstrap_pass = optional(string, "")
  }))
  sensitive = true
}
