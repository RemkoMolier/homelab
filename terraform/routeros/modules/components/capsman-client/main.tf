# CAPsMAN client component — configures WiFi radios to be managed by CAPsMAN.
# The controller (RB5009) pushes SSIDs, security, and datapaths via CAPsMAN.
# This component just enables the client side.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
  }
}

resource "routeros_wifi" "wifi1" {
  name = "wifi1"
  configuration = {
    manager = "capsman"
  }
  disabled = false
}

resource "routeros_wifi" "wifi2" {
  name = "wifi2"
  configuration = {
    manager = "capsman"
  }
  disabled = false
}

resource "routeros_wifi_cap" "this" {
  enabled              = true
  discovery_interfaces = [var.discovery_interface]
}
