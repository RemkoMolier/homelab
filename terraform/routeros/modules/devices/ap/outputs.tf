output "model" {
  description = "Device model from RouterOS"
  value       = module.base.model
}

output "cert_pem" {
  description = "Device certificate in PEM format"
  value       = module.cert.cert_pem
}

output "key_pem" {
  description = "Device private key in PEM format"
  value       = module.cert.key_pem
  sensitive   = true
}

output "terraform_ssh_private_key_pem" {
  description = "Per-device SSH private key for the bootstrap Terraform user"
  value       = module.base.terraform_ssh_private_key_pem
  sensitive   = true
}
