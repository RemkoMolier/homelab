# Decrypt SOPS-encrypted secrets at plan time.
# Only keys named "secrets" are encrypted (at any level).
# Device config (IPs, hosturls) is plaintext.

provider "sops" {}

data "sops_file" "config" {
  source_file = "${path.root}/terraform.tfvars.sops.json"
}

locals {
  config  = jsondecode(data.sops_file.config.raw)
  secrets = local.config["secrets"]

  # Device IPs extracted from device config
  device_ips = { for name, device in local.config["devices"] : name => device.ip }

  # Merge device config (plaintext) with credentials (encrypted per device)
  # into the routeros_devices map expected by provider blocks and modules.
  routeros_devices = {
    for name, device in local.config["devices"] : name => {
      hosturl        = device.hosturl
      insecure       = device.insecure
      bootstrap_ip   = device.bootstrap_ip
      username       = device.secrets.username
      password       = device.secrets.password
      bootstrap_user = device.secrets.bootstrap_user
      bootstrap_pass = device.secrets.bootstrap_pass
    }
  }

  wifi_passwords = local.secrets["wifi_passwords"]
}
