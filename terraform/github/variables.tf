variable "state_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2+AES-GCM)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "Passphrase must be at least 16 characters."
  }
}
