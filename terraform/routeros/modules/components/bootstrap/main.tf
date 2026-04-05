# Bootstrap module — generates .rsc scripts for MikroTik device provisioning.
#
# For each device, generates a bootstrap.rsc from a template and writes it
# to work/{device}/bootstrap.rsc. The user uploads this to the device and runs:
#   /system/reset-configuration run-after-reset=bootstrap.rsc
#
# The .rsc script sets up the bare minimum for Terraform to connect:
#   1. Bridge with all ports
#   2. Management IP on the mgmt VLAN interface
#   3. Terraform user group and user
#   4. Self-signed certificate for www-ssl and api-ssl
#   5. Restrict enabled services to the management subnet
#   6. Default gateway
#
# After reset, the routeros provider connects over HTTPS.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
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

# Generate the bootstrap .rsc script for each device.
locals {
  bootstrap_scripts = {
    for k, v in var.devices : k => templatefile("${path.module}/templates/bootstrap.rsc.tftpl", {
      device_name          = k
      device_ip            = v.ip
      prefix_length        = v.prefix_length
      management_subnet    = v.management_subnet
      gateway              = v.gateway
      tf_user              = v.username
      tf_pass              = v.password
      bridge_protocol_mode = v.bridge_protocol_mode
      vlan_mode            = v.vlan_mode
    })
  }
}

# Write the bootstrap script to work/{device}/bootstrap.rsc for each device.
resource "local_sensitive_file" "bootstrap" {
  for_each = var.devices

  content         = local.bootstrap_scripts[each.key]
  filename        = "${path.root}/../../work/bootstrap/${each.key}/bootstrap.rsc"
  file_permission = "0600"
}
