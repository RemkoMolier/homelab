# MikroTik RouterOS infrastructure
#
# Two-phase approach:
#   1. Bootstrap module — checks device reachability, provisions fresh devices
#      via plain HTTP REST API (no routeros provider needed)
#   2. RouterOS module — manages device configuration via the routeros provider
#      over HTTPS (depends on bootstrap completing)
#
# Certificates are issued by the intermediate CA (pki/intermediate-ca/) using
# the tls provider. The CA keys are decrypted transparently by git-crypt.

locals {
  pki_dir = "${path.root}/../../pki"
}

module "bootstrap" {
  source  = "./modules/bootstrap"
  devices = var.routeros_devices
}

module "routeros" {
  source     = "./modules/routeros"
  devices    = var.routeros_devices

  intermediate_ca_key_pem  = file("${local.pki_dir}/intermediate-ca/ca.key")
  intermediate_ca_cert_pem = file("${local.pki_dir}/intermediate-ca/ca.crt")
  root_ca_cert_pem         = file("${local.pki_dir}/root-ca/ca.crt")

  depends_on = [module.bootstrap]
}
