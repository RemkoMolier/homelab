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
  root_ca_cert_pem         = var.root_ca_cert_pem
  intermediate_ca_key_pem  = var.intermediate_ca_key_pem
  intermediate_ca_cert_pem = var.intermediate_ca_cert_pem
}

module "base" {
  source = "../../components/device-base"

  identity                  = var.name
  certificate_name          = "signed-cert"
  cert_pem                  = module.cert.cert_pem
  import_signed_certificate = true
  key_pem                   = module.cert.key_pem
  ca_cert_pem               = module.cert.ca_cert_pem
  import_ca_certificate     = true
  root_ca_cert_pem          = module.cert.root_ca_cert_pem
  import_root_certificate   = true
  dns_servers               = var.dns_servers
  manage_dns_settings       = false
  management_subnet         = var.management_subnet
  terraform_host            = var.terraform_host
  users                     = var.users
}

module "router" {
  source = "../../components/router"

  vlans              = var.vlans
  firewall_zones     = var.firewall_zones
  wan_interface      = var.wan_interface
  dns_servers        = var.dns_servers
  dns_static_records = var.dns_static_records
  dhcp_leases        = var.dhcp_leases

  depends_on = [module.base]
}

module "capsman" {
  source = "../../components/capsman-controller"

  wifi_passwords = var.wifi_passwords

  depends_on = [module.base]
}
