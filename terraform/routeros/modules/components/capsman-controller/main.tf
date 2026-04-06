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

# --- Datapaths (map SSID to VLAN) ---

resource "routeros_wifi_datapath" "home" {
  name    = "home-ax"
  bridge  = "bridge1"
  vlan_id = 10
}

resource "routeros_wifi_datapath" "iot" {
  name    = "iot-ax"
  bridge  = "bridge1"
  vlan_id = 30
}

resource "routeros_wifi_datapath" "cctv" {
  name    = "cctv-ax"
  bridge  = "bridge1"
  vlan_id = 50
}

resource "routeros_wifi_datapath" "voip" {
  name    = "voip-ax"
  bridge  = "bridge1"
  vlan_id = 40
}

resource "routeros_wifi_datapath" "guest" {
  name             = "guest-ax"
  bridge           = "bridge1"
  vlan_id          = 100
  client_isolation = true
}

resource "routeros_wifi_datapath" "mgmt" {
  name    = "mgmt-ax"
  bridge  = "bridge1"
  vlan_id = 1
}

# --- Security profiles ---

resource "routeros_wifi_security" "home" {
  name                 = "home"
  authentication_types = ["wpa2-psk", "wpa3-psk"]
  passphrase           = lookup(var.wifi_passwords, "home", null)
  ft                   = false
  ft_over_ds           = false
}

resource "routeros_wifi_security" "iot" {
  name                 = "iot"
  authentication_types = ["wpa2-psk"]
  passphrase           = lookup(var.wifi_passwords, "iot", null)
  ft                   = false
  ft_over_ds           = false
}

resource "routeros_wifi_security" "voip" {
  name                 = "voip"
  authentication_types = ["wpa2-psk", "wpa3-psk"]
  passphrase           = lookup(var.wifi_passwords, "voip", null)
  ft                   = false
  ft_over_ds           = false
}

resource "routeros_wifi_security" "cctv" {
  name                 = "cctv"
  authentication_types = ["wpa2-psk", "wpa3-psk"]
  passphrase           = lookup(var.wifi_passwords, "cctv", null)
  ft                   = false
  ft_over_ds           = false
}

resource "routeros_wifi_security" "mgmt" {
  name                 = "mgmt"
  authentication_types = ["wpa2-psk", "wpa3-psk"]
  passphrase           = lookup(var.wifi_passwords, "mgmt", null)
  ft                   = false
  ft_over_ds           = false
}

# --- Configurations (SSID + datapath + security) ---

resource "routeros_wifi_configuration" "home" {
  name     = "home-ax"
  ssid     = "HOME"
  country  = var.country
  mode     = "ap"
  datapath = { config = routeros_wifi_datapath.home.name }
  security = { config = routeros_wifi_security.home.name }
}

resource "routeros_wifi_configuration" "iot" {
  name     = "iot-ax"
  ssid     = "IOT"
  country  = var.country
  mode     = "ap"
  datapath = { config = routeros_wifi_datapath.iot.name }
  security = { config = routeros_wifi_security.iot.name }
}

resource "routeros_wifi_configuration" "cctv" {
  name     = "cctv-ax"
  ssid     = "CCTV"
  country  = var.country
  mode     = "ap"
  datapath = { config = routeros_wifi_datapath.cctv.name }
  security = { config = routeros_wifi_security.cctv.name }
}

resource "routeros_wifi_configuration" "voip" {
  name     = "voip-ax"
  ssid     = "VOIP"
  country  = var.country
  mode     = "ap"
  disabled = true
  datapath = { config = routeros_wifi_datapath.voip.name }
  security = { config = routeros_wifi_security.voip.name }
}

resource "routeros_wifi_configuration" "guest" {
  name     = "guest-ax"
  ssid     = "GUEST"
  country  = var.country
  mode     = "ap"
  disabled = true
  datapath = { config = routeros_wifi_datapath.guest.name }
}

resource "routeros_wifi_configuration" "mgmt" {
  name      = "mgmt-ax"
  ssid      = "MGMT"
  country   = var.country
  mode      = "ap"
  hide_ssid = true
  datapath  = { config = routeros_wifi_datapath.mgmt.name }
  security  = { config = routeros_wifi_security.mgmt.name }
}

# --- CAPsMAN service ---

resource "routeros_wifi_capsman" "this" {
  enabled        = true
  interfaces     = [var.discovery_interface]
  ca_certificate = "auto"
}

# --- Provisioning rules ---

resource "routeros_wifi_provisioning" "band_2ghz" {
  action               = "create-dynamic-enabled"
  master_configuration = routeros_wifi_configuration.home.name
  slave_configurations = [
    routeros_wifi_configuration.iot.name,
    routeros_wifi_configuration.voip.name,
    routeros_wifi_configuration.cctv.name,
    routeros_wifi_configuration.guest.name,
    routeros_wifi_configuration.mgmt.name,
  ]
  supported_bands = ["2ghz-ax"]
  name_format     = "2GHz ax wifi-%I"
}

resource "routeros_wifi_provisioning" "band_5ghz" {
  action               = "create-dynamic-enabled"
  master_configuration = routeros_wifi_configuration.home.name
  slave_configurations = [
    routeros_wifi_configuration.guest.name,
    routeros_wifi_configuration.mgmt.name,
  ]
  supported_bands = ["5ghz-ax"]
  name_format     = "5GHz ax wifi-%I"
}
