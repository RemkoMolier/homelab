# MikroTik RouterOS infrastructure
#
# Two-phase approach:
#   1. Bootstrap module — checks device reachability, provisions fresh devices
#      via plain HTTP REST API (no routeros provider needed)
#   2. RouterOS module — manages device configuration via the routeros provider
#      over HTTPS (depends on bootstrap completing)

module "bootstrap" {
  source  = "./modules/bootstrap"
  devices = var.routeros_devices
}

module "routeros" {
  source     = "./modules/routeros"
  devices    = var.routeros_devices
  depends_on = [module.bootstrap]
}
