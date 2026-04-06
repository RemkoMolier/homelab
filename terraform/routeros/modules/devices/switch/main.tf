# Device wrapper for bridge VLAN filtering switches.
# Composes: certificates + device-base + switch-bridge.
#
# The bootstrap .rsc script pre-configures the management VLAN (VLAN 1)
# with bridge VLAN filtering, so Terraform can apply the full config in
# a single pass without losing connectivity.

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
  management_subnet         = var.management_subnet
  terraform_host            = var.terraform_host
  terraform_user_name       = var.terraform_user_name
  admin_password            = var.admin_password
  users                     = var.users
  device_ip                 = var.ip
  default_route             = var.default_route
}

module "switch" {
  source = "../../components/switch-bridge"

  vlans         = var.vlans
  ports         = var.ports
  bonds         = var.bonds
  default_l2mtu = var.default_l2mtu

  ssh_host            = var.ip
  ssh_user            = var.terraform_user_name
  ssh_private_key_pem = module.base.terraform_ssh_private_key_pem

  depends_on = [module.base]
}
