variable "state_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2+AES-GCM)"
  type        = string
  sensitive   = true
}
