# Device wrapper for legacy switch-chip VLAN switches (CRS1xx/2xx).
# Composes: certificates + device-base + switch-chip.

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
  users                     = var.users
}

module "switch" {
  source = "../../components/switch-chip"

  vlans  = var.vlans
  ports  = var.ports
  trunks = var.trunks

  depends_on = [module.base]
}

# Move the management IP from bridge1 (bootstrap) to the mgmt VLAN interface.
# This must happen AFTER the switch-chip VLAN config is applied, because
# the mgmt interface needs VLAN 1 on switch1-cpu to receive traffic.
resource "routeros_ip_address" "management" {
  address   = "${var.ip}/24"
  interface = "mgmt"
  comment   = "Management"

  depends_on = [module.switch]
}
