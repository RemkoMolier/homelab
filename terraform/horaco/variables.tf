variable "state_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "Passphrase must be at least 16 characters."
  }
}

variable "horaco_devices" {
  description = "Map of Horaco switches to manage"
  type = map(object({
    url      = string
    username = string
    password = string
  }))
  sensitive = true
}
