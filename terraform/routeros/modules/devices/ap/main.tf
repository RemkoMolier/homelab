# Device wrapper for CAPsMAN-managed WiFi access points.
# Composes: certificates + device-base + switch-bridge + capsman-client.

terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

module "cert" {
  source = "../../components/certificates"

  device_name              = var.name
  device_ip                = var.ip
  intermediate_ca_key_pem  = var.intermediate_ca_key_pem
  intermediate_ca_cert_pem = var.intermediate_ca_cert_pem
}

module "base" {
  source = "../../components/device-base"

  identity          = var.name
  ip                = var.ip
  certificate_name  = "api-cert"
  management_subnet = var.management_subnet
  terraform_host    = var.terraform_host
}

module "switch" {
  source = "../../components/switch-bridge"

  vlans = var.vlans
  ports = var.ports

  depends_on = [module.base]
}

module "capsman" {
  source = "../../components/capsman-client"

  depends_on = [module.switch]
}
