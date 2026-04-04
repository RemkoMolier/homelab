# Bootstrap module — prepares fresh MikroTik devices for Terraform management.
#
# For each device, checks if the HTTPS API is reachable. If not, and a
# bootstrap_ip is configured, provisions the device via the plain HTTP REST
# API (which is enabled by default on factory-reset devices).
#
# Bootstrap steps:
#   1. Create the terraform user group and user
#   2. Generate a self-signed certificate for api-ssl
#   3. Enable api-ssl, disable www (plain HTTP)
#
# After bootstrap, the routeros provider can connect over HTTPS.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

# Check if each device is already reachable on its HTTPS API endpoint.
data "external" "device_status" {
  for_each = var.devices
  program  = ["bash", "${path.module}/scripts/check-device.sh"]

  query = {
    hosturl  = each.value.hosturl
    username = each.value.username
    password = each.value.password
  }
}

# Bootstrap devices that are not yet reachable on HTTPS.
# Only runs for devices that have a bootstrap_ip configured and are not yet
# bootstrapped. The resource is stored in state, so it only runs once per
# device. To re-bootstrap a reset device, taint this resource.
resource "terraform_data" "bootstrap" {
  for_each = {
    for k, v in var.devices : k => v
    if v.bootstrap_ip != null && data.external.device_status[k].result.reachable == "false"
  }

  input = each.key

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/bootstrap-device.sh"

    environment = {
      BOOTSTRAP_IP   = each.value.bootstrap_ip
      BOOTSTRAP_USER = each.value.bootstrap_user
      BOOTSTRAP_PASS = each.value.bootstrap_pass
      TF_USER        = each.value.username
      TF_PASS        = each.value.password
      DEVICE_NAME    = each.key
    }
  }
}
