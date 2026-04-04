output "cert_pem" {
  description = "The signed device certificate in PEM format"
  value       = tls_locally_signed_cert.this.cert_pem
}

output "key_pem" {
  description = "The device private key in PEM format"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}

output "ca_cert_pem" {
  description = "The intermediate CA certificate in PEM format"
  value       = var.intermediate_ca_cert_pem
}

output "root_ca_cert_pem" {
  description = "The root CA certificate in PEM format"
  value       = var.root_ca_cert_pem
}
