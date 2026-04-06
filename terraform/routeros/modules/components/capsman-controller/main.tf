# CAPsMAN controller — centralized WiFi management.
# Defines SSIDs, security profiles, datapaths, and provisioning rules.
# Runs on the RB5009. APs use the capsman-client component to connect.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
  }
}

locals {
  secured_ssids = { for k, v in var.ssids : k => v if length(coalesce(v.authentication_types, [])) > 0 }
  bands         = toset(flatten([for ssid in var.ssids : coalesce(ssid.bands, [])]))
}

# --- Datapaths (map SSID to VLAN) ---

resource "routeros_wifi_datapath" "this" {
  for_each = var.ssids

  name             = "${each.key}-ax"
  bridge           = "bridge1"
  vlan_id          = each.value.vlan_id
  client_isolation = each.value.client_isolation
}

# --- Security profiles ---

resource "routeros_wifi_security" "this" {
  for_each = local.secured_ssids

  name                 = each.key
  authentication_types = each.value.authentication_types
  passphrase           = lookup(var.wifi_passwords, each.key, null)
  ft                   = false
  ft_over_ds           = false

  lifecycle {
    precondition {
      condition = (
        lookup(var.wifi_passwords, each.key, null) != null &&
        trimspace(lookup(var.wifi_passwords, each.key, "")) != ""
      )
      error_message = "SSID \"${each.key}\" has authentication_types configured, but no non-empty passphrase was provided in var.wifi_passwords. Either add a password for this SSID or set authentication_types = [] to leave it unsecured."
    }
  }
}

# --- Configurations (SSID + datapath + security) ---

resource "routeros_wifi_configuration" "this" {
  for_each = var.ssids

  name      = "${each.key}-ax"
  ssid      = each.value.ssid
  country   = var.country
  mode      = "ap"
  hide_ssid = each.value.hide_ssid
  disabled  = each.value.disabled
  datapath  = { config = routeros_wifi_datapath.this[each.key].name }
  security  = contains(keys(local.secured_ssids), each.key) ? { config = routeros_wifi_security.this[each.key].name } : null
}

# --- CAPsMAN service ---

resource "routeros_wifi_capsman" "this" {
  enabled        = true
  interfaces     = [var.discovery_interface]
  ca_certificate = "auto"
}

# --- Provisioning rules ---

resource "routeros_wifi_provisioning" "this" {
  for_each = local.bands

  action               = "create-dynamic-enabled"
  master_configuration = try(routeros_wifi_configuration.this[var.master_ssid].name, null)
  slave_configurations = [
    for k, v in var.ssids : routeros_wifi_configuration.this[k].name
    if contains(coalesce(v.bands, []), each.key) && k != var.master_ssid
  ]
  supported_bands = [each.key]
  name_format     = "${replace(each.key, "ghz-", "GHz ")} wifi-%I"

  lifecycle {
    precondition {
      condition     = contains(keys(var.ssids), var.master_ssid)
      error_message = "var.master_ssid must be the key of one of the entries in var.ssids."
    }
  }
}
