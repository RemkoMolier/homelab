# Device wrapper for the router (RB5009).
# Composes: certificates + device-base + router + capsman-controller.

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

module "router" {
  source = "../../components/router"

  vlans              = var.vlans
  firewall_zones     = var.firewall_zones
  wan_interface      = var.wan_interface
  dns_static_records = var.dns_static_records
  dhcp_leases        = var.dhcp_leases

  depends_on = [module.base]
}

module "capsman" {
  source = "../../components/capsman-controller"

  wifi_passwords = var.wifi_passwords

  depends_on = [module.base]
}
