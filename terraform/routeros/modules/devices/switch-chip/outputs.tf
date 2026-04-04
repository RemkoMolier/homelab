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

output "vlan_aware_ports" {
  description = "Set of all VLAN-aware ports (for drop-if-invalid enforcement)"
  value       = module.switch.vlan_aware_ports
}
