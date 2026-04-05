output "model" {
  description = "Device model from RouterOS system routerboard"
  value       = data.routeros_system_routerboard.this.model
}

output "management_vlan_interface" {
  description = "Name of the management VLAN interface"
  value       = routeros_interface_vlan.management.name
}

output "terraform_ssh_private_key_pem" {
  description = "Per-device SSH private key for the bootstrap Terraform user"
  value       = tls_private_key.terraform_ssh.private_key_pem
  sensitive   = true
}

output "terraform_ssh_public_key_openssh" {
  description = "Per-device SSH public key installed on the bootstrap Terraform user"
  value       = tls_private_key.terraform_ssh.public_key_openssh
}
