# CAPsMAN — centralized WiFi management for hAP AX2 access points.
# SSIDs: HOME (VLAN 10), IOT (VLAN 30), CCTV (VLAN 50), GUEST (VLAN 100)

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

resource "routeros_wifi_datapath" "guest" {
  name             = "guest-ax"
  bridge           = "bridge1"
  vlan_id          = 100
  client_isolation = true
}

# --- Security profiles ---

resource "routeros_wifi_security" "home" {
  name                 = "home"
  authentication_types = ["wpa2-psk", "wpa3-psk"]
  ft                   = true
  ft_over_ds           = true
}

resource "routeros_wifi_security" "iot" {
  name                 = "iot"
  authentication_types = ["wpa2-psk"]
  ft                   = true
  ft_over_ds           = true
}

resource "routeros_wifi_security" "cctv" {
  name                 = "cctv"
  authentication_types = ["wpa2-psk", "wpa3-psk"]
  ft                   = true
  ft_over_ds           = true
}

# --- Configurations (SSID + datapath + security) ---

resource "routeros_wifi_configuration" "home" {
  name     = "home-ax"
  ssid     = "HOME"
  country  = "Germany"
  mode     = "ap"
  datapath = routeros_wifi_datapath.home.name
  security = routeros_wifi_security.home.name
}

resource "routeros_wifi_configuration" "iot" {
  name     = "iot-ax"
  ssid     = "IOT"
  country  = "Germany"
  mode     = "ap"
  datapath = routeros_wifi_datapath.iot.name
  security = routeros_wifi_security.iot.name
}

resource "routeros_wifi_configuration" "cctv" {
  name     = "cctv-ax"
  ssid     = "CCTV"
  country  = "Germany"
  mode     = "ap"
  datapath = routeros_wifi_datapath.cctv.name
  security = routeros_wifi_security.cctv.name
}

resource "routeros_wifi_configuration" "guest" {
  name    = "guest-ax"
  ssid    = "GUEST"
  country = "Germany"
  mode    = "ap"
  datapath = routeros_wifi_datapath.guest.name
}

# --- CAPsMAN ---

resource "routeros_wifi_capsman" "this" {
  enabled    = true
  interfaces = ["default"]
}

# --- Provisioning rules ---

resource "routeros_wifi_provisioning" "2ghz" {
  action               = "create-dynamic-enabled"
  master_configuration = routeros_wifi_configuration.home.name
  slave_configurations = join(",", [
    routeros_wifi_configuration.iot.name,
    routeros_wifi_configuration.cctv.name,
    routeros_wifi_configuration.guest.name,
  ])
  supported_bands = "2ghz-ax"
  name_format     = "2GHz ax wifi-%I"
}

resource "routeros_wifi_provisioning" "5ghz" {
  action               = "create-dynamic-enabled"
  master_configuration = routeros_wifi_configuration.home.name
  slave_configurations = routeros_wifi_configuration.guest.name
  supported_bands      = "5ghz-ax"
  name_format          = "5GHz ax wifi-%I"
}
