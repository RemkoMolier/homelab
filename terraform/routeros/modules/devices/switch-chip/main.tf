# Device wrapper for legacy switch-chip VLAN switches (CRS1xx/2xx).
# Composes: certificates + device-base + switch-chip.

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
  source = "../../components/switch-chip"

  vlans  = var.vlans
  ports  = var.ports
  trunks = var.trunks

  depends_on = [module.base]
}
