# Device wrapper for bridge VLAN filtering switches.
# Composes: certificates + device-base + switch-bridge.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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
  bonds = var.bonds

  depends_on = [module.base]
}
