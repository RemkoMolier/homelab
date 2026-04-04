# Device base module — common configuration applied to every MikroTik device.
# Handles system identity, clock, NTP, service hardening, and access control.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
  }
}

# --- System info ---

data "routeros_system_routerboard" "this" {}


# --- System ---

resource "routeros_system_identity" "this" {
  name = var.identity
}

resource "routeros_system_clock" "this" {
  time_zone_name = var.timezone
}

resource "routeros_system_ntp_client" "this" {
  enabled = true
  servers = var.ntp_servers
}

resource "routeros_ip_dns" "this" {
  count   = var.manage_dns_settings ? 1 : 0
  servers = var.dns_servers
}

# --- Services ---

resource "routeros_ip_service" "ssh" {
  numbers  = "ssh"
  port     = 22
  disabled = false
  address  = var.management_subnet
}

resource "routeros_ip_service" "winbox" {
  numbers  = "winbox"
  port     = 8291
  disabled = false
  address  = var.management_subnet
}

resource "routeros_ip_service" "api_ssl" {
  numbers     = "api-ssl"
  port        = 8729
  disabled    = false
  address     = var.terraform_host
  certificate = var.certificate_name

  depends_on = [
    routeros_system_certificate.signed_cert,
    routeros_system_certificate.ca,
  ]
}

resource "routeros_ip_service" "www_ssl" {
  numbers     = "www-ssl"
  port        = 443
  disabled    = false
  certificate = var.certificate_name

  depends_on = [
    routeros_system_certificate.signed_cert,
    routeros_system_certificate.ca,
  ]
}

resource "routeros_ip_service" "ftp" {
  numbers  = "ftp"
  port     = 21
  disabled = true
}

resource "routeros_ip_service" "telnet" {
  numbers  = "telnet"
  port     = 23
  disabled = true
}

resource "routeros_ip_service" "www" {
  numbers  = "www"
  port     = 80
  disabled = true
}

resource "routeros_ip_service" "api" {
  numbers  = "api"
  port     = 8728
  disabled = true
}

# --- User groups ---

locals {
  # "full" is a built-in RouterOS group — use it directly, don't create it
  builtin_groups = toset(["full", "read", "write"])
  custom_group_policies = {
    read-only = toset(["local", "ssh", "read", "winbox", "api", "rest-api"])
  }
  custom_groups = nonsensitive(toset([for u in var.users : u.group if !contains(local.builtin_groups, u.group)]))
}

resource "routeros_system_user_group" "groups" {
  for_each = local.custom_groups

  name   = each.value
  policy = local.custom_group_policies[each.value]
}

# --- User accounts ---

resource "routeros_system_user" "users" {
  for_each = nonsensitive(var.users)

  name     = each.key
  group    = each.value.group
  password = each.value.password
}

# --- Management VLAN interface ---
# On CRS1xx/2xx with switch-chip VLANs, the switch chip delivers tagged
# VLAN 1 traffic to the CPU via switch1-cpu. A VLAN interface on the bridge
# decapsulates it so the CPU can process management traffic.
#
# Bootstrap creates the IP on bridge1 (works without VLAN config).
# Terraform creates the mgmt VLAN interface here; the IP is moved to it
# by the device composition AFTER switch-chip VLANs are fully applied.

resource "routeros_interface_vlan" "management" {
  name      = "mgmt"
  vlan_id   = var.management_vlan_id
  interface = var.management_interface
  comment   = "Management VLAN"
}

# --- CA-signed certificate ---
# Import the CA-signed certificate directly into the RouterOS certificate
# store, replacing the bootstrap self-signed cert for api-ssl and www-ssl.

resource "routeros_system_certificate" "signed_cert" {
  count       = var.import_signed_certificate ? 1 : 0
  name        = var.certificate_name
  common_name = "${var.identity}.${var.domain}"
  import {
    cert_file_content = var.cert_pem
    key_file_content  = var.key_pem
  }

  depends_on = [routeros_system_certificate.ca]
}

resource "routeros_system_certificate" "ca" {
  count       = var.import_ca_certificate ? 1 : 0
  name        = "intermediate-ca"
  common_name = "Homelab Intermediate CA"
  import {
    cert_file_content = var.ca_cert_pem
  }

  depends_on = [routeros_system_certificate.root_ca]
}

resource "routeros_system_certificate" "root_ca" {
  count       = var.import_root_certificate ? 1 : 0
  name        = "root-ca"
  common_name = "Homelab Root CA"
  import {
    cert_file_content = var.root_ca_cert_pem
  }
}

# --- SSH hardening ---

resource "routeros_ip_ssh_server" "this" {
  strong_crypto = true
}

# --- Discovery and MAC server ---

resource "routeros_interface_list" "management" {
  name = "management"
}

resource "routeros_interface_list_member" "management_default" {
  interface = routeros_interface_vlan.management.name
  list      = routeros_interface_list.management.name
}

resource "routeros_tool_mac_server" "this" {
  allowed_interface_list = routeros_interface_list.management.name
}

resource "routeros_tool_mac_server_winbox" "this" {
  allowed_interface_list = routeros_interface_list.management.name
}

resource "routeros_ip_neighbor_discovery_settings" "this" {
  discover_interface_list = routeros_interface_list.management.name
}
