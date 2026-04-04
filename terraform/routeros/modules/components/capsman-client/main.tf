# CAPsMAN client component — configures WiFi radios to be managed by CAPsMAN.
# The controller (RB5009) pushes SSIDs, security, and datapaths via CAPsMAN.
# This component just enables the client side.

terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

resource "routeros_wifi_datapath" "cap" {
  name   = "cap"
  bridge = var.bridge_name
}

resource "routeros_wifi" "wifi1" {
  name                  = "wifi1"
  configuration_manager = "capsman"
  datapath              = routeros_wifi_datapath.cap.name
  disabled              = false
}

resource "routeros_wifi" "wifi2" {
  name                  = "wifi2"
  configuration_manager = "capsman"
  datapath              = routeros_wifi_datapath.cap.name
  disabled              = false
}

resource "routeros_wifi_cap" "this" {
  enabled              = true
  discovery_interfaces = [var.discovery_interface]
  slaves_datapath      = routeros_wifi_datapath.cap.name
}
