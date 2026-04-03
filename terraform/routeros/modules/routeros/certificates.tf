# Device certificates — issued by the intermediate CA for each MikroTik device.
# The tls provider generates keys and signs certificates locally.
# The routeros provider imports them to the devices.

terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Generate a private key for each device
resource "tls_private_key" "device" {
  for_each  = var.devices
  algorithm = "ECDSA"
  ecdsa_curve = "P256"
}

# Create a CSR for each device
resource "tls_cert_request" "device" {
  for_each        = var.devices
  private_key_pem = tls_private_key.device[each.key].private_key_pem

  subject {
    common_name  = "${each.key}.home.molier.net"
    organization = "molier.net"
  }

  ip_addresses = [
    regex("https?://([^:/]+)", each.value.hosturl)[0]
  ]
}

# Sign the CSR with the intermediate CA
resource "tls_locally_signed_cert" "device" {
  for_each           = var.devices
  cert_request_pem   = tls_cert_request.device[each.key].cert_request_pem
  ca_private_key_pem = var.intermediate_ca_key_pem
  ca_cert_pem        = var.intermediate_ca_cert_pem

  validity_period_hours = 17520 # 2 years

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
