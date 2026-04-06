variable "state_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2+AES-GCM)"
  type        = string
  sensitive   = true
}

variable "sops_age_key" {
  description = "Age private key for SOPS decryption in CI (from SOPS_AGE_KEY env var)"
  type        = string
  sensitive   = true
}
