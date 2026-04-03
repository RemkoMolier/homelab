# Device base module — common configuration applied to every MikroTik device.
# Handles system identity, clock, NTP, service hardening, and access control.

terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

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

# --- Services ---

resource "routeros_ip_service" "ssh" {
  numbers  = "ssh"
  disabled = false
  address  = var.management_subnet
}

resource "routeros_ip_service" "winbox" {
  numbers  = "winbox"
  disabled = false
  address  = var.management_subnet
}

resource "routeros_ip_service" "api_ssl" {
  numbers     = "api-ssl"
  disabled    = false
  address     = var.terraform_host
  certificate = var.certificate_name
}

resource "routeros_ip_service" "ftp" {
  numbers  = "ftp"
  disabled = true
}

resource "routeros_ip_service" "telnet" {
  numbers  = "telnet"
  disabled = true
}

resource "routeros_ip_service" "www" {
  numbers  = "www"
  disabled = true
}

resource "routeros_ip_service" "api" {
  numbers  = "api"
  disabled = true
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
  interface = "default"
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
