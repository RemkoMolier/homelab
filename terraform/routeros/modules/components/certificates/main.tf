# Certificate module — issues a TLS certificate for a single device,
# signed by the intermediate CA.

terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }
  }
}

resource "tls_private_key" "this" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "${var.device_name}.${var.domain}"
    organization = "molier.net"
  }

  ip_addresses = [var.device_ip]
}

resource "tls_locally_signed_cert" "this" {
  cert_request_pem   = tls_cert_request.this.cert_request_pem
  ca_private_key_pem = var.intermediate_ca_key_pem
  ca_cert_pem        = var.intermediate_ca_cert_pem

  validity_period_hours = var.validity_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
