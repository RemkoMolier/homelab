variable "state_passphrase" {
  description = "Passphrase for OpenTofu state encryption (PBKDF2)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "Passphrase must be at least 16 characters."
  }
}

# All other config and secrets are in terraform.tfvars.sops.json:
#   - Device IPs and hosturls are plaintext
#   - Credentials and passwords are under the "secrets" key (SOPS-encrypted)
# Decrypted via the sops provider in secrets.tf.
# Access via: local.device_ips, local.routeros_devices, local.wifi_passwords
